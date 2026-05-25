extends Node2D

class_name Room

@export var room_id: StringName = &""


func get_room_id() -> StringName:
	return room_id


func is_room() -> bool:
	return true
