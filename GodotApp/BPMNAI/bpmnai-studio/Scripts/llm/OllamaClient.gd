extends Node
class_name OllamaClient

@export var endpoint := "http://127.0.0.1:11434/api/chat"
@export var model := "gpt-oss:20b"
@export var timeout_sec := 45.0
@export var enable_retry := true   # Autowiederholung falls Response leer war
@export var master_prompt := ""
const DEFAULT_MASTER_PROMPT := """
Du agierst als hochpräziser BPMN-Prozessmodellierer und JSON-Generator mit tiefem Fachwissen in BPMN 2.0

ZIEL:
Erhebe gemeinsam mit dem Nutzer einen fachlich korrekten Geschäftsprozess und generiere ausschließlich ein valides, semantisch konsistentes BPMN-JSON,
das direkt durch einen BPMN-Renderer verarbeitet werden kann.
Der Dialog dient ausschließlich der erzeugung des Modells und endet spätestens nach 7 deiner Antworten.

Rolle(Role Prompting):
-Du denkst prozesslogisch, nicht narrativ.
-Du modellierst nur explizit genannte Schritte.
-Du trennst strikt zwischen:
->Aktivitäten (Tasks)
->Entscheidungen (Gateways)
->Parallelität
->Prozessstart und -ende
Du vermeidest implizite Annahmen.

Knowledge Injection
-Jeder Prozess hat genau ein Start-Event.
-End-Events dürfen mehrfach vorkommen.
-Exclusive Gateways:
->benötigen beschriftete Ausgänge (outputs.right, outputs.down)
-Parallel Gateways:
->treten immer als Split + Merge-Paar auf
->Anzahl eingehender = Anzahl ausgehender Flows
-Tasks dürfen nie direkt mehrere ausgehende Flows haben.
-Gateways dürfen keine fachlichen Tätigkeiten enthalten.
-Sequenzflüsse müssen gerichtet und logisch konsistent sein.

Standardisierung
Intern arbeitest du immer mit folgendem Modell:
1. Prozessliste erfassen
2. Sequenzielle Reihenfolge bestimmen
3. Entscheidungen & Parallelität explizit prüfen
4. BPMN-Elemente ableiten
5. IDs vergeben
6. JSON validieren

DIALOG- UND REFINEMENT-STRATEGIE
-Stelle nur gezielte Rückfragen, wenn mindestens eine dieser Informationen fehlt:
-Gibt es Entscheidungen mit Alternativen?
-Gibt es parallele Aktivitäten?
-Gibt es mehrere mögliche Enden?
-Ist die Reihenfolge eindeutig?

Maximal 5 deiner Antworten dürfen Fragen enthalten.
Nutze jede Frage zur gezielten Modellverbesserung, nicht zur allgemeinen Klärung.
Nur das finale JSON wird ausgegeben.

AUSGABEFORMAT (verpflichtend!)
Die Ausgabe besteht ausschließlich aus einem JSON-Array im folgenden Schema:
[
  {
	"element_id": "0",
	"element_name": "",
	"element_type": "start_event" | "end_event" | "task" | "exclusive_gateway" | "inclusive_gateway" | "parallel_gateway", 
	"flows_to": ["1","2"],
	"outputs": { "right": "", "down": "" },
	"lane_id":"",
	"pool_id":""
  }
]

REGELN:
-IDs sind numerisch, eindeutig und strikt fortlaufend
-Jeder flows_to-Verweis zeigt auf eine existierende ID
-Start-Event hat keine eingehenden Flows
-End-Events haben keine ausgehenden Flows
-Gateways haben mindestens zwei ausgehende Flows
-JSON ist syntaktisch valide

RÜCKFRAGEN-REGELN (verpflichtend):
- Wenn Informationen fehlen, stelle gezielte Rückfragen.
- Gib Rückfragen ausschließlich als normalen Klartext aus.
- Nummeriere Rückfragen mit "1., 2., 3."
- Gib keine Meta-Erklärungen oder internen Überlegungen aus.
- Verwende ausschließlich Deutsch.
- Gib niemals JSON oder strukturierte Daten für Rückfragen aus.

NEGATIVE PROMPTING
-Kein Text außerhalb des JSON
-Keine Erklärungen
-Kein Markdown
-Keine Codeblöcke
-Keine Kommentare
-Keine Annahmen
-Keine BPMN-Elemente außerhalb des Schemas
- Gib keine internen Überlegungen, Planungen oder Begründungen aus.
- Schreibe niemals Sätze wie "We should...", "I will...", "Let's...".
"""


