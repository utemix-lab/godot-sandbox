extends Node
## Менеджер экспорта в contracts (Autoload: ExportManager)

const CONTRACTS_PATH = "../contracts/contracts/public"

var _export_path: String = CONTRACTS_PATH

func _ready() -> void:
	_load_config()
	print("[ExportManager] Export path: ", _export_path)

func _load_config() -> void:
	var config_path = "res://config/local_paths.json"
	if FileAccess.file_exists(config_path):
		var file = FileAccess.open(config_path, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK:
				var config = json.get_data()
				if config.has("contracts_path"):
					_export_path = config.contracts_path

## Экспорт маршрута
func export_route(route: Dictionary, category: String = "demo", name: String = "") -> bool:
	if name.is_empty():
		name = "route-" + str(Time.get_unix_time_from_system())
	
	var dir_path = _export_path + "/routes/" + category
	var file_path = dir_path + "/" + name + ".json"
	
	# Создать директорию если не существует
	DirAccess.make_dir_recursive_absolute(dir_path)
	
	var json_string = JSON.stringify(route, "  ")
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("[ExportManager] Route exported: ", file_path)
		return true
	else:
		push_error("[ExportManager] Failed to export route: ", file_path)
		return false

## Экспорт interaction rules
func export_interaction_rules(rules: Array, name: String = "visitor") -> bool:
	var file_path = _export_path + "/ui/interaction/" + name + ".interaction.json"
	
	var json_string = JSON.stringify(rules, "  ")
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("[ExportManager] Interaction rules exported: ", file_path)
		return true
	else:
		push_error("[ExportManager] Failed to export interaction rules")
		return false

## Экспорт layout
func export_layout(layout: Dictionary, name: String = "visitor") -> bool:
	var file_path = _export_path + "/ui/layout/" + name + ".layout.json"
	
	var json_string = JSON.stringify(layout, "  ")
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("[ExportManager] Layout exported: ", file_path)
		return true
	else:
		push_error("[ExportManager] Failed to export layout")
		return false

## Экспорт bindings
func export_bindings(bindings: Dictionary, name: String = "visitor") -> bool:
	var file_path = _export_path + "/ui/bindings/" + name + ".bindings.json"
	
	var json_string = JSON.stringify(bindings, "  ")
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("[ExportManager] Bindings exported: ", file_path)
		return true
	else:
		push_error("[ExportManager] Failed to export bindings")
		return false

## Полный экспорт сцены
func export_scene(graph_editor, route_name: String = "", category: String = "demo") -> Dictionary:
	var results = {
		"route": false,
		"route_path": ""
	}
	
	if graph_editor and graph_editor.has_method("export_to_route_json"):
		var route = graph_editor.export_to_route_json()
		
		if route_name.is_empty():
			route_name = "scene-" + str(Time.get_unix_time_from_system())
		
		route.id = route_name
		route.title = route_name.replace("-", " ").capitalize()
		
		results.route = export_route(route, category, route_name)
		results.route_path = _export_path + "/routes/" + category + "/" + route_name + ".json"
	
	return results

## Получить путь экспорта
func get_export_path() -> String:
	return _export_path
