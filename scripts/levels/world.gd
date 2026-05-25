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
const EXIT_ZONE_SIZE := Vector2(20, 44)
const EXIT_SPAWN_INSET := 32.0
const CAMERA_FOLLOW_SPEED := 8.0
const ROOM_EXIT_ZONE_SCRIPT := preload("res://scripts/levels/room_exit_zone.gd")


func _ready() -> void:
	_cache_rooms()
	if _rooms.is_empty():
		push_error("World requires at least one Room child.")
		return

	if not _rooms.has(_current_room_id):
		_current_room_id = _rooms.keys()[0]

	_build_exit_zones()
	_set_current_room(_current_room_id)
	if is_instance_valid(_player) and _rooms.has(_current_room_id):
		_player.global_position = _rooms[_current_room_id].global_position
	_update_debug_readout()
	_update_camera(0.0)


func _process(delta: float) -> void:
	_resolve_player_state()
	_update_camera(delta)
	_update_debug_readout()


func _resolve_player_state() -> void:
	if not is_instance_valid(_player) or not _rooms.has(_current_room_id):
		return

	var current_room: Node2D = _rooms[_current_room_id]
	var room_bounds: Rect2 = _get_room_bounds(current_room)
	var local_position: Vector2 = _player.global_position - current_room.global_position
	local_position = _clamp_local_position_to_room(local_position, room_bounds)
	_player.global_position = current_room.global_position + local_position

	var active_exit_zone = _find_active_exit_zone(current_room, local_position)
	_update_room_visual_state(local_position)
	if is_instance_valid(active_exit_zone):
		_transition_player_to_room(active_exit_zone, local_position)


func _cache_rooms() -> void:
	for child in get_children():
		if child.has_method("get_room_id") and child.has_method("is_room") and child.is_room():
			var room_id: StringName = child.get_room_id()
			if room_id == &"":
				room_id = StringName(child.name)
			_rooms[room_id] = child


func _build_exit_zones() -> void:
	for room_id in _rooms.keys():
		var current_room_id: StringName = room_id
		var room: Node2D = _rooms[current_room_id]
		var connections: Dictionary = ROOM_CONNECTIONS.get(current_room_id, {})
		for direction in connections.keys():
			var target_room_id: StringName = connections[direction]
			if not _rooms.has(target_room_id):
				continue

			var exit_zone = ROOM_EXIT_ZONE_SCRIPT.new()
			exit_zone.source_room_id = current_room_id
			exit_zone.target_room_id = target_room_id
			exit_zone.exit_direction = direction
			exit_zone.zone_size = EXIT_ZONE_SIZE
			exit_zone.name = "%s_%s_exit" % [current_room_id, direction]
			room.add_child(exit_zone)
			_position_exit_zone(exit_zone, room, direction)


func _set_current_room(room_id: StringName) -> void:
	_current_room_id = room_id
	_update_room_visual_state()
	room_changed.emit(room_id)



func _transition_player_to_room(exit_zone, local_position: Vector2) -> void:
	if not is_instance_valid(exit_zone) or not _rooms.has(exit_zone.target_room_id):
		return

	var next_room_id: StringName = exit_zone.target_room_id
	var next_room: Node2D = _rooms[next_room_id]
	var next_bounds: Rect2 = _get_room_bounds(next_room)
	var next_local_position: Vector2 = local_position

	match exit_zone.exit_direction:
		&"right":
			next_local_position.x = next_bounds.position.x + EXIT_SPAWN_INSET
			next_local_position.y = clamp(local_position.y, next_bounds.position.y + EXIT_SPAWN_INSET, next_bounds.position.y + next_bounds.size.y - EXIT_SPAWN_INSET)
		&"left":
			next_local_position.x = next_bounds.position.x + next_bounds.size.x - EXIT_SPAWN_INSET
			next_local_position.y = clamp(local_position.y, next_bounds.position.y + EXIT_SPAWN_INSET, next_bounds.position.y + next_bounds.size.y - EXIT_SPAWN_INSET)
		&"down":
			next_local_position.y = next_bounds.position.y + EXIT_SPAWN_INSET
			next_local_position.x = clamp(local_position.x, next_bounds.position.x + EXIT_SPAWN_INSET, next_bounds.position.x + next_bounds.size.x - EXIT_SPAWN_INSET)
		&"up":
			next_local_position.y = next_bounds.position.y + next_bounds.size.y - EXIT_SPAWN_INSET
			next_local_position.x = clamp(local_position.x, next_bounds.position.x + EXIT_SPAWN_INSET, next_bounds.position.x + next_bounds.size.x - EXIT_SPAWN_INSET)

	_current_room_id = next_room_id
	_player.global_position = next_room.global_position + next_local_position
	_update_room_visual_state(next_local_position)
	print("Current room: ", next_room_id, " | player local position: ", next_local_position)
	room_changed.emit(next_room_id)


