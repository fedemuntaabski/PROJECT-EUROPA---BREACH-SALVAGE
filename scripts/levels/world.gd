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
@onready var _camera: Camera2D = $Camera2D
@onready var _debug_label: Label = get_node_or_null("../UI/DebugInfo") as Label

const ACTIVE_ROOM_MODULATE := Color(1, 1, 1, 1)
const INACTIVE_ROOM_MODULATE := Color(0.75, 0.75, 0.75, 0.45)
const CAMERA_FOLLOW_SPEED := 8.0


func _ready() -> void:
	_cache_rooms()
	if _rooms.is_empty():
		push_error("World requires at least one Room child.")
		return

	if not _rooms.has(_current_room_id):
		_current_room_id = _rooms.keys()[0]

	_set_current_room(_current_room_id)
	if is_instance_valid(_player) and _rooms.has(_current_room_id):
		_player.global_position = _rooms[_current_room_id].global_position
	_update_debug_readout()
	_update_camera(0.0)


func _process(delta: float) -> void:
	_update_camera(delta)
	_update_debug_readout()


func try_move(direction: StringName) -> bool:
	return _attempt_directional_transition(direction)


func resolve_player_room() -> void:
	if not is_instance_valid(_player) or not _rooms.has(_current_room_id):
		return

	var current_room: Node2D = _rooms[_current_room_id]
	var local_position: Vector2 = _player.global_position - current_room.global_position
	var room_bounds: Rect2 = _get_room_bounds(current_room)
	var half_extents: Vector2 = room_bounds.size * 0.5
	var connections: Dictionary = ROOM_CONNECTIONS.get(_current_room_id, {})

	var transition_direction: StringName = &""
	var transition_overshoot: float = 0.0

	if local_position.x > half_extents.x:
		if connections.has(&"right"):
			transition_direction = &"right"
			transition_overshoot = local_position.x - half_extents.x
		else:
			local_position.x = half_extents.x
	elif local_position.x < -half_extents.x:
		if connections.has(&"left"):
			transition_direction = &"left"
			transition_overshoot = -half_extents.x - local_position.x
		else:
			local_position.x = -half_extents.x

	if local_position.y > half_extents.y:
		if connections.has(&"down") and local_position.y - half_extents.y > transition_overshoot:
			transition_direction = &"down"
			transition_overshoot = local_position.y - half_extents.y
		else:
			local_position.y = half_extents.y
	elif local_position.y < -half_extents.y:
		if connections.has(&"up") and -half_extents.y - local_position.y > transition_overshoot:
			transition_direction = &"up"
			transition_overshoot = -half_extents.y - local_position.y
		else:
			local_position.y = -half_extents.y

	if transition_direction != &"":
		_transition_player_to_room(transition_direction, transition_overshoot, local_position)
	else:
		_player.global_position = current_room.global_position + local_position

	_update_debug_readout()


func _cache_rooms() -> void:
	for child in get_children():
		if child.has_method("get_room_id") and child.has_method("is_room") and child.is_room():
			var room_id: StringName = child.get_room_id()
			if room_id == &"":
				room_id = StringName(child.name)
			_rooms[room_id] = child


func _set_current_room(room_id: StringName) -> void:
	_current_room_id = room_id
	_apply_room_visual_state()
	room_changed.emit(room_id)


func _attempt_directional_transition(direction: StringName) -> bool:
	var connections: Dictionary = ROOM_CONNECTIONS.get(_current_room_id, {})
	if not connections.has(direction):
		return false

	var next_room_id: StringName = connections[direction]
	if not _rooms.has(next_room_id):
		return false

	_set_current_room(next_room_id)
	return true


func _transition_player_to_room(direction: StringName, overshoot: float, local_position: Vector2) -> void:
	var connections: Dictionary = ROOM_CONNECTIONS.get(_current_room_id, {})
	if not connections.has(direction) or not _rooms.has(connections[direction]):
		return

	var next_room_id: StringName = connections[direction]
	var next_room: Node2D = _rooms[next_room_id]
	var next_bounds: Rect2 = _get_room_bounds(next_room)
	var next_local_position: Vector2 = local_position

	match direction:
		&"right":
			next_local_position.x = next_bounds.position.x + overshoot
			next_local_position.y = clamp(local_position.y, next_bounds.position.y, next_bounds.position.y + next_bounds.size.y)
		&"left":
			next_local_position.x = next_bounds.position.x + next_bounds.size.x - overshoot
			next_local_position.y = clamp(local_position.y, next_bounds.position.y, next_bounds.position.y + next_bounds.size.y)
		&"down":
			next_local_position.y = next_bounds.position.y + overshoot
			next_local_position.x = clamp(local_position.x, next_bounds.position.x, next_bounds.position.x + next_bounds.size.x)
		&"up":
			next_local_position.y = next_bounds.position.y + next_bounds.size.y - overshoot
			next_local_position.x = clamp(local_position.x, next_bounds.position.x, next_bounds.position.x + next_bounds.size.x)

	_current_room_id = next_room_id
	_player.global_position = next_room.global_position + next_local_position
	_apply_room_visual_state()
	print("Current room: ", next_room_id, " | player local position: ", next_local_position)
	room_changed.emit(next_room_id)


func _apply_room_visual_state() -> void:
	for candidate_room_id: StringName in _rooms.keys():
		var candidate_room: Node2D = _rooms[candidate_room_id]
		if is_instance_valid(candidate_room):
			candidate_room.modulate = ACTIVE_ROOM_MODULATE if candidate_room_id == _current_room_id else INACTIVE_ROOM_MODULATE


func _get_room_bounds(room: Node2D) -> Rect2:
	if room.has_method("get_room_bounds"):
		return room.get_room_bounds()
	return Rect2(Vector2(-80, -55), Vector2(160, 110))


func _update_camera(delta: float) -> void:
	if not is_instance_valid(_camera) or not is_instance_valid(_player):
		return

	var follow_weight: float = 1.0 if delta <= 0.0 else clamp(CAMERA_FOLLOW_SPEED * delta, 0.0, 1.0)
	_camera.global_position = _camera.global_position.lerp(_player.global_position, follow_weight)


func _update_debug_readout() -> void:
	if not is_instance_valid(_debug_label) or not is_instance_valid(_player) or not _rooms.has(_current_room_id):
		return

	var current_room: Node2D = _rooms[_current_room_id]
	var local_position: Vector2 = _player.global_position - current_room.global_position
	_debug_label.text = "Room: %s\nLocal: (%.1f, %.1f)" % [_current_room_id, local_position.x, local_position.y]
