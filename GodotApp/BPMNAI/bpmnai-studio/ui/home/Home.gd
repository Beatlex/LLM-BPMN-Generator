extends Control

### UI-Referenzen
@onready var file_dialog      : FileDialog = $MarginContainer/FileDialog
@onready var btn_load_json    : Button     = $MarginContainer/CenterContainer/VBoxContainer/BtnLoadJson
@onready var btn_example      : Button     = $MarginContainer/CenterContainer/VBoxContainer/BtnLoadExample
@onready var btn_new          : Button     = $MarginContainer/CenterContainer/VBoxContainer/BtnNewDiagram
@onready var btn_exit         : Button     = $MarginContainer/CenterContainer/VBoxContainer/Beenden

### Szenenpfade
const CHAT_SCENE  := "res://ui/chat/LlmChatWindow.tscn"
const LOADER_SCENE := "res://Scripts/engine/Loader/BpmnJsonLoader.tscn"
const EXAMPLE_SCENE := "res://Testing/TestJSON/MultiGatewayTest.tscn"

func _ready() -> void:
	file_dialog.hide()

	btn_load_json.pressed.connect(_on_load_json_pressed)
	btn_example.pressed.connect(_on_example_pressed)
	btn_new.pressed.connect(_on_new_pressed)
	btn_exit.pressed.connect(func(): get_tree().quit())

	file_dialog.file_selected.connect(_on_file_selected)

func _on_load_json_pressed() -> void:
	file_dialog.popup()

func _on_file_selected(path:String) -> void:
	var text = FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)

	if typeof(parsed) != TYPE_ARRAY:
		push_error("[HOME] ❌ JSON ist kein BPMN-Array!")
		return

	_start_bpmn(parsed)

func _on_example_pressed() -> void:
	get_tree().change_scene_to_file(EXAMPLE_SCENE)

func _on_new_pressed() -> void:
	get_tree().change_scene_to_file(CHAT_SCENE)  

func _start_bpmn(data:Array) -> void:
	get_tree().change_scene_to_file(LOADER_SCENE)
	await get_tree().process_frame           
	get_tree().current_scene.call_deferred("load_json_data", data)
