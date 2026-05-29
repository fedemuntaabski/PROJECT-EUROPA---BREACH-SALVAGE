extends Node

signal player_list_changed
signal role_updated(steam_id, role_name)
signal ready_updated(steam_id, is_ready)
signal lobby_state_changed(state)
signal lobby_browser_updated(lobbies)

const ROLE_DATA_KEY := "member_role"
const LEGACY_ROLE_DATA_KEY := "role"
const READY_DATA_KEY := "member_ready"
const MATCH_STATE_KEY := "lobby_state"
const WORLD_SEED_KEY := "world_seed"
const LOBBY_VERSION_KEY := "lobby_version"
const HOST_STEAM_ID_KEY := "host_steam_id"

const LOBBY_STATE_WAITING_FOR_PLAYERS := "WAITING_FOR_PLAYERS"
const LOBBY_STATE_ROLE_SELECTION := "ROLE_SELECTION"
const LOBBY_STATE_READY_CHECK := "READY_CHECK"
const LOBBY_STATE_DESCENT_LOADING := "DESCENT_LOADING"
const LOBBY_STATE_CINEMATIC := "CINEMATIC"
const LOBBY_STATE_PUBLISHING_SEED := "PUBLISHING_SEED"
const LOBBY_STATE_WAITING_FOR_WORLD_ACKS := "WAITING_FOR_WORLD_ACKS"
const LOBBY_STATE_LOADING_GAMEPLAY := "LOADING_GAMEPLAY"
const LOBBY_STATE_IN_GAME := "IN_GAME"

const DESCENT_SCENE_PATH := "res://scenes/ui/Descenso.tscn"
const GAMEPLAY_SCENE_PATH := "res://scenes/gameplay/MainGameplay.tscn"
const LOBBY_SCENE_PATH := "res://scenes/ui/lobby/LobbyScene.tscn"
const DEFAULT_LOBBY_VERSION := "0.1.0"

var is_steam_running: bool = false
var lobby_id: int = 0
var is_host: bool = false
var local_steam_id: int = 0
var available_lobbies: Array[Dictionary] = []
var lobby_state: String = LOBBY_STATE_WAITING_FOR_PLAYERS

func _ready() -> void:
	_initialize_steam()

func _process(_delta: float) -> void:
	if is_steam_running:
		Steam.run_callbacks()

func _initialize_steam() -> void:
	var init_response: Dictionary = Steam.steamInitEx(false)
	if init_response.has("status") and init_response["status"] == 0:
		is_steam_running = true
		local_steam_id = int(Steam.getSteamID()) if Steam.has_method("getSteamID") else 0
		_connect_steam_signal("lobby_created", _on_lobby_created)
		_connect_steam_signal("lobby_joined", _on_lobby_joined)
		_connect_steam_signal("lobby_chat_update", _on_lobby_chat_update)
		_connect_steam_signal("lobby_data_update", _on_lobby_data_update)
		_connect_steam_signal("lobby_match_list", _on_lobby_match_list)
		print("¡Steam inicializado en el Manager Global!")

	else:
		print("Error Steam: ", init_response.get("verbal", "Error desconocido"))

func create_mission_lobby() -> void:
	create_expedition_lobby()

func create_expedition_lobby() -> void:
	if is_steam_running:
		is_host = true
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 4)

func join_expedition_lobby(target_lobby_id: int) -> void:
	if not is_steam_running or target_lobby_id <= 0:
		return

	Steam.joinLobby(target_lobby_id)

func request_lobby_browser() -> void:
	available_lobbies.clear()
	if not is_steam_running:
		lobby_browser_updated.emit(available_lobbies)
		return

	if Steam.has_method("requestLobbyList"):
		Steam.requestLobbyList()
	else:
		push_warning("Steam lobby browser is not available in this build.")
		lobby_browser_updated.emit(available_lobbies)

func leave_current_lobby(redirect_to_menu: bool = true) -> void:
	if lobby_id != 0 and is_steam_running and Steam.has_method("leaveLobby"):
		Steam.leaveLobby(lobby_id)

	_reset_lobby_state()
	if redirect_to_menu:
		SceneManager.change_scene("res://scenes/ui/MainMenu.tscn")

