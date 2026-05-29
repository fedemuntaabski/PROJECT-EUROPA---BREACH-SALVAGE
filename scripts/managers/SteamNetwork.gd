extends Node

# Señales para que la UI se entere de cambios
signal player_list_changed
signal role_updated(steam_id, role_name)

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
		# Conectar señales nativas de Steam a nuestras funciones
		Steam.lobby_created.connect(_on_lobby_created)
		Steam.lobby_joined.connect(_on_lobby_joined)
		Steam.lobby_chat_update.connect(_on_lobby_chat_update)
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

# Se dispara cuando alguien entra, sale o es expulsado
func _on_lobby_chat_update(_this_lobby_id: int, _changed_id: int, _making_change_id: int, _chat_state: int) -> void:
	player_list_changed.emit()

# Se dispara cuando alguien cambia su "Metadata" (como su Rol)
func _on_lobby_data_update(_success: int, this_lobby_id: int, member_id: int, key: String) -> void:
	# Verificamos que sea el lobby correcto y la clave correcta
	if this_lobby_id == lobby_id and key == "role":
		var new_role = Steam.getLobbyMemberData(lobby_id, member_id, "role")
		role_updated.emit(member_id, new_role)