extends Node

class_name HealthComponent


signal health_changed(current_health: int, max_health: int)
signal died
signal healed(amount: int, source: Node)
signal damaged(amount: int, source: Node)


@export var max_health: int = 100
@export var start_full_health: bool = true
@export var starting_health: int = 100


var current_health: int = 0
var _is_alive: bool = true


func _ready() -> void:
	# This component owns the actor's survivability state and emits lifecycle events.
	if start_full_health:
		current_health = max_health
	else:
		current_health = clamp(starting_health, 0, max_health)

	_is_alive = current_health > 0
	health_changed.emit(current_health, max_health)


func apply_damage(amount: int, source: Node = null) -> int:
	if amount <= 0 or not _is_alive:
		return current_health

	current_health = max(current_health - amount, 0)
	damaged.emit(amount, source)
	health_changed.emit(current_health, max_health)

	if current_health == 0:
		_is_alive = false
		died.emit()

	return current_health


func heal(amount: int, source: Node = null) -> int:
	if amount <= 0 or not _is_alive:
		return current_health

	current_health = min(current_health + amount, max_health)
	healed.emit(amount, source)
	health_changed.emit(current_health, max_health)
	return current_health


func set_max_health(value: int) -> void:
	var was_alive: bool = is_alive()
	max_health = max(value, 1)
	current_health = clamp(current_health, 0, max_health)
	_is_alive = current_health > 0
	health_changed.emit(current_health, max_health)
	if was_alive and current_health == 0:
		died.emit()


func set_current_health(value: int) -> void:
	var was_alive: bool = is_alive()
	current_health = clamp(value, 0, max_health)
	_is_alive = current_health > 0
	health_changed.emit(current_health, max_health)
	if was_alive and current_health == 0:
		died.emit()


func is_alive() -> bool:
	return _is_alive and current_health > 0


func is_at_full_health() -> bool:
	return current_health >= max_health