func set_local_role(role_id: String) -> bool:
	if lobby_id == 0 or role_id.is_empty():
		return false

	if not is_role_available(role_id, local_steam_id):
		var current_role := get_player_role_for_peer(local_steam_id)
		if current_role != role_id:
			return false

	Steam.setLobbyMemberData(lobby_id, ROLE_DATA_KEY, role_id)
	Steam.setLobbyMemberData(lobby_id, READY_DATA_KEY, "false")
	player_list_changed.emit()
	role_updated.emit(local_steam_id, role_id)
	ready_updated.emit(local_steam_id, false)
	_refresh_progress_state()
	return true

func set_local_ready(is_ready: bool) -> void:
	if lobby_id == 0:
		return

	Steam.setLobbyMemberData(lobby_id, READY_DATA_KEY, "true" if is_ready else "false")
	player_list_changed.emit()
	ready_updated.emit(local_steam_id, is_ready)
	_refresh_progress_state()

func toggle_local_ready() -> bool:
	var next_ready := not get_player_ready_for_peer(local_steam_id)
	set_local_ready(next_ready)
	return next_ready

func begin_expedition_launch() -> bool:
	if not can_host_launch():
		return false

	set_lobby_state(LOBBY_STATE_DESCENT_LOADING)
	set_lobby_state(LOBBY_STATE_CINEMATIC)
	SceneManager.change_scene(DESCENT_SCENE_PATH)
	return true

func publish_world_seed(world_seed: int) -> void:
	if not is_host or lobby_id == 0:
		return

	set_lobby_state(LOBBY_STATE_PUBLISHING_SEED)
	Steam.setLobbyData(lobby_id, WORLD_SEED_KEY, str(world_seed))
	set_lobby_state(LOBBY_STATE_WAITING_FOR_WORLD_ACKS)

func mark_in_game() -> void:
	if not is_host:
		return

	set_lobby_state(LOBBY_STATE_IN_GAME)

func set_lobby_state(state: String) -> void:
	if not is_host or lobby_id == 0:
		return

	lobby_state = state
	Steam.setLobbyData(lobby_id, MATCH_STATE_KEY, state)
	lobby_state_changed.emit(state)

func can_host_launch() -> bool:
	if not is_host or lobby_id == 0:
		return false

	var member_ids := get_sorted_lobby_member_ids()
	if member_ids.is_empty():
		return false

	for steam_id in member_ids:
		if get_player_role_for_peer(steam_id).is_empty():
			return false
		if not get_player_ready_for_peer(steam_id):
			return false

	return true

func get_lobby_state() -> String:
	if lobby_id == 0:
		return lobby_state

	var state := String(Steam.getLobbyData(lobby_id, MATCH_STATE_KEY))
	if state.is_empty():
		return lobby_state

	return state

func get_sorted_lobby_member_ids() -> Array[int]:
	var member_ids: Array[int] = []
	if lobby_id == 0 or not is_steam_running:
		return member_ids

	var members_count := Steam.getNumLobbyMembers(lobby_id)
	for index in range(members_count):
		var steam_id := int(Steam.getLobbyMemberByIndex(lobby_id, index))
		if steam_id > 0:
			member_ids.append(steam_id)

	member_ids.sort_custom(func(a: int, b: int) -> bool:
		return a < b
	)
	return member_ids

func get_lobby_roster() -> Array[Dictionary]:
	var roster: Array[Dictionary] = []
	for steam_id in get_sorted_lobby_member_ids():
		roster.append(_build_member_summary(steam_id))

	return roster

func get_player_role_for_peer(steam_id: int) -> String:
	if lobby_id == 0 or steam_id <= 0:
		return ""

	var role_value := String(Steam.getLobbyMemberData(lobby_id, steam_id, ROLE_DATA_KEY))
	if role_value.is_empty():
		role_value = String(Steam.getLobbyMemberData(lobby_id, steam_id, LEGACY_ROLE_DATA_KEY))

	return role_value

func get_player_ready_for_peer(steam_id: int) -> bool:
	if lobby_id == 0 or steam_id <= 0:
		return false

	var ready_value := String(Steam.getLobbyMemberData(lobby_id, steam_id, READY_DATA_KEY)).to_lower()
	return ready_value == "true" or ready_value == "1" or ready_value == "yes"

