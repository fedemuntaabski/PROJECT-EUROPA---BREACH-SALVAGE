extends Node2D

class_name Room

@export var room_id: StringName = &""
@export var room_size: Vector2 = Vector2(160, 110)


func get_room_id() -> StringName:
	return room_id


func get_room_bounds() -> Rect2:
	return Rect2(-room_size * 0.5, room_size)


func is_room() -> bool:
	return true
