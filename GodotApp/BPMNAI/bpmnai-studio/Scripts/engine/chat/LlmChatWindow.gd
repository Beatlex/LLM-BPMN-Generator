extends Control

@onready var messages_box = $"MarginContainer/MainContainer/ChatPanel/Scroll/Messages"
@onready var input_field  = $"MarginContainer/MainContainer/ChatPanel/Input/LineEdit"
@onready var send_button  = $"MarginContainer/MainContainer/ChatPanel/Input/Send"
@onready var btn_render   = $"MarginContainer/MainContainer/SidePanel/BtnRender"
@onready var btn_clear    = $"MarginContainer/MainContainer/SidePanel/BtnClear"
@onready var status_label = $"MarginContainer/MainContainer/SidePanel/StatusLabel"
@onready var scroll       = $"MarginContainer/MainContainer/ChatPanel/Scroll"
@onready var btn_back_home = $"MarginContainer/MainContainer/SidePanel/btnBackHome" 
const HOME_SCENE := preload("res://ui/home/Home.tscn")


var controller: ChatController

func _ready() -> void:
	controller = ChatController.new()
	add_child(controller)

	controller.response_ready.connect(_on_llm_response)

	send_button.pressed.connect(_on_send)
	input_field.text_submitted.connect(_on_text_submitted)
	btn_clear.pressed.connect(_on_clear)
	btn_render.pressed.connect(_on_render_last)
	btn_back_home.pressed.connect(_on_back_home)

	status_label.text = "Bereit. Tippe eine Frage ein…"
	print_rich("[color=lightgreen][LlmChatWindow][/color] UI bereit.")

	if BPMNData.chat_history.is_empty():
		_add_chat(
			"BPMN-Assistent",
			"Bitte beschreiben Sie den zu modellierenden Prozess."
		)
	else:
		_restore_chat()


func _log(msg: String) -> void:
	print_rich("[color=lightgreen][LlmChatWindow][/color] " + msg)

func _on_text_submitted(_new_text: String) -> void:
	_on_send()

func _on_send() -> void:
	var t = input_field.text.strip_edges()
	if t == "":
		return

	_log("Sende User-Message: " + t)
	_add_chat("👤 USER", t)
	input_field.clear()

	controller.request(t)

func _on_llm_response(reply: String) -> void:
	_log("LLM-Antwort im UI angekommen.")
	_add_chat("🤖 LLM", reply)
	_scroll_to_bottom()

func _add_chat(author: String, text: String, _role: String = "") -> void:
	var lbl := Label.new()
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.text = "%s:\n%s" % [author, text]

	messages_box.add_child(lbl)

	BPMNData.chat_history.append({
		"author": author,
		"text": text
	})

	_scroll_to_bottom()

func _scroll_to_bottom() -> void:
	if scroll == null:
		return

	call_deferred("_apply_scroll")

func _apply_scroll():
	if scroll == null:
		return
	var v = scroll.get_v_scroll_bar()
	if v:
		v.value = v.max_value

func _on_json_auto(data: Array) -> void:
	status_label.text = "JSON erkannt → Auto-Render…"
	_log("JSON erkannt, starte Render.")
	controller.render_bpmn(data)

func _on_clear() -> void:
	for x in messages_box.get_children():
		x.queue_free()
	status_label.text = "Chat geleert."
	BPMNData.chat_history.clear()
	_log("Chat-Fenster geleert.")

func _on_render_last() -> void:
	if messages_box.get_child_count() == 0:
		status_label.text = "Keine Nachrichten vorhanden."
		return

	var last := messages_box.get_child(messages_box.get_child_count() - 1) as Label
	var text := last.text.strip_edges()

	# JSON Extraktion
	var s := text.find("[")
	var e := text.rfind("]")

	if s == -1 or e == -1:
		status_label.text = "Keine JSON gefunden."
		return

	var json := text.substr(s, e - s + 1)
	var parsed = JSON.parse_string(json)

	if typeof(parsed) != TYPE_ARRAY:
		push_error("Parsing fehlgeschlagen:\n" + json)
		status_label.text = "JSON fehlerhaft."
		return

	status_label.text = "Rendering…"

	BPMNData.pending_bpmn = parsed
	BPMNData.origin = BPMNData.Origin.CHAT
	get_tree().change_scene_to_file(
		"res://Scripts/engine/Loader/BpmnJsonLoader.tscn"
	)
	
func _on_back_home() -> void:
	get_tree().change_scene_to_file("res://ui/home/Home.tscn")

func _restore_chat() -> void:
	if BPMNData.chat_history.is_empty():
		return

	for msg in BPMNData.chat_history:
		var lbl := Label.new()
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		lbl.text = "%s:\n%s" % [msg.author, msg.text]
		messages_box.add_child(lbl)

	_scroll_to_bottom()
