extends Control
## 2D Редактор графа маршрута
class_name GraphEditor

signal node_selected(node_data: Dictionary)
signal node_added(node_data: Dictionary)
signal edge_added(edge_data: Dictionary)
signal graph_changed()

# Данные графа
var nodes: Array[Dictionary] = []
var edges: Array[Dictionary] = []
var selected_node_id: String = ""
var next_node_id: int = 1

# Состояние редактора
var is_connecting: bool = false
var connect_from_id: String = ""
var drag_node_id: String = ""
var drag_offset: Vector2 = Vector2.ZERO

# Визуальные настройки
const NODE_RADIUS: float = 24.0
const NODE_COLOR_DEFAULT: Color = Color(0.3, 0.5, 0.9, 1.0)
const NODE_COLOR_SELECTED: Color = Color(0.4, 0.8, 1.0, 1.0)
const NODE_COLOR_START: Color = Color(0.2, 0.8, 0.4, 1.0)
const EDGE_COLOR: Color = Color(0.5, 0.6, 0.7, 0.6)
const EDGE_COLOR_NEXT: Color = Color(0.3, 0.7, 0.9, 0.8)
const FONT_COLOR: Color = Color(1, 1, 1, 0.9)

# UI элементы
var context_menu: PopupMenu
var connecting_line_end: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Создать контекстное меню
	context_menu = PopupMenu.new()
	context_menu.add_item("Add Node", 0)
	context_menu.add_separator()
	context_menu.add_item("Delete Node", 1)
	context_menu.add_item("Set as Start", 2)
	context_menu.add_separator()
	context_menu.add_item("Connect (NEXT)", 10)
	context_menu.add_item("Connect (BRANCH)", 11)
	context_menu.add_item("Connect (RELATED)", 12)
	context_menu.id_pressed.connect(_on_context_menu_selected)
	add_child(context_menu)
	
	# Начать с одного узла
	_add_initial_node()

func _add_initial_node() -> void:
	var center = size / 2 if size.x > 0 else Vector2(300, 200)
	add_node(center, "Start", true)

func _draw() -> void:
	# Рисовать рёбра
	for edge in edges:
		var from_node = _get_node_by_id(edge.source)
		var to_node = _get_node_by_id(edge.target)
		if from_node and to_node:
			var from_pos = Vector2(from_node.position.x, from_node.position.y)
			var to_pos = Vector2(to_node.position.x, to_node.position.y)
			var edge_color = EDGE_COLOR_NEXT if edge.type == "NEXT" else EDGE_COLOR
			_draw_edge(from_pos, to_pos, edge_color, edge.type)
	
	# Рисовать линию соединения (если активно)
	if is_connecting and connect_from_id:
		var from_node = _get_node_by_id(connect_from_id)
		if from_node:
			var from_pos = Vector2(from_node.position.x, from_node.position.y)
			draw_line(from_pos, connecting_line_end, Color(1, 1, 0, 0.5), 2.0)
	
	# Рисовать узлы
	for node in nodes:
		var pos = Vector2(node.position.x, node.position.y)
		var color = NODE_COLOR_DEFAULT
		
		if node.id == selected_node_id:
			color = NODE_COLOR_SELECTED
		elif node.get("is_start", false):
			color = NODE_COLOR_START
		
		_draw_node(pos, node.label, color, node.id == selected_node_id)

func _draw_node(pos: Vector2, label: String, color: Color, is_selected: bool) -> void:
	# Тень
	draw_circle(pos + Vector2(2, 2), NODE_RADIUS, Color(0, 0, 0, 0.3))
	
	# Основной круг
	draw_circle(pos, NODE_RADIUS, color)
	
	# Обводка
	if is_selected:
		draw_arc(pos, NODE_RADIUS + 3, 0, TAU, 32, Color(1, 1, 1, 0.8), 2.0)
	
	# Подпись
	var font = ThemeDB.fallback_font
	var font_size = 12
	var text_size = font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos = pos + Vector2(-text_size.x / 2, NODE_RADIUS + 16)
	draw_string(font, text_pos, label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, FONT_COLOR)

