extends Control
## Main scene controller

@onready var step_label: Label = $MainContainer/CenterContainer/NavBar/StepLabel
@onready var prev_button: Button = $MainContainer/CenterContainer/NavBar/PrevButton
@onready var next_button: Button = $MainContainer/CenterContainer/NavBar/NextButton
@onready var graph_label: Label = $MainContainer/CenterContainer/GraphPlaceholder/Label

@onready var story_panel = $MainContainer/StoryPanel
@onready var system_panel = $MainContainer/RightContainer/SystemPanel
@onready var service_panel = $MainContainer/RightContainer/ServicePanel


func _ready() -> void:
	print("[Main] Scene ready")
	
	# Connect buttons
	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)
	
	# Connect to AppState signals
	AppState.step_changed.connect(_on_step_changed)
	AppState.panel_updated.connect(_on_panel_updated)
	
	# Connect to ContractsLoader
	ContractsLoader.contracts_loaded.connect(_on_contracts_loaded)
	ContractsLoader.load_error.connect(_on_load_error)
	
	# Load contracts after a short delay (to ensure autoloads are ready)
	await get_tree().create_timer(0.1).timeout
	ContractsLoader.load_all_contracts()


func _on_contracts_loaded() -> void:
	print("[Main] Contracts loaded!")
	
	# Apply layout
	_apply_layout()
	
	# Set initial step
	var start_id = AppState.route_graph.get("start_node_id", "")
	if start_id:
		AppState.set_current_step(start_id)
	
	# Update graph placeholder
	var nodes_count = AppState.route_graph.get("nodes", []).size()
	var edges_count = AppState.route_graph.get("edges", []).size()
	graph_label.text = "Route: %s\n%d nodes, %d edges" % [
		AppState.route_graph.get("title", "Unknown"),
		nodes_count,
		edges_count
	]


func _on_load_error(message: String) -> void:
	print("[Main] Load error: ", message)
	graph_label.text = "Error loading contracts:\n" + message


func _apply_layout() -> void:
	var layout = AppState.layout
	if layout.is_empty():
		return
	
	var desktop = layout.get("layout", {}).get("desktop", {})
	var panels = desktop.get("panels", {})
	
	# Apply panel widths
	if panels.has("story"):
		var story_config = panels["story"]
		var width = _parse_px(story_config.get("width", "280px"))
		story_panel.custom_minimum_size.x = width
	
	if panels.has("system") or panels.has("service"):
		var system_config = panels.get("system", {})
		var width = _parse_px(system_config.get("width", "320px"))
		$MainContainer/RightContainer.custom_minimum_size.x = width
	
	# Apply theme colors
	var theme_config = layout.get("theme", {})
	if theme_config.has("background"):
		var bg_color = Color.from_string(theme_config["background"], Color.BLACK)
		$Background.color = bg_color
	
	print("[Main] Layout applied")


func _parse_px(value: String) -> float:
	if value.ends_with("px"):
		return float(value.substr(0, value.length() - 2))
	return float(value)


func _on_step_changed(step_id: String) -> void:
	step_label.text = "Step: " + step_id
	
	# Update navigation buttons
	prev_button.disabled = AppState.get_prev_step_id().is_empty()
	next_button.disabled = AppState.get_next_step_id().is_empty()
	
	print("[Main] Step changed to: ", step_id)


func _on_panel_updated(panel_name: String, content: Dictionary) -> void:
	match panel_name:
		"story":
			story_panel.update_content(content)
		"system":
			system_panel.update_content(content)
		"service":
			service_panel.update_content(content)


func _on_prev_pressed() -> void:
	AppState.navigate_prev()
	InteractionRuntime.process_event("click", {"type": "navigation-point", "direction": "prev"})


func _on_next_pressed() -> void:
	AppState.navigate_next()
	InteractionRuntime.process_event("click", {"type": "navigation-point", "direction": "next"})


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT:
				_on_prev_pressed()
			KEY_RIGHT:
				_on_next_pressed()
			KEY_ESCAPE:
				# Deselect all
				pass
