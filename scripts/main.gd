extends Control
## Главный контроллер приложения

@onready var story_panel: PanelContainer = $HBoxContainer/StoryPanel
@onready var graph_area: ColorRect = $HBoxContainer/GraphArea
@onready var right_container: VBoxContainer = $HBoxContainer/RightContainer
@onready var system_panel: PanelContainer = $HBoxContainer/RightContainer/SystemPanel
@onready var service_panel: PanelContainer = $HBoxContainer/RightContainer/ServicePanel

# Навигация
@onready var nav_container: HBoxContainer = $NavContainer
@onready var prev_button: Button = $NavContainer/PrevButton
@onready var next_button: Button = $NavContainer/NextButton
@onready var step_label: Label = $NavContainer/StepLabel

# Заголовок
@onready var title_label: Label = $TitleLabel

func _ready() -> void:
	print("[Main] Starting...")
	
	# Подключить сигналы
	AppState.step_changed.connect(_on_step_changed)
	AppState.route_loaded.connect(_on_route_loaded)
	
	if prev_button:
		prev_button.pressed.connect(_on_prev_pressed)
	if next_button:
		next_button.pressed.connect(_on_next_pressed)
	
	# Загрузить контракты
	_load_contracts()

func _load_contracts() -> void:
	# Загрузить layout
	AppState.layout = ContractsLoader.load_layout("visitor")
	print("[Main] Layout: ", AppState.layout)
	
	# Загрузить interaction rules
	AppState.interaction_rules = ContractsLoader.load_interaction("visitor")
	InteractionRuntime.load_rules(AppState.interaction_rules)
	
	# Загрузить bindings
	AppState.bindings = ContractsLoader.load_bindings("visitor")
	
	# Загрузить демо-маршрут
	var route = ContractsLoader.load_route("demo", "visitor.demo.route")
	if not route.is_empty():
		AppState.load_route(route)
	else:
		push_error("[Main] Failed to load demo route!")

func _on_route_loaded(route: Dictionary) -> void:
	if title_label:
		title_label.text = route.get("title", "Route Graph")
	_update_nav_buttons()

func _on_step_changed(step: Dictionary, index: int) -> void:
	print("[Main] Step changed to: ", step.get("label", "Unknown"))
	
	# Обновить панели
	if story_panel and story_panel.has_method("set_content"):
		story_panel.set_content(step.get("story", {}))
	
	if system_panel and system_panel.has_method("set_content"):
		system_panel.set_content(step.get("system", {}))
	
	if service_panel and service_panel.has_method("set_content"):
		service_panel.set_content(step.get("service", {}))
	
	# Обновить навигацию
	_update_nav_buttons()
	_update_step_label()

func _update_nav_buttons() -> void:
	if prev_button:
		prev_button.disabled = not AppState.has_prev()
	if next_button:
		next_button.disabled = not AppState.has_next()

func _update_step_label() -> void:
	if step_label:
		var info = AppState.get_route_info()
		step_label.text = "%s (%d/%d)" % [
			info.current_label,
			info.current_index + 1,
			info.total_steps
		]

func _on_prev_pressed() -> void:
	AppState.prev_step()

func _on_next_pressed() -> void:
	AppState.next_step()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT:
				AppState.prev_step()
			KEY_RIGHT:
				AppState.next_step()
			KEY_ESCAPE:
				# Сбросить выделение
				pass
			KEY_R:
				# Restart
				if event.ctrl_pressed:
					var start_id = AppState.current_route.get("start_node_id", "")
					if start_id:
						AppState.go_to_step_by_id(start_id)