func get_role_occupant(role_id: String) -> int:
	if role_id.is_empty():
		return 0

	for steam_id in get_sorted_lobby_member_ids():
		if get_player_role_for_peer(steam_id) == role_id:
			return steam_id

	return 0

func is_role_available(role_id: String, ignoring_steam_id: int = 0) -> bool:
	if role_id.is_empty():
		return false

	for steam_id in get_sorted_lobby_member_ids():
		if steam_id == ignoring_steam_id:
			continue
		if get_player_role_for_peer(steam_id) == role_id:
			return false

	return true

func request_lobby_metadata_refresh() -> void:
	player_list_changed.emit()
	lobby_state_changed.emit(get_lobby_state())

func _on_lobby_created(connect_status: int, this_lobby_id: int) -> void:
	if connect_status == 1:
		lobby_id = this_lobby_id
		local_steam_id = int(Steam.getSteamID()) if Steam.has_method("getSteamID") else local_steam_id
		is_host = true
		lobby_state = LOBBY_STATE_ROLE_SELECTION
		_initialize_lobby_metadata()
		Steam.setLobbyMemberData(lobby_id, READY_DATA_KEY, "false")
		player_list_changed.emit()
		lobby_state_changed.emit(lobby_state)
		SceneManager.change_scene(LOBBY_SCENE_PATH)

func _initialize_lobby_metadata() -> void:
	Steam.setLobbyData(lobby_id, "game_mode", "project_europa")
	Steam.setLobbyData(lobby_id, "name", str(Steam.getPersonaName(), "'s Expedition"))
	Steam.setLobbyData(lobby_id, LOBBY_VERSION_KEY, DEFAULT_LOBBY_VERSION)
	Steam.setLobbyData(lobby_id, HOST_STEAM_ID_KEY, str(local_steam_id))
	Steam.setLobbyData(lobby_id, MATCH_STATE_KEY, lobby_state)

func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response == 1:
		lobby_id = this_lobby_id
		local_steam_id = int(Steam.getSteamID()) if Steam.has_method("getSteamID") else local_steam_id
		is_host = (Steam.getLobbyOwner(lobby_id) == Steam.getSteamID())
		lobby_state = get_lobby_state()
		print("Unido a la sala con éxito. ¿Es Host?: ", is_host)
		player_list_changed.emit()
		lobby_state_changed.emit(lobby_state)
		_sync_match_state_if_needed()

func _on_lobby_chat_update(_this_lobby_id: int, _changed_id: int, _making_change_id: int, _chat_state: int) -> void:
	player_list_changed.emit()

func _on_lobby_data_update(_success: int, this_lobby_id: int, member_id: int, key: String) -> void:
	if _success != 1 or this_lobby_id != lobby_id:
		return

	if key == ROLE_DATA_KEY or key == LEGACY_ROLE_DATA_KEY:
		var new_role := Steam.getLobbyMemberData(lobby_id, member_id, ROLE_DATA_KEY)
		role_updated.emit(member_id, new_role)
		player_list_changed.emit()
		_refresh_progress_state()
		return

	if key == READY_DATA_KEY:
		ready_updated.emit(member_id, get_player_ready_for_peer(member_id))
		player_list_changed.emit()
		_refresh_progress_state()
		return

	if key == MATCH_STATE_KEY:
		lobby_state = get_lobby_state()
		lobby_state_changed.emit(lobby_state)
		_sync_match_state_if_needed()
		return

	if key == WORLD_SEED_KEY:
		_handle_world_seed_update()

func _sync_match_state_if_needed() -> void:
	if lobby_id == 0:
		return

	if get_cached_world_seed() >= 0:
		_handle_world_seed_update()
		return

	var current_state := get_lobby_state()
	if current_state == LOBBY_STATE_DESCENT_LOADING or current_state == LOBBY_STATE_CINEMATIC or current_state == LOBBY_STATE_PUBLISHING_SEED or current_state == LOBBY_STATE_WAITING_FOR_WORLD_ACKS or current_state == LOBBY_STATE_LOADING_GAMEPLAY or current_state == LOBBY_STATE_IN_GAME:
		_handle_match_state_update()

