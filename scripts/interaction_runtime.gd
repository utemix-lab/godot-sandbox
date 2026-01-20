extends Node
## Processes interaction rules from contracts

signal effect_executed(effect_type: String, details: Dictionary)

var _rules: Array = []


func _ready() -> void:
	# Wait for contracts to load
	ContractsLoader.contracts_loaded.connect(_on_contracts_loaded)
	AppState.effect_triggered.connect(_execute_effect)
	print("[InteractionRuntime] Initialized")


func _on_contracts_loaded() -> void:
	_rules = AppState.interactions.get("rules", [])
	print("[InteractionRuntime] Loaded ", _rules.size(), " rules")


func process_event(event_type: String, target: Dictionary) -> void:
	"""
	Process an event and execute matching rules.
	
	event_type: "click", "hover", etc.
	target: { "type": "tag", "label": "...", ... }
	"""
	print("[InteractionRuntime] Event: ", event_type, " on ", target)
	
	for rule in _rules:
		if _matches_rule(rule, event_type, target):
			_execute_rule(rule, target)


func _matches_rule(rule: Dictionary, event_type: String, target: Dictionary) -> bool:
	var trigger = rule.get("trigger", {})
	
	# Check event type
	if trigger.get("event") != event_type:
		return false
	
	# Check target type
	var trigger_target = trigger.get("target", {})
	if trigger_target.has("type"):
		if trigger_target["type"] != target.get("type"):
			return false
	
	# Check additional conditions
	if trigger_target.has("expandable"):
		if trigger_target["expandable"] != target.get("expandable", false):
			return false
	
	return true


func _execute_rule(rule: Dictionary, target: Dictionary) -> void:
	print("[InteractionRuntime] Executing rule: ", rule.get("id", "unknown"))
	
	var effects = rule.get("effects", [])
	for effect in effects:
		var processed_effect = _interpolate_effect(effect, target)
		_execute_effect(processed_effect)


func _interpolate_effect(effect: Dictionary, target: Dictionary) -> Dictionary:
	"""Replace {{target.xxx}} placeholders with actual values."""
	var result = effect.duplicate(true)
	
	for key in result.keys():
		if result[key] is String:
			result[key] = _interpolate_string(result[key], target)
	
	return result


func _interpolate_string(template: String, target: Dictionary) -> String:
	var result = template
	
	# Replace {{target.xxx}} patterns
	var regex = RegEx.new()
	regex.compile("\\{\\{target\\.([^}]+)\\}\\}")
	
	for match_result in regex.search_all(template):
		var key = match_result.get_string(1)
		var value = target.get(key, "")
		result = result.replace(match_result.get_string(0), str(value))
	
	return result


func _execute_effect(effect: Dictionary) -> void:
	var effect_type = effect.get("type", "")
	
	match effect_type:
		"highlight":
			_effect_highlight(effect)
		"log":
			_effect_log(effect)
		"navigate":
			_effect_navigate(effect)
		"select":
			_effect_select(effect)
		"update":
			_effect_update(effect)
		"toggle-expand":
			_effect_toggle_expand(effect)
		"toggle-collapse":
			_effect_toggle_collapse(effect)
		"execute":
			_effect_execute(effect)
		"open-external":
			_effect_open_external(effect)
		"tooltip":
			_effect_tooltip(effect)
		"focus":
			_effect_focus(effect)
		_:
			print("[InteractionRuntime] Unknown effect type: ", effect_type)
	
	effect_executed.emit(effect_type, effect)


func _effect_highlight(effect: Dictionary) -> void:
	var target = effect.get("target", "")
	var duration = effect.get("duration", 500)
	print("[Effect:highlight] Target: ", target, ", Duration: ", duration, "ms")
	# TODO: Implement actual highlight animation


func _effect_log(effect: Dictionary) -> void:
	var message = effect.get("message", "")
	print("[Effect:log] ", message)


func _effect_navigate(effect: Dictionary) -> void:
	var to = effect.get("to", "")
	print("[Effect:navigate] To: ", to)
	
	if to.begins_with("step:"):
		var step_id = to.substr(5)
		AppState.set_current_step(step_id)
	elif to.begins_with("actor:"):
		var actor_id = to.substr(6)
		print("[Effect:navigate] Actor navigation not implemented: ", actor_id)


func _effect_select(effect: Dictionary) -> void:
	var target = effect.get("target", "")
	print("[Effect:select] Target: ", target)
	
	if target.begins_with("step:"):
		var step_id = target.substr(5)
		AppState.set_current_step(step_id)


func _effect_update(effect: Dictionary) -> void:
	var panel = effect.get("panel", "")
	var content = effect.get("content", "")
	print("[Effect:update] Panel: ", panel, ", Content: ", content)
	# Panels are updated via AppState signals


func _effect_toggle_expand(effect: Dictionary) -> void:
	var target = effect.get("target", "")
	print("[Effect:toggle-expand] Target: ", target)
	# TODO: Implement expand/collapse


func _effect_toggle_collapse(effect: Dictionary) -> void:
	var panel = effect.get("panel", "")
	print("[Effect:toggle-collapse] Panel: ", panel)
	
	if AppState.panel_states.has(panel):
		AppState.panel_states[panel]["collapsed"] = not AppState.panel_states[panel]["collapsed"]


func _effect_execute(effect: Dictionary) -> void:
	var action = effect.get("action", "")
	print("[Effect:execute] Action: ", action)
	# TODO: Implement action execution


func _effect_open_external(effect: Dictionary) -> void:
	var url = effect.get("url", "")
	print("[Effect:open-external] URL: ", url)
	OS.shell_open(url)


func _effect_tooltip(effect: Dictionary) -> void:
	var content = effect.get("content", "")
	var position = effect.get("position", "above")
	print("[Effect:tooltip] Content: ", content, ", Position: ", position)
	# TODO: Implement tooltip display


func _effect_focus(effect: Dictionary) -> void:
	var target = effect.get("target", "")
	print("[Effect:focus] Target: ", target)
	# TODO: Implement focus (camera/highlight)
