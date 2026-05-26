extends Node

class_name StatusEffectComponent


signal status_effect_added(effect_id: StringName)
signal status_effect_removed(effect_id: StringName)
signal status_effects_cleared


var _status_effects: Dictionary = {}


func add_status_effect(effect_id: StringName, effect_data: Dictionary = {}) -> void:
	# This is a storage-and-events layer only; effect resolution can be built on top later.
	_status_effects[effect_id] = effect_data.duplicate(true)
	status_effect_added.emit(effect_id)


func remove_status_effect(effect_id: StringName) -> void:
	if _status_effects.erase(effect_id):
		status_effect_removed.emit(effect_id)


func has_status_effect(effect_id: StringName) -> bool:
	return _status_effects.has(effect_id)


func get_status_effect(effect_id: StringName) -> Dictionary:
	if not _status_effects.has(effect_id):
		return {}
	return _status_effects[effect_id]


func clear_status_effects() -> void:
	if _status_effects.is_empty():
		return

	_status_effects.clear()
	status_effects_cleared.emit()


func get_status_effect_ids() -> Array[StringName]:
	return _status_effects.keys()