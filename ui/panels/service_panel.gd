extends PanelContainer
## Service panel - displays actions and affordances

@onready var content_label: RichTextLabel = $MarginContainer/VBox/Content
@onready var actions_container: VBoxContainer = $MarginContainer/VBox/ActionsContainer/ActionButtons


func _ready() -> void:
	# Set panel style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.071, 0.071, 0.086, 0.95)
	style.border_width_bottom = 3
	style.border_color = Color(0.133, 0.773, 0.369)  # Service accent color
	add_theme_stylebox_override("panel", style)


func update_content(data: Dictionary) -> void:
	var text = data.get("text", "")
	content_label.text = text if text else "No actions for this step."
	
	# Clear existing buttons
	for child in actions_container.get_children():
		child.queue_free()
	
	# Create action buttons
	var actions = data.get("actions", [])
	for action in actions:
		var button = Button.new()
		button.text = action.get("label", "Action")
		button.set_meta("action_id", action.get("id", ""))
		button.set_meta("action_type", action.get("type", "custom"))
		button.pressed.connect(_on_action_pressed.bind(action))
		actions_container.add_child(button)
	
	# Hide actions container if no actions
	$MarginContainer/VBox/ActionsContainer.visible = actions.size() > 0


func _on_action_pressed(action: Dictionary) -> void:
	var action_id = action.get("id", "")
	var action_type = action.get("type", "custom")
	var action_label = action.get("label", "Unknown")
	
	print("[ServicePanel] Action pressed: ", action_label, " (", action_type, ")")
	
	InteractionRuntime.process_event("click", {
		"type": "action-icon",
		"action": action_id,
		"actionType": action_type,
		"label": action_label,
		"panel": "service"
	})
