extends PanelContainer
## Панель Story — "Что происходит"

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var content_label: RichTextLabel = $VBoxContainer/ContentLabel
@onready var refs_container: VBoxContainer = $VBoxContainer/RefsContainer

# Текущий контент
var current_content: Dictionary = {}

func _ready() -> void:
	# Настроить RichTextLabel
	if content_label:
		content_label.bbcode_enabled = true
		content_label.meta_clicked.connect(_on_meta_clicked)

## Установить контент
func set_content(story: Dictionary) -> void:
	current_content = story
	
	# Заголовок
	if title_label:
		title_label.text = "📖 Story"
	
	# Текст с Markdown
	if content_label:
		var text = story.get("text", "")
		content_label.text = MarkdownParser.to_bbcode(text)
	
	# Refs (ссылки на Universe Graph)
	_render_refs(story.get("refs", []))

## Отрендерить refs
func _render_refs(refs: Array) -> void:
	if not refs_container:
		return
	
	# Очистить старые
	for child in refs_container.get_children():
		child.queue_free()
	
	if refs.is_empty():
		return
	
	# Заголовок refs
	var refs_title = Label.new()
	refs_title.text = "Ссылки:"
	refs_title.add_theme_font_size_override("font_size", 12)
	refs_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	refs_container.add_child(refs_title)
	
	# Кнопки refs
	for ref in refs:
		var button = Button.new()
		button.text = _get_ref_icon(ref.get("type", "")) + " " + ref.get("label", ref.get("id", ""))
		button.flat = true
		button.add_theme_color_override("font_color", Color(0.4, 0.4, 1.0))
		button.pressed.connect(_on_ref_clicked.bind(ref))
		refs_container.add_child(button)

## Получить иконку для типа ref
func _get_ref_icon(ref_type: String) -> String:
	match ref_type:
		"project":
			return "📁"
		"concept":
			return "💡"
		"document":
			return "📄"
		"principle":
			return "⚖️"
		"pattern":
			return "🔄"
		"service":
			return "⚙️"
		"character":
			return "👤"
		_:
			return "🔗"

## Обработать клик по ref
func _on_ref_clicked(ref: Dictionary) -> void:
	InteractionRuntime.handle_ref_click(ref)

## Обработать клик по мета-ссылке (из BBCode)
func _on_meta_clicked(meta: Variant) -> void:
	var meta_str = str(meta)
	print("[StoryPanel] Meta clicked: ", meta_str)
	
	if meta_str.begins_with("tag:"):
		var tag = meta_str.substr(4)
		print("[StoryPanel] Tag clicked: #", tag)
		InteractionRuntime.handle_event("click", {"type": "tag", "id": tag})
	elif meta_str.begins_with("http"):
		OS.shell_open(meta_str)
	else:
		InteractionRuntime.handle_event("click", {"type": "link", "id": meta_str})
