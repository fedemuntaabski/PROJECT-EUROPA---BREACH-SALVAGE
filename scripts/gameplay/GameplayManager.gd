extends Node2D


const ROLE_SCENE_PATHS := {
	"electrical_engineer": "res://scenes/player/roles/ElectricalEngineer.tscn",
	"mechanic_welder": "res://scenes/player/roles/Mechanic.tscn",
	"security_officer": "res://scenes/player/roles/Security.tscn",
	"medic_scientist": "res://scenes/player/roles/Medic.tscn",
}

const FALLBACK_CHARACTER_SCENE_PATH := "res://scenes/player/Character.tscn"

const CREW_SPAWN_POINTS := [
	Vector2(-96.0, 0.0),
	Vector2(-32.0, 0.0),
	Vector2(32.0, 0.0),
	Vector2(96.0, 0.0),
]

@onready var crew_root: Node2D = $CrewRoot
@onready var spawn_anchor: Node2D = $SpawnAnchor


func _ready() -> void:
	var world_seed := SteamNetwork.get_cached_world_seed()
	if world_seed >= 0:
		seed(world_seed)
	else:
		randomize()

	_spawn_crew()


func _spawn_crew() -> void:
	if SteamNetwork.lobby_id == 0:
		push_warning("GameplayManager cannot spawn crew without an active lobby.")
		return

	if not is_instance_valid(crew_root):
		push_error("GameplayManager requires a valid CrewRoot node.")
		return

	for child in crew_root.get_children():
		child.queue_free()

	var members_count := Steam.getNumLobbyMembers(SteamNetwork.lobby_id)
	for index in range(members_count):
		var steam_id := Steam.getLobbyMemberByIndex(SteamNetwork.lobby_id, index)
		if steam_id <= 0:
			continue

		var role_id := SteamNetwork.get_player_role_for_peer(steam_id)
		var crew_scene := _resolve_role_scene(role_id)
		if crew_scene == null:
			push_warning("No crew scene could be resolved for role '%s'; skipping peer %s." % [role_id, str(steam_id)])
			continue

		var crew := crew_scene.instantiate()
		if crew == null:
			push_warning("Failed to instance crew scene for peer %s." % str(steam_id))
			continue

		crew.name = "%s_%s" % [role_id if not role_id.is_empty() else "crew", str(steam_id)]
		crew_root.add_child(crew)
		crew.set_multiplayer_authority(steam_id)
		if crew is Node2D:
			(crew as Node2D).global_position = _get_spawn_position(index)
		crew.set_meta("steam_id", steam_id)
		crew.set_meta("role_id", role_id)


func _resolve_role_scene(role_id: String) -> PackedScene:
	var scene_path := String(ROLE_SCENE_PATHS.get(role_id, FALLBACK_CHARACTER_SCENE_PATH))
	var scene := load(scene_path)
	if scene is PackedScene:
		return scene

	var fallback_scene := load(FALLBACK_CHARACTER_SCENE_PATH)
	if fallback_scene is PackedScene:
		return fallback_scene

	return null


func _get_spawn_position(index: int) -> Vector2:
	var base_position := Vector2.ZERO
	if is_instance_valid(spawn_anchor):
		base_position = spawn_anchor.global_position

	var point_index := index % CREW_SPAWN_POINTS.size()
	var row_offset := int(index / CREW_SPAWN_POINTS.size()) * 28
	var offset = CREW_SPAWN_POINTS[point_index] + Vector2(0.0, float(row_offset))
	return base_position + offset