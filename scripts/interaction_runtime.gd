extends Node
## Обработчик взаимодействий (Autoload: InteractionRuntime)

# Правила взаимодействия из контракта
var rules: Array = []

# Сигналы
signal effect_triggered(effect: Dictionary)
signal action_executed(action_id: String, action_type: String)

func _ready() -> void:
	print("[InteractionRuntime] Initialized")

## Загрузить правила
func load_rules(interaction_rules: Array) -> void:
	rules = interaction_rules
	print("[InteractionRuntime] Loaded ", rules.size(), " rules")

## Обработать событие
func handle_event(event_type: String, target: Dictionary) -> void:
	print("[InteractionRuntime] Event: ", event_type, " on ", target)
	
	for rule in rules:
		if _matches_trigger(rule.get("trigger", {}), event_type, target):
			_execute_effects(rule.get("effects", []))

## Проверить совпадение триггера
func _matches_trigger(trigger: Dictionary, event_type: String, target: Dictionary) -> bool:
	if trigger.get("event", "") != event_type:
		return false
	
	var trigger_target = trigger.get("target", {})
	if trigger_target.is_empty():
		return true
	
	# Проверить тип цели
	if trigger_target.has("type"):
		if target.get("type", "") != trigger_target.type:
			return false
	
	# Проверить ID цели
	if trigger_target.has("id"):
		if target.get("id", "") != trigger_target.id:
			return false
	
	return true

## Выполнить эффекты
func _execute_effects(effects: Array) -> void:
	for effect in effects:
		_execute_effect(effect)

## Выполнить один эффект
func _execute_effect(effect: Dictionary) -> void:
	var effect_type = effect.get("type", "")
	
	match effect_type:
		"log":
			print("[Effect:log] ", effect.get("message", ""))
		
		"highlight":
			var target = effect.get("target", "")
			print("[Effect:highlight] ", target)
			effect_triggered.emit(effect)
		
		"navigate":
			var step_id = effect.get("step_id", "")
			if step_id:
				AppState.go_to_step_by_id(step_id)
		
		"show_tooltip":
			print("[Effect:tooltip] ", effect.get("text", ""))
			effect_triggered.emit(effect)
		
		"play_sound":
			var sound_path = effect.get("path", "")
			print("[Effect:sound] ", sound_path)
			# TODO: Реализовать воспроизведение звука
		
		_:
			print("[Effect:unknown] ", effect_type)
			effect_triggered.emit(effect)

## Обработать клик по ref
func handle_ref_click(ref: Dictionary) -> void:
	print("[InteractionRuntime] Ref clicked: ", ref)
	handle_event("click", {"type": "ref", "id": ref.get("id", ""), "data": ref})

## Обработать клик по action
func handle_action_click(action: Dictionary) -> void:
	var action_id = action.get("id", "")
	var action_type = action.get("type", "")
	
	print("[InteractionRuntime] Action: ", action_id, " (", action_type, ")")
	
	match action_type:
		"navigate":
			# Если есть target, перейти к нему
			var target = action.get("target", "")
			if target:
				AppState.go_to_step_by_id(target)
			else:
				# Иначе просто следующий шаг
				AppState.next_step()
		
		"export":
			print("[Action:export] Exporting session...")
			# TODO: Реализовать экспорт
		
		"restart":
			var start_id = AppState.current_route.get("start_node_id", "")
			if start_id:
				AppState.go_to_step_by_id(start_id)
		
		_:
			print("[Action:custom] ", action_type)
	
	action_executed.emit(action_id, action_type)
	handle_event("click", {"type": "action", "id": action_id, "action_type": action_type})