func _draw_edge(from: Vector2, to: Vector2, color: Color, edge_type: String) -> void:
	var direction = (to - from).normalized()
	var start = from + direction * NODE_RADIUS
	var end = to - direction * NODE_RADIUS
	
	# Линия
	draw_line(start, end, color, 2.0)
	
	# Стрелка
	var arrow_size = 10.0
	var arrow_angle = 0.4
	var arrow_dir = (start - end).normalized()
	var arrow_left = end + arrow_dir.rotated(arrow_angle) * arrow_size
	var arrow_right = end + arrow_dir.rotated(-arrow_angle) * arrow_size
	draw_polygon([end, arrow_left, arrow_right], [color])
	
	# Подпись типа (для не-NEXT)
	if edge_type != "NEXT":
		var mid = (start + end) / 2
		var font = ThemeDB.fallback_font
		draw_string(font, mid + Vector2(5, -5), edge_type, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.7, 0.7, 0.8))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_pos = event.position
		var clicked_node = _get_node_at_position(mouse_pos)
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if is_connecting:
					# Завершить соединение
					if clicked_node and clicked_node.id != connect_from_id:
						_complete_connection(clicked_node.id)
					_cancel_connection()
				elif clicked_node:
					# Начать перетаскивание
					drag_node_id = clicked_node.id
					drag_offset = mouse_pos - Vector2(clicked_node.position.x, clicked_node.position.y)
					_select_node(clicked_node.id)
				else:
					_select_node("")
			else:
				drag_node_id = ""
		
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if is_connecting:
				_cancel_connection()
			else:
				# Контекстное меню
				selected_node_id = clicked_node.id if clicked_node else ""
				_show_context_menu(mouse_pos)
	
	elif event is InputEventMouseMotion:
		if is_connecting:
			connecting_line_end = event.position
			queue_redraw()
		elif drag_node_id:
			var node = _get_node_by_id(drag_node_id)
			if node:
				node.position.x = event.position.x - drag_offset.x
				node.position.y = event.position.y - drag_offset.y
				queue_redraw()
				graph_changed.emit()

func _get_node_at_position(pos: Vector2) -> Dictionary:
	for node in nodes:
		var node_pos = Vector2(node.position.x, node.position.y)
		if node_pos.distance_to(pos) <= NODE_RADIUS:
			return node
	return {}

func _get_node_by_id(id: String) -> Dictionary:
	for node in nodes:
		if node.id == id:
			return node
	return {}

func _select_node(node_id: String) -> void:
	selected_node_id = node_id
	queue_redraw()
	
	var node = _get_node_by_id(node_id)
	node_selected.emit(node)

func _show_context_menu(pos: Vector2) -> void:
	# Показать/скрыть опции в зависимости от контекста
	context_menu.set_item_disabled(1, selected_node_id.is_empty())  # Delete
	context_menu.set_item_disabled(2, selected_node_id.is_empty())  # Set as Start
	context_menu.set_item_disabled(10, selected_node_id.is_empty()) # Connect NEXT
	context_menu.set_item_disabled(11, selected_node_id.is_empty()) # Connect BRANCH
	context_menu.set_item_disabled(12, selected_node_id.is_empty()) # Connect RELATED
	
	context_menu.position = Vector2i(global_position + pos)
	context_menu.popup()

func _on_context_menu_selected(id: int) -> void:
	var mouse_pos = get_local_mouse_position()
	
	match id:
		0:  # Add Node
			add_node(mouse_pos)
		1:  # Delete Node
			delete_node(selected_node_id)
		2:  # Set as Start
			set_start_node(selected_node_id)
		10: # Connect NEXT
			_start_connection("NEXT")
		11: # Connect BRANCH
			_start_connection("BRANCH")
		12: # Connect RELATED
			_start_connection("RELATED")

func _start_connection(edge_type: String) -> void:
	if selected_node_id.is_empty():
		return
	
	is_connecting = true
	connect_from_id = selected_node_id
	connecting_line_end = get_local_mouse_position()
	
	# Сохранить тип соединения
	set_meta("pending_edge_type", edge_type)

func _complete_connection(to_id: String) -> void:
	var edge_type = get_meta("pending_edge_type", "NEXT")
	add_edge(connect_from_id, to_id, edge_type)

func _cancel_connection() -> void:
	is_connecting = false
	connect_from_id = ""
	remove_meta("pending_edge_type")
	queue_redraw()

## Публичные методы

func add_node(pos: Vector2, label: String = "", is_start: bool = false) -> Dictionary:
	var node_id = "step-" + str(next_node_id)
	next_node_id += 1
	
	if label.is_empty():
		label = "Step " + str(nodes.size() + 1)
	
	var node = {
		"id": node_id,
		"label": label,
		"position": { "x": pos.x, "y": pos.y },
		"is_start": is_start,
		"story": { "text": "", "refs": [] },
		"system": { "text": "", "refs": [] },
		"service": { "text": "", "actions": [] }
	}
	
	nodes.append(node)
	queue_redraw()
	node_added.emit(node)
	graph_changed.emit()
	
	return node

