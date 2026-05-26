extends Node

class_name AbilityComponent


signal ability_registered(ability_id: StringName)
signal ability_used(ability_id: StringName, user: Node, payload: Dictionary)
signal ability_unavailable(ability_id: StringName)


@export var role_name: StringName = &""


var _abilities: Dictionary = {}


func register_ability(ability_id: StringName, ability_data: Dictionary = {}) -> void:
	# The component only stores ability metadata for now; actual abilities can be added later.
	_abilities[ability_id] = ability_data.duplicate(true)
	ability_registered.emit(ability_id)


func has_ability(ability_id: StringName) -> bool:
	return _abilities.has(ability_id)


func get_ability_data(ability_id: StringName) -> Dictionary:
	if not _abilities.has(ability_id):
		return {}
	return _abilities[ability_id]


func use_ability(ability_id: StringName, payload: Dictionary = {}) -> bool:
	if not has_ability(ability_id):
		ability_unavailable.emit(ability_id)
		return false

	ability_used.emit(ability_id, get_parent(), payload)
	return true


func clear_abilities() -> void:
	_abilities.clear()


func get_registered_ability_ids() -> Array[StringName]:
	return _abilities.keys()