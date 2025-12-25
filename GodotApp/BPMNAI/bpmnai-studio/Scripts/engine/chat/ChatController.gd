extends Node
class_name ChatController

signal response_ready(text: String)

@export var debug: bool = true

var client: OllamaClient
var validator := BpmnJsonValidator.new()
var session_logged := false
var messages: Array = []          
var history_limit := 8             

enum LlmResultType {
	QUESTION,
	INVALID_JSON,
	VALID_JSON
}

func _ready() -> void:
	client = OllamaClient.new()
	add_child(client)
	_log("ChatController bereit, OllamaClient angehängt.")

# MasterPrompt leer -> default Fallback
	var master := client.master_prompt.strip_edges()

	if master == "":
		master = """
Du bist ein BPMN-Generator.

ZIEL:
Du führst einen dialogischen Erhebungsprozess durch, um einen Geschäftsprozess
vollständig zu erfassen. Erst wenn alle Mindestanforderungen erfüllt sind,
gibst du ausschließlich ein gültiges BPMN-JSON aus.

Mindestanforderungen für die Ausgabe:
- genau ein Start-Event
- mindestens ein End-Event
- jede Aktivität und jedes Gateway (außer End-Events) besitzt mindestens einen gültigen flows_to-Eintrag
- Gateways haben mindestens zwei ausgehende Pfade
- alle referenzierten IDs existieren
- IDs sind strikt fortlaufend ab 0

JSON Format:
[
  {
	"element_id": "0",
	"element_name": "",
	"element_type": "start_event" | "end_event" | "task" | "exclusive_gateway" | "parallel_gateway",
	"flows_to": ["1","2"],
	"outputs": { "right": "", "down": "" },
	"lane_id":"",
	"pool_id":""
  }
]

REGELN:
1. Wenn eine Mindestanforderung nicht erfüllt ist, stelle gezielt Rückfragen.
2. Maximal 5 deiner Antworten dürfen Rückfragen enthalten.
3. Gib niemals JSON aus, solange Anforderungen verletzt sind.
4. Gib ausschließlich JSON aus, wenn alle Anforderungen erfüllt sind.
5. Keine Codeblöcke, kein Markdown, keine Kommentare.
"""

	messages.append({
	"role": "system",
	"content": master
})

	_log("System-Prompt geladen: %d Zeichen" % master.length())

func request(user_text: String) -> void:
	# User-Nachricht anhängen
	messages.append({
		"role": "user",
		"content": user_text
	})

	_log("Sende Chat-History an LLM (%d Nachrichten)." % messages.size())

	# LLM aufrufen
	var reply := await client.chat(messages)

	_log("Antwort vom LLM (Länge=%d)" % reply.length())
	messages.append({
		"role": "assistant",
		"content": reply
	})

	# Versuch: JSON parsen
	var json := JSON.new()
	var parse_err := json.parse(reply.strip_edges())

	# Kein JSON → Dialog geht weiter
	if parse_err != OK or not (json.data is Array):
		response_ready.emit(reply)
		return

	# JSON vorhanden → validieren
	var result := BpmnJsonValidator.validate(json.data)

	# Valides BPMN → Session erfolgreich beendet
	if result.valid:
		save_bpmn_json(json.data)
		log_session_once()
		response_ready.emit(reply)
		return

	# JSON ungültig → strukturierte Rückfrage
	var error_prompt := "Das BPMN-JSON ist formal ungültig:\n"
	for e in result.errors:
		error_prompt += "- " + e + "\n"

	error_prompt += "\nKorrigiere das JSON. "
	error_prompt += "Gib ausschließlich das korrigierte BPMN-JSON aus. "
	error_prompt += "Keine Erklärungen, kein Text."

	messages.append({
		"role": "system",
		"content": error_prompt
	})

	_log("❗ BPMN-JSON ungültig – LLM-Korrektur angefordert")

	# UI informieren
	response_ready.emit("⚠️ BPMN-Modell unvollständig – Korrektur wird angefordert …")

	# 🔁 LLM erneut aufrufen (einmaliger Korrekturversuch)
	var corrected_reply := await client.chat(messages)

	messages.append({
		"role": "assistant",
		"content": corrected_reply
	})

	response_ready.emit(corrected_reply)

	# Korrigiertes JSON einmalig speichern (egal ob valide)
	var corrected_json := JSON.new()
	if corrected_json.parse(corrected_reply.strip_edges()) == OK:
		if corrected_json.data is Array:
			save_bpmn_json(corrected_json.data)

	# 🔚 Session sauber beenden
	log_session_once()

