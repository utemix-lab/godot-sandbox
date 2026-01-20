extends PanelContainer
## Панель Service — "Что можно сделать"

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var content_label: RichTextLabel = $VBoxContainer/ContentLabel
@onready var actions_container: VBoxContainer = $VBoxContainer/ActionsContainer

# Текущий контент
var current_content: Dictionary = {}

func _ready() -> void:
	if content_label:
		content_label.bbcode_enabled = true
		content_label.meta_clicked.connect(_on_meta_clicked)

## Установить контент
func set_content(service: Dictionary) -> void:
	current_content = service
	
	if title_label:
		title_label.text = "🎯 Service"
	
	if content_label:
		var text = service.get("text", "")
		content_label.text = MarkdownParser.to_bbcode(text)
	
	_render_actions(service.get("actions", []))

## Отрендерить actions
func _render_actions(actions: Array) -> void:
	if not actions_container:
		return
	
	for child in actions_container.get_children():
		child.queue_free()
	
	if actions.is_empty():
		return
	
	var actions_title = Label.new()
	actions_title.text = "Действия:"
	actions_title.add_theme_font_size_override("font_size", 12)
	actions_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	actions_container.add_child(actions_title)
	
	for action in actions:
		var button = Button.new()
		button.text = _get_action_icon(action.get("type", "")) + " " + action.get("label", action.get("id", ""))
		button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		button.pressed.connect(_on_action_clicked.bind(action))
		actions_container.add_child(button)

func _get_action_icon(action_type: String) -> String:
	match action_type:
		"navigate":
			return "➡️"
		"export":
			return "📤"
		"generate":
			return "✨"
		"compare":
			return "🔍"
		"restart":
			return "🔄"
		_:
			return "▶️"

func _on_action_clicked(action: Dictionary) -> void:
	InteractionRuntime.handle_action_click(action)

func _on_meta_clicked(meta: Variant) -> void:
	var meta_str = str(meta)
	if meta_str.begins_with("http"):
		OS.shell_open(meta_str)
