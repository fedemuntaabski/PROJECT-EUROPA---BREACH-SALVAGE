extends Node2D


signal room_changed(room_id: StringName)

const START_ROOM_ID: StringName = &"room_a"
const ROOM_CONNECTIONS := {
	&"room_a": {
		&"right": &"room_b",
		&"down": &"room_c",
	},
	&"room_b": {
		&"left": &"room_a",
		&"down": &"room_d",
	},
	&"room_c": {
		&"up": &"room_a",
		&"right": &"room_d",
	},
	&"room_d": {
		&"up": &"room_b",
		&"left": &"room_c",
	},
}

var _rooms: Dictionary[StringName, Node2D] = {}
var _current_room_id: StringName = START_ROOM_ID

@onready var _player: Node2D = $Player


func _ready() -> void:
	_cache_rooms()
	if _rooms.is_empty():
		push_error("World requires at least one Room child.")
		return

	if not _rooms.has(_current_room_id):
		_current_room_id = _rooms.keys()[0]

	_set_current_room(_current_room_id)


func try_move(direction: StringName) -> bool:
	var connections: Dictionary = ROOM_CONNECTIONS.get(_current_room_id, {})
	if not connections.has(direction):
		return false

	var next_room_id: StringName = connections[direction]
	if not _rooms.has(next_room_id):
		return false

	_set_current_room(next_room_id)
	return true


func _cache_rooms() -> void:
	for child in get_children():
		if child.has_method("get_room_id") and child.has_method("is_room") and child.is_room():
			var room_id: StringName = child.get_room_id()
			if room_id == &"":
				room_id = StringName(child.name)
			_rooms[room_id] = child


func _set_current_room(room_id: StringName) -> void:
	_current_room_id = room_id
	var active_room: Node2D = _rooms[room_id]

	if is_instance_valid(_player):
		_player.global_position = active_room.global_position

	print("Current room: ", room_id)
	room_changed.emit(room_id)
