extends Node
## Глобальное состояние приложения (Autoload: AppState)

# Текущий маршрут
var current_route: Dictionary = {}
var current_step_index: int = 0
var current_step: Dictionary = {}

# Контракты
var layout: Dictionary = {}
var interaction_rules: Array = []
var bindings: Dictionary = {}

# Пути
var contracts_path: String = ""

# Сигналы
signal step_changed(step: Dictionary, index: int)
signal route_loaded(route: Dictionary)
signal asset_loaded(asset_type: String, asset_path: String)

func _ready() -> void:
	print("[AppState] Initialized")

## Загрузить маршрут
func load_route(route: Dictionary) -> void:
	current_route = route
	current_step_index = 0
	
	# Найти стартовый шаг
	var start_id = route.get("start_node_id", "")
	for i in range(route.nodes.size()):
		if route.nodes[i].id == start_id:
			current_step_index = i
			break
	
	current_step = route.nodes[current_step_index] if route.nodes.size() > 0 else {}
	route_loaded.emit(route)
	step_changed.emit(current_step, current_step_index)
	print("[AppState] Route loaded: ", route.get("title", "Unknown"))

## Перейти к следующему шагу
func next_step() -> bool:
	if current_route.is_empty():
		return false
	
	# Найти NEXT edge от текущего шага
	var current_id = current_step.get("id", "")
	for edge in current_route.get("edges", []):
		if edge.source == current_id and edge.type == "NEXT":
			return go_to_step_by_id(edge.target)
	
	return false

## Перейти к предыдущему шагу
func prev_step() -> bool:
	if current_route.is_empty():
		return false
	
	# Найти NEXT edge, ведущий к текущему шагу
	var current_id = current_step.get("id", "")
	for edge in current_route.get("edges", []):
		if edge.target == current_id and edge.type == "NEXT":
			return go_to_step_by_id(edge.source)
	
	return false

## Перейти к шагу по ID
func go_to_step_by_id(step_id: String) -> bool:
	for i in range(current_route.nodes.size()):
		if current_route.nodes[i].id == step_id:
			current_step_index = i
			current_step = current_route.nodes[i]
			step_changed.emit(current_step, current_step_index)
			print("[AppState] Step changed to: ", current_step.get("label", step_id))
			return true
	return false

## Получить информацию о маршруте
func get_route_info() -> Dictionary:
	return {
		"title": current_route.get("title", ""),
		"total_steps": current_route.get("nodes", []).size(),
		"current_index": current_step_index,
		"current_label": current_step.get("label", "")
	}

## Проверить, есть ли следующий шаг
func has_next() -> bool:
	var current_id = current_step.get("id", "")
	for edge in current_route.get("edges", []):
		if edge.source == current_id and edge.type == "NEXT":
			return true
	return false

## Проверить, есть ли предыдущий шаг
func has_prev() -> bool:
	var current_id = current_step.get("id", "")
	for edge in current_route.get("edges", []):
		if edge.target == current_id and edge.type == "NEXT":
			return true
	return false