func _ready() -> void:
	_load_settings()
	
const SETTINGS_FILE := "user://llm_settings.cfg"

#  open Endpunkt
func chat(messages:Array) -> String:
	var reply = await _send(messages)

	# Falls Null/Leer -> Wiederholen
	if enable_retry and (reply == "" or reply.begins_with("ERROR:")):
		print_rich("[color=orange][OllamaClient] ⚠ Keine Antwort → Retry...[/color]")
		reply = await _send(messages) 

	if reply == "" or reply.begins_with("ERROR:"):
		return "Das Modell hat keine verwertbare Antwort zurückgegeben."

	return reply

#  PRIVATE -> HTTP Request Engine 
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

	var code : int    = response[1]
	var raw  : String = ""
	if response.size() > 3 and response[3] != null:
		raw = response[3].get_string_from_utf8()

	if raw.strip_edges() == "":
		return "ERROR: Leere Raw-Response erhalten."

	if code != 200:
		return "ERROR: HTTP-%d → %s" % [code, raw]

	var parsed = JSON.parse_string(raw)

	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		return "ERROR: Ungültiges JSON → Raw übernommen\n" + raw

	if parsed.has("message") and parsed["message"].has("content"):
		return str(parsed["message"]["content"]).strip_edges()

	return "ERROR: Keine 'content' Antwort im JSON.\n" + raw

func set_active_model(name: String) -> void:
	model = name
	_save_settings()

func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("ollama", "endpoint", endpoint)
	cfg.set_value("ollama", "model", model)
	var err := cfg.save(SETTINGS_FILE)
	if err != OK:
		push_error("[OllamaClient] ⚠ Konnte Settings nicht speichern (Code=%d)" % err)
	cfg.set_value("ollama", "master_prompt", master_prompt)

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SETTINGS_FILE)
	if err != OK:
		return
	master_prompt = str(cfg.get_value("ollama", "master_prompt", DEFAULT_MASTER_PROMPT))

	endpoint = str(cfg.get_value("ollama", "endpoint", endpoint))
	model    = str(cfg.get_value("ollama", "model", model))

func _get_base_url() -> String:
	var idx := endpoint.find("/api/")
	if idx == -1:
		return endpoint
	return endpoint.substr(0, idx)

func list_available_models() -> Array:
	var http := HTTPRequest.new()
	add_child(http)

	var url := _get_base_url() + "/api/tags"
	var err := http.request(url, [], HTTPClient.METHOD_GET)
	if err != OK:
		push_error("[OllamaClient] ❌ HTTP-Fehler beim Abruf der Modelle (Code=%d)" % err)
		http.queue_free()
		return []

	var response = await http.request_completed
	http.queue_free()

	var code: int = response[1]
	var raw: String = ""
	if response.size() > 3 and response[3] != null:
		raw = response[3].get_string_from_utf8()

	if code != 200:
		push_error("[OllamaClient] ❌ /api/tags Antwort %d: %s" % [code, raw])
		return []

	var parsed = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY or !parsed.has("models"):
		push_error("[OllamaClient] ⚠ /api/tags JSON ohne 'models'-Feld.")
		return []

	var result: Array = []

	for m in parsed["models"]:
		if typeof(m) == TYPE_DICTIONARY:
			# je nach Ollama-Version 'name' oder 'model' mit Fallback zur sicherheit
			if m.has("name"):
				result.append(str(m["name"]))
			elif m.has("model"):
				result.append(str(m["model"]))

	return result

func set_master_prompt(text: String) -> void:
	master_prompt = text
	_save_settings()
