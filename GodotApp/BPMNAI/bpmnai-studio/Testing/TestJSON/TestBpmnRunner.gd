extends Node2D

var json_loader := BpmnJsonLoaderV1.new()  # Oder den neuen Klassennamen
var layout_handler := preload("res://Scripts/engine/layout/LayoutHandler.gd").new()
var flow_handler := preload("res://Scripts/engine/layout/FlowConnectionHandler.gd").new()

var test_json := {
	"elements": [
{
  "id": "start",
  "type": "start_event",
  "name": "Start",
  "lane_id": "lane1",
  "pool_id": "pool1",
  "flows_to": ["task1"]
}
,
		{
			"id": "task1",
			"type": "task",
			"name": "My Task",
			"lane_id": "lane1",
			"pool_id": "pool1",
			"flows_to": ["end"],
			"parent": "start",
			"children": ["end"]
		},
		{
			"id": "end",
			"type": "end_event",
			"name": "End",
			"lane_id": "lane1",
			"pool_id": "pool1",
			"flows_to": []
		}
	]
}

func _ready():
	var instance_map: Dictionary = json_loader.load_bpmn_from_json(test_json, self)
	var all_nodes: Array = instance_map.values()
	layout_handler.apply_layout(all_nodes)
	flow_handler.setup(self, layout_handler, all_nodes)
	flow_handler.connect_all_flows()