func _log(msg: String) -> void:
	if debug:
		print_rich("[color=yellow][ChatController][/color] " + msg)

func _save_chat_log() -> void:
	var root := DirAccess.open("res://")
	if root == null:
		push_error("❌ Konnte Projekt-Root nicht öffnen!")
		return

	root.make_dir_recursive("res://Logs/ChatLogs")

	var timestamp := Time.get_datetime_string_from_system().replace(":", "-")
	var file_path := "res://Logs/ChatLogs/chat_" + timestamp + ".txt"

	var f := FileAccess.open(file_path, FileAccess.WRITE)
	if f == null:
		push_error("❌ Chat-Log konnte nicht geschrieben werden!")
		return

	f.store_line("=== Chat Log (" + timestamp + ") ===\n")

	for m in messages:
		f.store_line("[%s] %s\n" % [m.get("role", "?"), m.get("content", "")])

	f.close()
	_log("💾 Chat-Log gespeichert unter: " + file_path)


func save_bpmn_json(json_array: Array) -> String:
	var root := DirAccess.open("res://")
	if root == null:
		push_error("❌ Konnte Projekt-Root nicht öffnen!")
		return ""

	root.make_dir_recursive("res://Logs/CreatedJson")

	var timestamp := Time.get_datetime_string_from_system().replace(":", "-")
	var file_path := "res://Logs/CreatedJson/bpmn_" + timestamp + ".json"

	var f := FileAccess.open(file_path, FileAccess.WRITE)
	if f == null:
		push_error("❌ JSON konnte nicht gespeichert werden!")
		return ""

	var json_pretty := JSON.stringify(json_array, "\t")
	f.store_string(json_pretty)
	f.close()

	_log("💾 BPMN-JSON gespeichert unter: " + file_path)
	return file_path

func _build_message_history() -> Array:
	var msgs : Array = []
	for i in range(max(1, messages.size() - history_limit), messages.size()):
		msgs.append(messages[i])
	return msgs


func get_last_assistant_message() -> String:
	for i in range(messages.size() - 1, -1, -1):
		var msg = messages[i]
		if msg is Dictionary and msg.get("role", "") == "assistant":
			return str(msg.get("content", ""))
	return ""

func try_extract_and_save_bpmn_json(reply: String) -> bool:
	var json := JSON.new()
	var err := json.parse(reply.strip_edges())

	if err != OK:
		return false

	var data = json.data
	if data is Array:
		save_bpmn_json(data)
		return true

	push_error("❌ JSON erkannt, aber kein Array – BPMN-Format verletzt.")
	return false
	
func try_handle_llm_reply(reply: String) -> bool:
	var json := JSON.new()
	if json.parse(reply.strip_edges()) != OK:
		# Kein JSON → normales Chat-Verhalten
		_save_chat_log()
		return true

	if not (json.data is Array):
		return true

	var result := BpmnJsonValidator.validate(json.data)

	if result.valid:
		save_bpmn_json(json.data)
		_save_chat_log()
		return true

	# JSON ist formal falsch → gezielte Rückfrage
	var error_text := "Das BPMN-JSON ist formal ungültig:\n"
	for e in result.errors:
		error_text += "- " + e + "\n"

	error_text += "\nKorrigiere das JSON. Gib ausschließlich korrigiertes JSON aus."

	messages.append({
		"role": "system",
		"content": error_text
	})

	_log("❗ JSON ungültig → LLM-Korrektur angefordert")
	return false

func log_session_once() -> void:
	if session_logged:
		return
	session_logged = true
	_save_chat_log()
