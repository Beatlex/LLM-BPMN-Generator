extends Control

const HOME_SCENE := "res://ui/home/Home.tscn"

@onready var dropdown_models: OptionButton = $MarginContainer/CenterContainer/VBoxContainer/LLMSetup
@onready var btn_master_prompt: Button     = $MarginContainer/CenterContainer/VBoxContainer/MasterPrompt
@onready var btn_back: Button              = $MarginContainer/CenterContainer/VBoxContainer/Zurück
@onready var lbl_status: Label             = $MarginContainer/CenterContainer/VBoxContainer/Label

@onready var popup_prompt: AcceptDialog    = $MarginContainer/MasterPromptPopup
@onready var editor_prompt: TextEdit       = $MarginContainer/MasterPromptPopup/VBoxContainer/PromptEditor
@onready var btn_prompt_save: Button       = $MarginContainer/MasterPromptPopup/VBoxContainer/HBoxContainer/BtnSave
@onready var btn_prompt_cancel: Button     = $MarginContainer/MasterPromptPopup/VBoxContainer/HBoxContainer/BtnCancel
@onready var btn_test_llm      : Button = $MarginContainer/CenterContainer/VBoxContainer/LLMTest
@onready var panel_test_output : PanelContainer = $MarginContainer/VBoxContainer/TestResultPanel
@onready var lbl_test_output   : RichTextLabel = $MarginContainer/VBoxContainer/TestResultPanel/MarginContainer/MasterPromptOutput

var debug := true
var client: OllamaClient

func _ready() -> void:
	client = OllamaClient.new()
	add_child(client)
	
	btn_back.pressed.connect(_on_back_pressed)
	dropdown_models.item_selected.connect(_on_model_selected)

	btn_master_prompt.pressed.connect(_on_edit_prompt_pressed)
	btn_prompt_save.pressed.connect(_on_save_prompt_pressed)
	btn_prompt_cancel.pressed.connect(_on_cancel_prompt_pressed)
	btn_test_llm.pressed.connect(_on_test_llm_pressed)
	
	_populate_models()

func _on_back_pressed() -> void:
	var err := get_tree().change_scene_to_file(HOME_SCENE)
	if err != OK:
		push_error("[SETTINGS]  Home-Szene konnte nicht geladen werden.")

func _on_model_selected(index: int) -> void:
	var name := dropdown_models.get_item_text(index)
	client.set_active_model(name)
	lbl_status.text = "Aktives Modell: %s" % name


func _populate_models() -> void:
	await _do_populate_models()


func _do_populate_models() -> void:
	lbl_status.text = "Verbinde mit Ollama..."
	dropdown_models.clear()

	var models := await client.list_available_models()

	if models.is_empty():
		lbl_status.text = "Keine Modelle gefunden. Läuft Ollama-Server?"
		return

	var selected_index := 0

	for m in models:
		dropdown_models.add_item(m)

		if m == client.model:
			selected_index = dropdown_models.item_count - 1

	dropdown_models.select(selected_index)
	lbl_status.text = "Modelle geladen."

func _on_edit_prompt_pressed() -> void:
	var mp := client.master_prompt.strip_edges()

	if mp == "":
		editor_prompt.text = "Hier deinen Master Prompt eingeben..."
	else:
		editor_prompt.text = mp

	popup_prompt.popup_centered()


func _on_save_prompt_pressed() -> void:
	var new_text := editor_prompt.text.strip_edges()
	client.set_master_prompt(new_text)

	lbl_status.text = "Master Prompt gespeichert."
	popup_prompt.hide()


func _on_cancel_prompt_pressed() -> void:
	popup_prompt.hide()

func _on_test_llm_pressed() -> void:
	lbl_status.text = "Teste LLM…"
	log_to_ui("⚡ TestLLM Button wurde gedrückt" + "\n")
	panel_test_output.visible = true
	lbl_test_output.clear()

	var mp := client.master_prompt.strip_edges()
	if mp == "":
		mp = client.DEFAULT_MASTER_PROMPT

	var test_messages := [
		{"role": "system", "content": mp},
		{"role": "user", "content": "Dies ist ein Test. Antworte kurz, dass du aktiv bist. "}
	]
	lbl_test_output.text += "📨 Sende Anfrage an LLM:\n" + mp
	
	var reply := await client.chat(test_messages)
	
	lbl_test_output.text += "\n \nAntwort der LLM:\n" + reply + "\n"
	
	lbl_status.text = "Test beendet."

func log_to_ui(msg: String) -> void:
	if panel_test_output and lbl_test_output:
		lbl_test_output.text += msg + "\n"
