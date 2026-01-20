extends PanelContainer
## Панель System — "Как это устроено"

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var content_label: RichTextLabel = $VBoxContainer/ContentLabel
@onready var refs_container: VBoxContainer = $VBoxContainer/RefsContainer

# Текущий контент
var current_content: Dictionary = {}

func _ready() -> void:
	if content_label:
		content_label.bbcode_enabled = true
		content_label.meta_clicked.connect(_on_meta_clicked)

## Установить контент
func set_content(system: Dictionary) -> void:
	current_content = system
	
	if title_label:
		title_label.text = "⚙️ System"
	
	if content_label:
		var text = system.get("text", "")
		content_label.text = MarkdownParser.to_bbcode(text)
	
	_render_refs(system.get("refs", []))

## Отрендерить refs
func _render_refs(refs: Array) -> void:
	if not refs_container:
		return
	
	for child in refs_container.get_children():
		child.queue_free()
	
	if refs.is_empty():
		return
	
	var refs_title = Label.new()
	refs_title.text = "Архитектура:"
	refs_title.add_theme_font_size_override("font_size", 12)
	refs_title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	refs_container.add_child(refs_title)
	
	for ref in refs:
		var button = Button.new()
		button.text = _get_ref_icon(ref.get("type", "")) + " " + ref.get("label", ref.get("id", ""))
		button.flat = true
		button.add_theme_color_override("font_color", Color(0.3, 0.7, 0.4))
		button.pressed.connect(_on_ref_clicked.bind(ref))
		refs_container.add_child(button)

func _get_ref_icon(ref_type: String) -> String:
	match ref_type:
		"repo":
			return "📦"
		"adr":
			return "📋"
		"spec":
			return "📐"
		"decision":
			return "✅"
		"pattern":
			return "🔄"
		_:
			return "🔧"

func _on_ref_clicked(ref: Dictionary) -> void:
	InteractionRuntime.handle_ref_click(ref)

func _on_meta_clicked(meta: Variant) -> void:
	var meta_str = str(meta)
	if meta_str.begins_with("http"):
		OS.shell_open(meta_str)
	else:
		InteractionRuntime.handle_event("click", {"type": "link", "id": meta_str})
