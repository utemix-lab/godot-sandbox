extends Control
## Главный контроллер — Чистый редактор графа

@onready var graph_editor: Control = $GraphEditor
@onready var export_button: Button = $BottomBar/ExportButton
@onready var title_label: Label = $TitleLabel
@onready var hint_label: Label = $BottomBar/HintLabel

func _ready() -> void:
	print("[Main] Graph Editor started")
	
	# Подключить сигналы GraphEditor
	if graph_editor:
		graph_editor.node_selected.connect(_on_graph_node_selected)
		graph_editor.graph_changed.connect(_on_graph_changed)
	
	# Подключить кнопку экспорта
	if export_button:
		export_button.pressed.connect(_on_export_pressed)

func _on_graph_node_selected(node_data: Dictionary) -> void:
	if node_data.is_empty():
		_update_hint("No selection")
		return
	
	var label = node_data.get("label", "Unknown")
	var node_count = graph_editor.nodes.size() if graph_editor else 0
	_update_hint("Selected: " + label + " | Total: " + str(node_count) + " nodes")

func _on_graph_changed() -> void:
	# Граф изменился — пометить как "unsaved"
	if title_label and not title_label.text.ends_with("*"):
		title_label.text = title_label.text + " *"

func _update_hint(text: String) -> void:
	if hint_label:
		hint_label.text = text

func _on_export_pressed() -> void:
	if not graph_editor:
		return
	
	var results = ExportManager.export_scene(graph_editor, "visitor.demo.route", "demo")
	
	if results.route:
		print("[Main] Export successful!")
		if title_label:
			title_label.text = "Graph Editor"  # Убрать *
		_update_hint("Exported! Press Reload in dream-graph.")
	else:
		_update_hint("Export failed!")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_S and event.ctrl_pressed:
			_on_export_pressed()
