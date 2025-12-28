extends Control

### UI-Referenzen
@onready var file_dialog      : FileDialog = $MarginContainer/FileDialog
@onready var btn_load_json    : Button     = $MarginContainer/CenterContainer/VBoxContainer/BtnLoadJson
@onready var btn_example      : Button     = $MarginContainer/CenterContainer/VBoxContainer/BtnLoadExample
@onready var btn_new          : Button     = $MarginContainer/CenterContainer/VBoxContainer/BtnNewDiagram
@onready var btn_settings : Button = $MarginContainer/CenterContainer/VBoxContainer/Einstellungen
@onready var btn_exit         : Button     = $MarginContainer/CenterContainer/VBoxContainer/Beenden


### Szenenpfade
const CHAT_SCENE  := "res://ui/chat/LlmChatWindow.tscn"
const LOADER_SCENE := "res://Scripts/engine/Loader/BpmnJsonLoader.tscn"
const EXAMPLE_SCENE := "res://Testing/TestJSON/MultiGatewayTest.tscn"
const SETTINGS_SCENE := "res://ui/settings/settings.tscn"

func _ready() -> void:
	file_dialog.hide()

	btn_load_json.pressed.connect(_on_load_json_pressed)
	btn_example.pressed.connect(_on_example_pressed)
	btn_new.pressed.connect(_on_new_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_exit.pressed.connect(func(): get_tree().quit())

	file_dialog.file_selected.connect(_on_file_selected)

func _on_load_json_pressed() -> void:
	file_dialog.popup()

func _on_file_selected(path:String) -> void:
	var text   := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)

	if typeof(parsed) != TYPE_ARRAY:
		push_error("[HOME] ❌ JSON ist kein BPMN-Array!")
		return

	BPMNData.pending_bpmn = parsed
	BPMNData.origin = BPMNData.Origin.HOME  

	get_tree().change_scene_to_file(LOADER_SCENE)

func _on_settings_pressed() -> void:
	var err := get_tree().change_scene_to_file(SETTINGS_SCENE)
	if err != OK:
		push_error("[HOME] ❌ Settings-Szene konnte nicht geladen werden!")

func _on_example_pressed() -> void:
	get_tree().change_scene_to_file(EXAMPLE_SCENE)

func _on_new_pressed() -> void:
	# 🔥 HARTE RESET-SEMANTIK
	BPMNData.chat_history.clear()
	BPMNData.pending_bpmn.clear()
	BPMNData.origin = BPMNData.Origin.CHAT

	get_tree().change_scene_to_file(CHAT_SCENE)


func _start_bpmn(data:Array) -> void:
	BPMNData.pending_bpmn = data
	BPMNData.origin = BPMNData.Origin.HOME   
	get_tree().change_scene_to_file(LOADER_SCENE)
