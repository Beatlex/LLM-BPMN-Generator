extends Node
class_name ChatController

signal response_ready(text: String)  # UI soll Text anzeigen

@export var debug: bool = true

var client: OllamaClient
var messages: Array = []  # Chat-History mit system/user/assistant

func _ready() -> void:
	client = OllamaClient.new()
	add_child(client)
	_log("ChatController bereit, OllamaClient angehängt.")

	# System-Prompt definieren
	var system_prompt := """
Du bist BPMN-Generator.

ZIEL:
Du führst einen kurzen Dialog mit dem Nutzer (max. 5 deiner Antworten), um einen Prozess zu erheben und diesen anschließend als BPMN-JSON auszugeben.

JSON Format (Pflicht):
[
  {
	"element_id": "0",
	"element_name": "Start",
	"element_type": "start_event" | "end_event" | "task" | "exclusive_gateway" | "parallel_gateway",
	"flows_to": ["1","2"],
	"outputs": { "right": "Text", "down": "Text" },
	"lane_id":"",
	"pool_id":""
  }
]

REGELN:
1. Sammle erst Daten → FRAGE, falls Infos fehlen.
2. Du darfst maximal 5 Fragen stellen.
3. Genau 1 Start & 1 End Event.
4. IDs strikt aufsteigend als Strings.
5. Wenn genug Informationen vorhanden sind:
   🔥 ANTWORTE NUR mit JSON – ohne Text, ohne Codeblock, ohne Markdown.

WENN der Nutzer explizit sagt:
"Erzeuge JSON jetzt" oder "Beispiel JSON",
→ dann überspringe Fragen & liefere direkt JSON.
"""
	messages.clear()
	messages.append({
		"role": "system",
		"content": system_prompt.strip_edges()
	})
	_log("System-Prompt gesetzt.")

func _log(msg: String) -> void:
	if debug:
		print_rich("[color=yellow][ChatController][/color] " + msg)

func request(user_text: String) -> void:
	# User-Nachricht in History
	messages.append({
		"role": "user",
		"content": user_text
	})

	_log("Sende Chat-History mit %d Nachrichten an LLM." % messages.size())
	var reply := await client.chat(messages)

	# Antwort in History speichern
	messages.append({
		"role": "assistant",
		"content": reply
	})

	_log("Antwort vom LLM (Länge=%d)" % reply.length())
	response_ready.emit(reply)

var history_limit := 8

func _build_message_history() -> Array:
	var msgs : Array = []
	for i in range(max(1, messages.size() - history_limit), messages.size()):
		msgs.append(messages[i])
	return msgs

func get_last_assistant_message() -> String:
	# Für den Render-Button: letzte Assistant-Nachricht zurückgeben
	for i in range(messages.size() - 1, -1, -1):
		var msg = messages[i]
		if msg is Dictionary and msg.get("role", "") == "assistant":
			return str(msg.get("content", ""))
	return ""