func _refresh_progress_state() -> void:
	if not is_host or lobby_id == 0:
		return

	var current_state := get_lobby_state()
	if current_state == LOBBY_STATE_DESCENT_LOADING or current_state == LOBBY_STATE_CINEMATIC or current_state == LOBBY_STATE_PUBLISHING_SEED or current_state == LOBBY_STATE_WAITING_FOR_WORLD_ACKS or current_state == LOBBY_STATE_LOADING_GAMEPLAY or current_state == LOBBY_STATE_IN_GAME:
		return

	var all_roles_assigned := true
	for steam_id in get_sorted_lobby_member_ids():
		if get_player_role_for_peer(steam_id).is_empty():
			all_roles_assigned = false
			break

	if all_roles_assigned:
		set_lobby_state(LOBBY_STATE_READY_CHECK)
	elif current_state != LOBBY_STATE_ROLE_SELECTION:
		set_lobby_state(LOBBY_STATE_ROLE_SELECTION)

func _handle_match_state_update() -> void:
	if get_tree().current_scene != null and get_tree().current_scene.scene_file_path == GAMEPLAY_SCENE_PATH:
		return

	if get_tree().current_scene != null and get_tree().current_scene.scene_file_path == DESCENT_SCENE_PATH:
		return

	print("[SteamNetwork] lobby ", lobby_id, " state=", get_lobby_state(), "; transitioning to Descenso.tscn")
	SceneManager.change_scene(DESCENT_SCENE_PATH)

func _handle_world_seed_update() -> void:
	if lobby_id == 0 or is_host:
		return

	if get_tree().current_scene != null and get_tree().current_scene.scene_file_path == GAMEPLAY_SCENE_PATH:
		return

	if get_cached_world_seed() >= 0:
		print("[SteamNetwork] lobby ", lobby_id, " world_seed detected; transitioning to MainGameplay.tscn")
		lobby_state = LOBBY_STATE_LOADING_GAMEPLAY
		SceneManager.change_scene(GAMEPLAY_SCENE_PATH)

func get_cached_world_seed() -> int:
	if lobby_id == 0:
		return -1

	var raw_world_seed := String(Steam.getLobbyData(lobby_id, WORLD_SEED_KEY))
	if raw_world_seed.is_empty():
		return -1

	return int(raw_world_seed)

func _on_lobby_match_list(lobbies: Array) -> void:
	available_lobbies.clear()
	for raw_lobby_id in lobbies:
		var lobby_entry := _build_lobby_summary(int(raw_lobby_id))
		if not lobby_entry.is_empty():
			available_lobbies.append(lobby_entry)

	lobby_browser_updated.emit(available_lobbies)

func _build_lobby_summary(target_lobby_id: int) -> Dictionary:
	if target_lobby_id <= 0:
		return {}

	var member_count := Steam.getNumLobbyMembers(target_lobby_id)
	return {
		"lobby_id": target_lobby_id,
		"name": String(Steam.getLobbyData(target_lobby_id, "name")),
		"state": String(Steam.getLobbyData(target_lobby_id, MATCH_STATE_KEY)),
		"version": String(Steam.getLobbyData(target_lobby_id, LOBBY_VERSION_KEY)),
		"host_steam_id": String(Steam.getLobbyData(target_lobby_id, HOST_STEAM_ID_KEY)),
		"member_count": member_count,
		"max_members": 4,
	}

func _build_member_summary(steam_id: int) -> Dictionary:
	return {
		"steam_id": steam_id,
		"name": Steam.getFriendPersonaName(steam_id),
		"role_id": get_player_role_for_peer(steam_id),
		"ready": get_player_ready_for_peer(steam_id),
		"is_host": steam_id == Steam.getLobbyOwner(lobby_id),
	}

func _connect_steam_signal(signal_name: String, handler: Callable) -> void:
	if not Steam.has_signal(signal_name):
		return

	if not Steam.is_connected(signal_name, handler):
		Steam.connect(signal_name, handler)

func _reset_lobby_state() -> void:
	lobby_id = 0
	is_host = false
	lobby_state = LOBBY_STATE_WAITING_FOR_PLAYERS
	available_lobbies.clear()
	player_list_changed.emit()
	lobby_state_changed.emit(lobby_state)
	lobby_browser_updated.emit(available_lobbies)