func delete_node(node_id: String) -> void:
	if node_id.is_empty():
		return
	
	# Удалить связанные рёбра
	edges = edges.filter(func(e): return e.source != node_id and e.target != node_id)
	
	# Удалить узел
	nodes = nodes.filter(func(n): return n.id != node_id)
	
	if selected_node_id == node_id:
		selected_node_id = ""
	
	queue_redraw()
	graph_changed.emit()

func add_edge(from_id: String, to_id: String, edge_type: String = "NEXT") -> Dictionary:
	# Проверить, что такого ребра ещё нет
	for edge in edges:
		if edge.source == from_id and edge.target == to_id:
			return {}
	
	var edge = {
		"id": "edge-" + str(edges.size() + 1),
		"source": from_id,
		"target": to_id,
		"type": edge_type
	}
	
	edges.append(edge)
	queue_redraw()
	edge_added.emit(edge)
	graph_changed.emit()
	
	return edge

func set_start_node(node_id: String) -> void:
	for node in nodes:
		node.is_start = (node.id == node_id)
	queue_redraw()
	graph_changed.emit()

func get_start_node_id() -> String:
	for node in nodes:
		if node.get("is_start", false):
			return node.id
	return nodes[0].id if nodes.size() > 0 else ""

func update_node_content(node_id: String, story: Dictionary, system: Dictionary, service: Dictionary) -> void:
	var node = _get_node_by_id(node_id)
	if node:
		node.story = story
		node.system = system
		node.service = service
		graph_changed.emit()

func get_selected_node() -> Dictionary:
	return _get_node_by_id(selected_node_id)

## Экспорт в JSON

func export_to_route_json() -> Dictionary:
	var route = {
		"$schema": "https://utemix-lab.github.io/schemas/route.schema.json",
		"version": "0.1.0",
		"id": "exported-route-" + str(Time.get_unix_time_from_system()),
		"title": "Exported Route",
		"description": "Route exported from Godot editor",
		"created_at": Time.get_datetime_string_from_system(),
		"start_node_id": get_start_node_id(),
		"nodes": [],
		"edges": [],
		"limits": {
			"max_nodes": 50,
			"max_edges": 100,
			"max_depth": 10
		},
		"meta": {
			"tags": ["exported"],
			"source": "godot-sandbox"
		}
	}
	
	for node in nodes:
		route.nodes.append({
			"id": node.id,
			"label": node.label,
			"story": node.story,
			"system": node.system,
			"service": node.service,
			"position": node.position
		})
	
	for edge in edges:
		route.edges.append({
			"id": edge.id,
			"source": edge.source,
			"target": edge.target,
			"type": edge.type
		})
	
	return route

func export_to_file(file_path: String) -> bool:
	var route = export_to_route_json()
	var json_string = JSON.stringify(route, "  ")
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("[GraphEditor] Exported to: ", file_path)
		return true
	else:
		push_error("[GraphEditor] Failed to export: ", file_path)
		return false

## Импорт из JSON

func import_from_route_json(route: Dictionary) -> void:
	nodes.clear()
	edges.clear()
	next_node_id = 1
	
	var start_id = route.get("start_node_id", "")
	
	for node_data in route.get("nodes", []):
		var node = {
			"id": node_data.id,
			"label": node_data.get("label", node_data.id),
			"position": node_data.get("position", { "x": 100, "y": 100 }),
			"is_start": node_data.id == start_id,
			"story": node_data.get("story", { "text": "", "refs": [] }),
			"system": node_data.get("system", { "text": "", "refs": [] }),
			"service": node_data.get("service", { "text": "", "actions": [] })
		}
		nodes.append(node)
		
		# Обновить next_node_id
		var id_num = node_data.id.replace("step-", "").to_int()
		if id_num >= next_node_id:
			next_node_id = id_num + 1
	
	for edge_data in route.get("edges", []):
		edges.append({
			"id": edge_data.id,
			"source": edge_data.source,
			"target": edge_data.target,
			"type": edge_data.get("type", "NEXT")
		})
	
	queue_redraw()
	print("[GraphEditor] Imported route with ", nodes.size(), " nodes")
