extends Control
## Главный контроллер приложения — Редактор + Просмотр

@onready var story_panel: PanelContainer = $HBoxContainer/StoryPanel
@onready var graph_editor: Control = $HBoxContainer/GraphArea/GraphEditor
@onready var right_container: VBoxContainer = $HBoxContainer/RightContainer
@onready var system_panel: PanelContainer = $HBoxContainer/RightContainer/SystemPanel
@onready var service_panel: PanelContainer = $HBoxContainer/RightContainer/ServicePanel

# Навигация
@onready var nav_container: HBoxContainer = $NavContainer
@onready var prev_button: Button = $NavContainer/PrevButton
@onready var next_button: Button = $NavContainer/NextButton
@onready var step_label: Label = $NavContainer/StepLabel
@onready var export_button: Button = $NavContainer/ExportButton

# Заголовок
@onready var title_label: Label = $TitleLabel

# Режим
enum Mode { EDITOR, VIEWER }
var current_mode: Mode = Mode.EDITOR

func _ready() -> void:
	print("[Main] Starting in EDITOR mode...")
	
	# Подключить сигналы AppState
	AppState.step_changed.connect(_on_step_changed)
	AppState.route_loaded.connect(_on_route_loaded)
	
	# Подключить сигналы GraphEditor
	if graph_editor:
		graph_editor.node_selected.connect(_on_graph_node_selected)
		graph_editor.graph_changed.connect(_on_graph_changed)
	
	# Подключить кнопки
	if prev_button:
		prev_button.pressed.connect(_on_prev_pressed)
	if next_button:
		next_button.pressed.connect(_on_next_pressed)
	if export_button:
		export_button.pressed.connect(_on_export_pressed)
	
	# Загрузить существующий маршрут или начать с нуля
	_try_load_existing_route()
	
	_update_ui()

func _try_load_existing_route() -> void:
	# Сначала попробовать Universe Graph (канонический)
	var universe = ContractsLoader.load_universe_graph()
	if universe.has("nodes") and universe.nodes.size() > 0 and graph_editor:
		graph_editor.import_from_universe_graph(universe)
		print("[Main] Loaded Universe Graph with ", universe.nodes.size(), " nodes")
		return
	
	# Fallback: демо-маршрут
	var route = ContractsLoader.load_route("demo", "visitor.demo.route")
	if not route.is_empty() and graph_editor:
		graph_editor.import_from_route_json(route)
		print("[Main] Loaded existing route")

func _on_graph_node_selected(node_data: Dictionary) -> void:
	if node_data.is_empty():
		_clear_panels()
		_update_step_label_editor("")
		return
	
	# Обновить панели с данными узла
	if story_panel and story_panel.has_method("set_content"):
		story_panel.set_content(node_data.get("story", {}))
	
	if system_panel and system_panel.has_method("set_content"):
		system_panel.set_content(node_data.get("system", {}))
	
	if service_panel and service_panel.has_method("set_content"):
		service_panel.set_content(node_data.get("service", {}))
	
	_update_step_label_editor(node_data.get("label", ""))

func _on_graph_changed() -> void:
	# Граф изменился — можно автосохранять или помечать как "unsaved"
	if title_label:
		if not title_label.text.ends_with("*"):
			title_label.text = title_label.text + " *"

func _clear_panels() -> void:
	if story_panel and story_panel.has_method("set_content"):
		story_panel.set_content({})
	if system_panel and system_panel.has_method("set_content"):
		system_panel.set_content({})
	if service_panel and service_panel.has_method("set_content"):
		service_panel.set_content({})

func _update_step_label_editor(label: String) -> void:
	if step_label:
		if label.is_empty():
			step_label.text = "No selection"
		else:
			var node_count = graph_editor.nodes.size() if graph_editor else 0
			step_label.text = label + " (" + str(node_count) + " nodes)"

func _on_export_pressed() -> void:
	if not graph_editor:
		return
	
	var results = ExportManager.export_scene(graph_editor, "visitor.demo.route", "demo")
	
	if results.route:
		print("[Main] Export successful!")
		if title_label:
			title_label.text = "Route Graph Editor"  # Убрать *
		
		# Показать уведомление
		_show_notification("Exported to contracts!")
	else:
		_show_notification("Export failed!")

func _show_notification(text: String) -> void:
	# Простое уведомление в консоль
	print("[Notification] ", text)
	# TODO: Добавить визуальное уведомление

# === Режим VIEWER (для навигации по готовому маршруту) ===

func _on_route_loaded(route: Dictionary) -> void:
	if title_label:
		title_label.text = route.get("title", "Route Graph")
	_update_nav_buttons()

func _on_step_changed(step: Dictionary, index: int) -> void:
	if current_mode != Mode.VIEWER:
		return
	
	print("[Main] Step changed to: ", step.get("label", "Unknown"))
	
	if story_panel and story_panel.has_method("set_content"):
		story_panel.set_content(step.get("story", {}))
	
	if system_panel and system_panel.has_method("set_content"):
		system_panel.set_content(step.get("system", {}))
	
	if service_panel and service_panel.has_method("set_content"):
		service_panel.set_content(step.get("service", {}))
	
	_update_nav_buttons()
	_update_step_label_viewer()

func _update_nav_buttons() -> void:
	if current_mode == Mode.EDITOR:
		if prev_button:
			prev_button.visible = false
		if next_button:
			next_button.visible = false
		return
	
	if prev_button:
		prev_button.visible = true
		prev_button.disabled = not AppState.has_prev()
	if next_button:
		next_button.visible = true
		next_button.disabled = not AppState.has_next()

func _update_step_label_viewer() -> void:
	if step_label and current_mode == Mode.VIEWER:
		var info = AppState.get_route_info()
		step_label.text = "%s (%d/%d)" % [
			info.current_label,
			info.current_index + 1,
			info.total_steps
		]

func _update_ui() -> void:
	if current_mode == Mode.EDITOR:
		if title_label:
			title_label.text = "Route Graph Editor"
		if prev_button:
			prev_button.visible = false
		if next_button:
			next_button.visible = false
		if export_button:
			export_button.visible = true
	else:
		if export_button:
			export_button.visible = false

func _on_prev_pressed() -> void:
	if current_mode == Mode.VIEWER:
		AppState.prev_step()

func _on_next_pressed() -> void:
	if current_mode == Mode.VIEWER:
		AppState.next_step()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT:
				if current_mode == Mode.VIEWER:
					AppState.prev_step()
			KEY_RIGHT:
				if current_mode == Mode.VIEWER:
					AppState.next_step()
			KEY_E:
				if event.ctrl_pressed:
					_on_export_pressed()
			KEY_S:
				if event.ctrl_pressed:
					_on_export_pressed()  # Ctrl+S = экспорт