func _update_room_visual_state(player_local_position: Vector2 = Vector2.ZERO) -> void:
	for candidate_room_id: StringName in _rooms.keys():
		var candidate_room: Node2D = _rooms[candidate_room_id]
		if is_instance_valid(candidate_room):
			candidate_room.modulate = ACTIVE_ROOM_MODULATE if candidate_room_id == _current_room_id else INACTIVE_ROOM_MODULATE
			_update_exit_zone_visual_state(candidate_room_id, player_local_position if candidate_room_id == _current_room_id else Vector2.ZERO)


func _update_exit_zone_visual_state(room_id: StringName, player_local_position: Vector2) -> void:
	var room: Node2D = _rooms.get(room_id, null)
	if not is_instance_valid(room):
		return

	var exit_zones: Array = _get_room_exit_zones(room)
	for exit_zone_variant in exit_zones:
		var exit_zone = exit_zone_variant
		if not is_instance_valid(exit_zone):
			continue

		var is_current_room: bool = room_id == _current_room_id
		var player_inside: bool = is_current_room and exit_zone.contains_local_point(player_local_position - exit_zone.position)
		exit_zone.set_visual_state(is_current_room, player_inside)


func _get_room_exit_zones(room: Node2D) -> Array:
	if room.has_method("get_exit_zones"):
		return room.get_exit_zones()
	return []


func _find_active_exit_zone(current_room: Node2D, local_position: Vector2):
	var exit_zones: Array = _get_room_exit_zones(current_room)
	for exit_zone_variant in exit_zones:
		var exit_zone = exit_zone_variant
		if is_instance_valid(exit_zone) and exit_zone.contains_local_point(local_position - exit_zone.position):
			return exit_zone
	return null


func _position_exit_zone(exit_zone, room: Node2D, direction: StringName) -> void:
	var room_bounds: Rect2 = _get_room_bounds(room)
	var half_zone_size: Vector2 = exit_zone.zone_size * 0.5

	match direction:
		&"right":
			exit_zone.position = Vector2(room_bounds.position.x + room_bounds.size.x - half_zone_size.x, 0.0)
		&"left":
			exit_zone.position = Vector2(room_bounds.position.x + half_zone_size.x, 0.0)
		&"down":
			exit_zone.position = Vector2(0.0, room_bounds.position.y + room_bounds.size.y - half_zone_size.y)
		&"up":
			exit_zone.position = Vector2(0.0, room_bounds.position.y + half_zone_size.y)


func _get_room_bounds(room: Node2D) -> Rect2:
	if room.has_method("get_room_bounds"):
		return room.get_room_bounds()
	return Rect2(Vector2(-80, -55), Vector2(160, 110))


func _clamp_local_position_to_room(local_position: Vector2, room_bounds: Rect2) -> Vector2:
	var clamped_position: Vector2 = local_position
	clamped_position.x = clamp(clamped_position.x, room_bounds.position.x, room_bounds.position.x + room_bounds.size.x)
	clamped_position.y = clamp(clamped_position.y, room_bounds.position.y, room_bounds.position.y + room_bounds.size.y)
	return clamped_position


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
	var exit_labels: PackedStringArray = PackedStringArray()
	var exit_zones: Array = _get_room_exit_zones(current_room)
	for exit_zone_variant in exit_zones:
		var exit_zone = exit_zone_variant
		if not is_instance_valid(exit_zone):
			continue

		var active_marker: String = "*" if exit_zone.contains_local_point(local_position - exit_zone.position) else "-"
		exit_labels.append("%s%s->%s" % [active_marker, exit_zone.exit_direction, exit_zone.target_room_id])

	var exit_text: String = "none"
	if not exit_labels.is_empty():
		exit_text = exit_labels[0]
		for index in range(1, exit_labels.size()):
			exit_text += ", " + exit_labels[index]

	_debug_label.text = "Room: %s\nLocal: (%.1f, %.1f)\nExits: %s" % [_current_room_id, local_position.x, local_position.y, exit_text]
