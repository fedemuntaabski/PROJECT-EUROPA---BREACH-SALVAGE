extends Node2D

class_name RoomExitZone


@export var source_room_id: StringName = &""
@export var target_room_id: StringName = &""
@export var exit_direction: StringName = &""
@export var zone_size: Vector2 = Vector2(20, 44)

const ACTIVE_MODULATE := Color(1.0, 0.92, 0.35, 0.72)
const INACTIVE_MODULATE := Color(1.0, 0.92, 0.35, 0.18)
const OVERLAP_MODULATE := Color(1.0, 1.0, 0.5, 0.95)

var _debug_shape: Polygon2D


func _ready() -> void:
	_ensure_debug_shape()
	_refresh_debug_shape()


func is_exit_zone() -> bool:
	return true


func get_zone_bounds() -> Rect2:
	return Rect2(-zone_size * 0.5, zone_size)


func contains_local_point(local_point: Vector2) -> bool:
	return get_zone_bounds().has_point(local_point)


func set_visual_state(is_current_room: bool, player_inside: bool) -> void:
	if not is_instance_valid(_debug_shape):
		_ensure_debug_shape()

	if player_inside:
		_debug_shape.modulate = OVERLAP_MODULATE
	elif is_current_room:
		_debug_shape.modulate = ACTIVE_MODULATE
	else:
		_debug_shape.modulate = INACTIVE_MODULATE


func _ensure_debug_shape() -> void:
	if is_instance_valid(_debug_shape):
		return

	_debug_shape = get_node_or_null("DebugShape") as Polygon2D
	if not is_instance_valid(_debug_shape):
		_debug_shape = Polygon2D.new()
		_debug_shape.name = "DebugShape"
		add_child(_debug_shape)

	_debug_shape.z_index = 5


func _refresh_debug_shape() -> void:
	if not is_instance_valid(_debug_shape):
		return

	var half_size: Vector2 = zone_size * 0.5
	_debug_shape.polygon = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y),
	])