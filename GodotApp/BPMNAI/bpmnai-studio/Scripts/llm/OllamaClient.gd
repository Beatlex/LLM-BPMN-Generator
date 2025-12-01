extends Node
class_name OllamaClient

@export var endpoint := "http://127.0.0.1:11434/api/chat"
@export var model := "gpt-oss:20b"
@export var timeout_sec := 45.0
@export var enable_retry := true   # Autowiederholung falls Response leer war

# =======================================================================
#  Öffentlicher Endpunkt – wird vom ChatController genutzt
# =======================================================================
func chat(messages:Array) -> String:
	var reply = await _send(messages)

	# Falls Null/Leer → Wiederholen?
	if enable_retry and (reply == "" or reply.begins_with("ERROR:")):
		print_rich("[color=orange][OllamaClient] ⚠ Keine Antwort → Retry...[/color]")
		reply = await _send(messages) # Zweiter Versuch

	# Falls immer noch leer → als Text ersetzen
	if reply == "" or reply.begins_with("ERROR:"):
		return "⚠ Das Modell hat keine verwertbare Antwort zurückgegeben."

	return reply



# =======================================================================
#  PRIVATE — HTTP Request Engine (mit Vollschutz)
# =======================================================================
func _send(messages:Array) -> String:
	var http := HTTPRequest.new()
	add_child(http)

	var body := {
		"model": model,
		"messages": messages,
		"stream": false
	}

	var err = http.request(
		endpoint,
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify(body),
	)

	if err != OK:
		return "ERROR: HTTP-Start fehlgeschlagen (Code=%s)" % err


	var response = await http.request_completed

	# unpack result
	var code : int    = response[1]
	var raw  : String = ""
	if response.size() > 3 and response[3] != null:
		raw = response[3].get_string_from_utf8()

	# Nicht einmal eine HTTP-Antwort → sofort Fehler
	if raw.strip_edges() == "":
		return "ERROR: Leere Raw-Response erhalten."

	# HTTP != OK? → Nicht crashen, Text zurückgeben
	if code != 200:
		return "ERROR: HTTP-%d → %s" % [code, raw]

	# JSON parsen
	var parsed = JSON.parse_string(raw)

	# JSON ungültig → trotzdem weiter geben
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		return "ERROR: Ungültiges JSON → Raw übernommen\n" + raw

	# Suche nach Chat-Content
	if parsed.has("message") and parsed["message"].has("content"):
		return str(parsed["message"]["content"]).strip_edges()

	# Wenn Message existiert aber kein Content → fallback
	return "ERROR: Keine 'content' Antwort im JSON.\n" + raw
