extends Node
## Global application state singleton

signal step_changed(step_id: String)
signal panel_updated(panel_name: String, content: Dictionary)
signal effect_triggered(effect: Dictionary)

# Current state
var current_step_id: String = ""
var visited_steps: Array[String] = []
var selected_actors: Array[String] = []

# Loaded data
var route_graph: Dictionary = {}
var session: Dictionary = {}
var layout: Dictionary = {}
var interactions: Dictionary = {}
var bindings: Dictionary = {}

# Panel states
var panel_states: Dictionary = {
	"story": {"collapsed": false, "scroll": 0},
	"system": {"collapsed": false, "scroll": 0},
	"service": {"collapsed": false, "scroll": 0}
}


func _ready() -> void:
	print("[AppState] Initialized")


func set_current_step(step_id: String) -> void:
	if step_id != current_step_id:
		current_step_id = step_id
		if step_id not in visited_steps:
			visited_steps.append(step_id)
		step_changed.emit(step_id)
		_update_panels_for_step(step_id)


func get_step_data(step_id: String) -> Dictionary:
	if route_graph.has("nodes"):
		for node in route_graph["nodes"]:
			if node.get("id") == step_id:
				return node
	return {}


func _update_panels_for_step(step_id: String) -> void:
	var step_data = get_step_data(step_id)
	if step_data.is_empty():
		return
	
	panel_updated.emit("story", step_data.get("story", {}))
	panel_updated.emit("system", step_data.get("system", {}))
	panel_updated.emit("service", step_data.get("service", {}))


func trigger_effect(effect: Dictionary) -> void:
	effect_triggered.emit(effect)
	print("[AppState] Effect: ", effect)


func get_next_step_id() -> String:
	if route_graph.has("edges"):
		for edge in route_graph["edges"]:
			if edge.get("source") == current_step_id and edge.get("type") == "NEXT":
				return edge.get("target", "")
	return ""


func get_prev_step_id() -> String:
	if route_graph.has("edges"):
		for edge in route_graph["edges"]:
			if edge.get("target") == current_step_id and edge.get("type") == "NEXT":
				return edge.get("source", "")
	return ""


func navigate_next() -> void:
	var next_id = get_next_step_id()
	if next_id:
		set_current_step(next_id)


func navigate_prev() -> void:
	var prev_id = get_prev_step_id()
	if prev_id:
		set_current_step(prev_id)
