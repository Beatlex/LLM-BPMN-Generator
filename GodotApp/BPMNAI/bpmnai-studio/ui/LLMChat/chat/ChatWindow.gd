extends Control

@onready var messages: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/Messages
@onready var input: LineEdit = $MarginContainer/VBoxContainer/HBoxContainer/UserInput
@onready var send_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/SendButton

var controller

func _ready():
	controller = preload("res://ui/LLMChat/chat/ChatController.gd").new()
	controller.chat_window = self

	send_button.pressed.connect(_on_send_pressed)
	input.text_submitted.connect(_on_send_pressed)

func _on_send_pressed(text=""):
	var message = text if text != "" else input.text
	if message.strip_edges() == "":
		return

	controller.handle_user_message(message)
	input.text = ""

func scroll_to_bottom():
	var sc = $MarginContainer/VBoxContainer/ScrollContainer
	sc.scroll_vertical = sc.get_v_scroll_bar().max_value
	
func add_message(sender: String, text: String):
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.autowrap = true
	label.text = "[b]" + sender + ":[/b] " + text
	
	messages.add_child(label)
	
	await get_tree().process_frame
	scroll_to_bottom()
