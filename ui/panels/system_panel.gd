extends PanelContainer
## System panel - displays architecture/technical content

@onready var content_label: RichTextLabel = $MarginContainer/VBox/Content
@onready var refs_list: ItemList = $MarginContainer/VBox/RefsContainer/RefsList


func _ready() -> void:
	refs_list.item_clicked.connect(_on_ref_clicked)
	
	# Set panel style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.071, 0.071, 0.086, 0.95)
	style.border_width_top = 3
	style.border_color = Color(0.345, 0.651, 1.0)  # System accent color
	add_theme_stylebox_override("panel", style)


func update_content(data: Dictionary) -> void:
	var text = data.get("text", "")
	content_label.text = text if text else "No system info for this step."
	
	# Update refs
	refs_list.clear()
	var refs = data.get("refs", [])
	for ref in refs:
		var label = ref.get("label", ref.get("entity_id", "Unknown"))
		refs_list.add_item(label)
	
	# Hide refs container if no refs
	$MarginContainer/VBox/RefsContainer.visible = refs.size() > 0


func _on_ref_clicked(index: int, _at_position: Vector2, _button_index: int) -> void:
	var item_text = refs_list.get_item_text(index)
	print("[SystemPanel] Ref clicked: ", item_text)
	
	InteractionRuntime.process_event("click", {
		"type": "pointer-tag",
		"label": item_text,
		"panel": "system"
	})
