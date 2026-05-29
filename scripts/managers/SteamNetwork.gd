extends Node

# Señales para que la UI se entere de cambios
signal player_list_changed
signal role_updated(steam_id, role_name)

const ROLE_DATA_KEY := "role"
const MATCH_STATE_KEY := "match_state"
const MATCH_STATE_DESCENDING := "descending"
const DESCENT_SCENE_PATH := "res://scenes/ui/Descenso.tscn"
const GAMEPLAY_SCENE_PATH := "res://scenes/gameplay/MainGameplay.tscn"

var is_steam_running: bool = false
var lobby_id: int = 0
var is_host: bool = false

func _ready() -> void:
	_initialize_steam()

func _process(_delta: float) -> void:
	if is_steam_running:
		Steam.run_callbacks()

func _initialize_steam() -> void:
	var init_response: Dictionary = Steam.steamInitEx(false)
	if init_response.has("status") and init_response["status"] == 0:
		is_steam_running = true
		if not Steam.lobby_created.is_connected(_on_lobby_created):
			Steam.lobby_created.connect(_on_lobby_created)
		if not Steam.lobby_joined.is_connected(_on_lobby_joined):
			Steam.lobby_joined.connect(_on_lobby_joined)
		if not Steam.lobby_chat_update.is_connected(_on_lobby_chat_update):
			Steam.lobby_chat_update.connect(_on_lobby_chat_update)
		if not Steam.lobby_data_update.is_connected(_on_lobby_data_update):
			Steam.lobby_data_update.connect(_on_lobby_data_update)
		print("¡Steam inicializado en el Manager Global!")

	else:
		# Corregido de forma segura usando la clave 'verbal' que expuso tu debug
		print("Error Steam: ", init_response.get("verbal", "Error desconocido"))

func create_mission_lobby() -> void:
	if is_steam_running:
		is_host = true
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 4)

func _on_lobby_created(connect_status: int, this_lobby_id: int) -> void:
	if connect_status == 1:
		lobby_id = this_lobby_id
		Steam.setLobbyData(lobby_id, "game_mode", "project_europa")
		Steam.setLobbyData(lobby_id, "name", str(Steam.getPersonaName(), "'s Expedition"))
		# Cambiamos a la escena del lobby
		SceneManager.change_scene("res://scenes/ui/Lobby.tscn")

# Se dispara cuando ALGUIEN (tú u otro) entra a la sala
func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response == 1:
		lobby_id = this_lobby_id
		is_host = (Steam.getLobbyOwner(lobby_id) == Steam.getSteamID()) # Si eres el dueño, te marca como host
		print("Unido a la sala con éxito. ¿Es Host?: ", is_host)
		player_list_changed.emit()
		_sync_match_state_if_needed()

# Se dispara cuando alguien entra, sale o es expulsado
func _on_lobby_chat_update(_this_lobby_id: int, _changed_id: int, _making_change_id: int, _chat_state: int) -> void:
	player_list_changed.emit()

# Se dispara cuando alguien cambia su "Metadata" (como su Rol)
func _on_lobby_data_update(_success: int, this_lobby_id: int, member_id: int, key: String) -> void:
	if _success != 1 or this_lobby_id != lobby_id:
		return

	if key == ROLE_DATA_KEY:
		var new_role := Steam.getLobbyMemberData(lobby_id, member_id, ROLE_DATA_KEY)
		role_updated.emit(member_id, new_role)
		return

	if key == MATCH_STATE_KEY:
		_sync_match_state_if_needed()
		return

	if key == "world_seed":
		_handle_world_seed_update()

func _sync_match_state_if_needed() -> void:
	if lobby_id == 0:
		return

	if get_cached_world_seed() >= 0:
		_handle_world_seed_update()
		return

	if Steam.getLobbyData(lobby_id, MATCH_STATE_KEY) == MATCH_STATE_DESCENDING:
		_handle_match_state_update()

func _handle_match_state_update() -> void:
	if get_tree().current_scene != null and get_tree().current_scene.scene_file_path == GAMEPLAY_SCENE_PATH:
		return

	if Steam.getLobbyData(lobby_id, MATCH_STATE_KEY) == MATCH_STATE_DESCENDING:
		print("[SteamNetwork] lobby ", lobby_id, " match_state=descending; transitioning to Descenso.tscn")
		SceneManager.change_scene(DESCENT_SCENE_PATH)

func _handle_world_seed_update() -> void:
	if lobby_id == 0 or is_host:
		return

	if get_tree().current_scene != null and get_tree().current_scene.scene_file_path == GAMEPLAY_SCENE_PATH:
		return

	if get_cached_world_seed() >= 0:
		print("[SteamNetwork] lobby ", lobby_id, " world_seed detected; transitioning to MainGameplay.tscn")
		SceneManager.change_scene(GAMEPLAY_SCENE_PATH)

func get_cached_world_seed() -> int:
	if lobby_id == 0:
		return -1

	var raw_world_seed := String(Steam.getLobbyData(lobby_id, "world_seed"))
	if raw_world_seed.is_empty():
		return -1

	return int(raw_world_seed)

func get_player_role_for_peer(steam_id: int) -> String:
	if lobby_id == 0 or steam_id <= 0:
		return ""

	return String(Steam.getLobbyMemberData(lobby_id, steam_id, ROLE_DATA_KEY))