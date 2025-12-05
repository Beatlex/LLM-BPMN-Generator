extends Node
class_name ChatController

signal response_ready(text: String)

@export var debug: bool = true

var client: OllamaClient
var messages: Array = []          
var history_limit := 8              # Requests anzahl


# ===================================================================
#   READY
# ===================================================================
func _ready() -> void:
	client = OllamaClient.new()
	add_child(client)
	_log("ChatController bereit, OllamaClient angehängt.")

# MasterPrompt leer → default Fallback
	var master := client.master_prompt.strip_edges()

	if master == "":
		master = """
Du bist BPMN-Generator.

ZIEL:
Du führst einen kurzen Dialog mit dem Nutzer (max. 5 deiner Antworten),
um einen Prozess zu erheben und anschließend **ausschließlich**
ein gültiges BPMN-JSON auszugeben.

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
1. Stelle Rückfragen wenn Infos fehlen.
2. Maximal 5 deiner Antworten dürfen Fragen sein.
3. IDs strikt fortlaufend.
4. JSON muss valide sein.
5. Keine Codeblöcke, kein Markdown.
"""

	messages.append({
	"role": "system",
	"content": master
})

	_log("System-Prompt geladen: %d Zeichen" % master.length())


func _log(msg: String) -> void:
	if debug:
		print_rich("[color=yellow][ChatController][/color] " + msg)

func request(user_text: String) -> void:
	messages.append({"role": "user", "content": user_text})
	_log("Sende Chat-History an LLM (%d Nachrichten)." % messages.size())

	var reply := await client.chat(messages)

	messages.append({"role": "assistant", "content": reply})
	_log("Antwort vom LLM (Länge=%d)" % reply.length())

	_save_chat_log()

	response_ready.emit(reply)

func _save_chat_log() -> void:
	# Ordner sicherstellen
	var root := DirAccess.open("res://")
	if root == null:
		push_error("❌ Konnte Projekt-Root nicht öffnen!")
		return

	root.make_dir_recursive("res://Logs/ChatLogs")

	# Dateiname
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


# ===================================================================
#   SAVE BPMN JSON TO TEST FOLDER
# ===================================================================
func save_bpmn_json(json_array: Array) -> String:
	# Ordner sicherstellen
	var root := DirAccess.open("res://")
	root.make_dir_recursive("res://Testing/TestJSON")

	var timestamp := Time.get_datetime_string_from_system().replace(":", "-")
	var file_path := "res://Testing/TestJSON/bpmn_" + timestamp + ".json"

	var f := FileAccess.open(file_path, FileAccess.WRITE)
	if f == null:
		push_error("❌ JSON konnte nicht gespeichert werden!")
		return ""

	var json_pretty := JSON.stringify(json_array, "\t")
	f.store_string(json_pretty)
	f.close()

	_log("💾 JSON gespeichert unter: " + file_path)
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
