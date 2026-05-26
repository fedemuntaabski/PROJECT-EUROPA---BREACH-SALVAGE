extends Node

class_name CharacterAnimationController


signal animation_state_changed(state_name: StringName)


@export var sprite_path: NodePath = ^"../Visuals/Sprite2D"
@export var direction_marker_path: NodePath = ^"../DirectionMarker"


var _current_state: StringName = &"idle"
var _facing_direction: Vector2 = Vector2.DOWN
var _sprite: Sprite2D
var _direction_marker: Node2D


func _ready() -> void:
	# This controller keeps animation-facing state isolated from gameplay logic.
	_sprite = get_node_or_null(sprite_path) as Sprite2D
	_direction_marker = get_node_or_null(direction_marker_path) as Node2D
	_apply_direction()


func set_facing_direction(direction: Vector2) -> void:
	var normalized_direction: Vector2 = direction.normalized()
	if normalized_direction == Vector2.ZERO:
		return

	_facing_direction = normalized_direction
	_apply_direction()


func set_state(state_name: StringName) -> void:
	if state_name == _current_state:
		return

	_current_state = state_name
	animation_state_changed.emit(_current_state)


func play_idle() -> void:
	set_state(&"idle")


func play_move() -> void:
	set_state(&"move")


func play_interact() -> void:
	set_state(&"interact")


func play_hurt() -> void:
	set_state(&"hurt")


func play_death() -> void:
	set_state(&"dead")


func _apply_direction() -> void:
	if is_instance_valid(_direction_marker):
		_direction_marker.rotation = _facing_direction.angle()

	if is_instance_valid(_sprite):
		_sprite.flip_h = _facing_direction.x < 0.0