extends Node

var chat_window

func handle_user_message(user_text: String):
	# Display user message
	chat_window.add_message("User", user_text)

	# TODO: später -> LLMClient call
	# Placeholder Response
	var reply = "Ich habe deine Nachricht empfangen!"
	chat_window.add_message("AI", reply)
