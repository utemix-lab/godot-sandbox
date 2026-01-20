extends Node
## Loads contracts from workspace

signal contracts_loaded
signal load_error(message: String)

# Path to workspace (relative to Godot project)
const DEFAULT_WORKSPACE_PATH = "../utemix-workspace/contracts/public"

var workspace_path: String = DEFAULT_WORKSPACE_PATH
var _local_paths_config: Dictionary = {}


func _ready() -> void:
	_load_local_paths_config()
	print("[ContractsLoader] Initialized, workspace: ", workspace_path)


func _load_local_paths_config() -> void:
	# Try to load local config (not committed)
	var config_path = "res://config/local_paths.json"
	if FileAccess.file_exists(config_path):
		var file = FileAccess.open(config_path, FileAccess.READ)
		if file:
			var json = JSON.new()
			var error = json.parse(file.get_as_text())
			if error == OK:
				_local_paths_config = json.data
				if _local_paths_config.has("workspace_path"):
					workspace_path = _local_paths_config["workspace_path"]
					print("[ContractsLoader] Using custom workspace path: ", workspace_path)
			file.close()


func load_all_contracts() -> void:
	print("[ContractsLoader] Loading all contracts...")
	
	# Layout
	var layout = load_json("ui/layout/visitor.layout.json")
	if layout:
		AppState.layout = layout
		print("[ContractsLoader] Layout loaded")
	
	# Interactions
	var interactions = load_json("ui/interaction/visitor.interaction.json")
	if interactions:
		AppState.interactions = interactions
		print("[ContractsLoader] Interactions loaded: ", interactions.get("rules", []).size(), " rules")
	
	# Bindings
	var bindings = load_json("ui/bindings/visitor.bindings.json")
	if bindings:
		AppState.bindings = bindings
		print("[ContractsLoader] Bindings loaded")
	
	# Demo route
	var route = load_json("routes/demo/visitor.demo.route.json")
	if route:
		AppState.route_graph = route
		print("[ContractsLoader] Route loaded: ", route.get("nodes", []).size(), " nodes")
	
	# Demo session
	var session = load_json("sessions/demo/visitor.demo.session.json")
	if session:
		AppState.session = session
		print("[ContractsLoader] Session loaded")
	
	contracts_loaded.emit()


func load_json(relative_path: String) -> Variant:
	var full_path = workspace_path + "/" + relative_path
	
	# Try absolute path first (for external workspace)
	if not full_path.begins_with("res://"):
		# Convert to absolute if needed
		if not full_path.begins_with("/") and not full_path.begins_with("C:"):
			# Relative path from project
			var project_path = ProjectSettings.globalize_path("res://")
			full_path = project_path + full_path
	
	print("[ContractsLoader] Loading: ", full_path)
	
	if not FileAccess.file_exists(full_path):
		print("[ContractsLoader] File not found: ", full_path)
		load_error.emit("File not found: " + full_path)
		return null
	
	var file = FileAccess.open(full_path, FileAccess.READ)
	if not file:
		var error_msg = "Cannot open file: " + full_path
		print("[ContractsLoader] ", error_msg)
		load_error.emit(error_msg)
		return null
	
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(content)
	if error != OK:
		var error_msg = "JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()]
		print("[ContractsLoader] ", error_msg)
		load_error.emit(error_msg)
		return null
	
	return json.data


func get_asset_path(relative_path: String) -> String:
	# Returns full path to asset
	return workspace_path + "/assets/" + relative_path
