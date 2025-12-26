extends Node
class_name BPMNData

enum Origin {
	HOME,
	CHAT
}
static var pending_bpmn: Array = []
static var origin: Origin = Origin.HOME
static var chat_history: Array = []
