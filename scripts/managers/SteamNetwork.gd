extends Node

var is_steam_running: bool = false
var lobby_id: int = 0
var is_host: bool = false

func _ready() -> void:
	_initialize_steam()

func _process(_delta: float) -> void:
	if is_steam_running:
		Steam.run_callbacks() # Mantiene a Godot sincronizado con Steam

func _initialize_steam() -> void:
	# Inicializamos la API de Steam
	var init_response: Dictionary = Steam.steamInitEx(false)
	
	# Revisamos si el estado es 0 (Éxito)
	if init_response.has("status") and init_response["status"] == 0:
		is_steam_running = true
		print("¡Steam inicializado correctamente! Usuario: ", Steam.getPersonaName())
		
		# Conectar señales de salas
		Steam.lobby_created.connect(_on_lobby_created)
		Steam.lobby_match_list.connect(_on_lobby_match_list)
	else:
		# Extraemos el motivo usando la clave 'verbal' que expone tu plugin
		var motivo = init_response.get("verbal", "Motivo desconocido")
		var estado = init_response.get("status", "No definido")
		
		print("Error al inicializar Steam.")
		print("Estado devuelto: ", estado)
		print("Motivo: ", motivo)
        
# Función para que el Host cree una sala
func create_mission_lobby() -> void:
	if is_steam_running:
		is_host = true
		# 4 es el máximo de jugadores, LOBBY_TYPE_PUBLIC para que aparezca en el buscador
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 4)

func _on_lobby_created(connect_status: int, this_lobby_id: int) -> void:
	if connect_status == 1:
		lobby_id = this_lobby_id
		print("Sala creada con éxito. ID de Sala: ", lobby_id)
		
		# Seteamos datos de la sala para que otros puedan filtrarla en el buscador
		Steam.setLobbyData(lobby_id, "game_mode", "project_europa")
		Steam.setLobbyData(lobby_id, "name", str(Steam.getPersonaName(), "'s Expedition"))

# ESTA ES LA FUNCIÓN QUE FALTABA:
# Se dispara cuando Steam te devuelve la lista de salas públicas disponibles
func _on_lobby_match_list(lobbies: Array) -> void:
	print("Salas encontradas en Steam: ", lobbies)
