extends Control

var player_list_vbox: VBoxContainer
var role_selector: OptionButton
var start_button: Button

func _ready():
	# 1. Configuración de la Ventana Principal
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	# 2. Fondo Oscuro Profundo (ColorRect)
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.07, 0.1) # Azul casi negro
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 3. Contenedor Central
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var main_vbox = VBoxContainer.new()
	main_vbox.custom_minimum_size = Vector2(400, 0)
	main_vbox.add_theme_constant_override("separation", 20)
	center.add_child(main_vbox)

	# 4. Título de la Misión
	var title = Label.new()
	title.text = "MISSION PREPARATION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	main_vbox.add_child(title)

	# 5. Lista de Jugadores (Tripulación)
	var list_panel = PanelContainer.new()
	main_vbox.add_child(list_panel)
	
	player_list_vbox = VBoxContainer.new()
	player_list_vbox.add_theme_constant_override("separation", 10)
	list_panel.add_child(player_list_vbox)
	
	# 6. Selector de Roles
	var role_label = Label.new()
	role_label.text = "SELECT YOUR ROLE:"
	main_vbox.add_child(role_label)

	role_selector = OptionButton.new()
	role_selector.add_item("Operator")
	role_selector.add_item("Technical")
	role_selector.add_item("Custodian")
	role_selector.item_selected.connect(_on_role_selected)
	main_vbox.add_child(role_selector)

	# 7. Botón de Inicio (Solo para el Host)
	start_button = Button.new()
	start_button.text = "INITIATE DESCENT"
	
	# Habilitamos el botón si eres el Host
	if SteamNetwork.is_host:
		start_button.visible = true
		start_button.disabled = false # Lo dejamos activo para pruebas iniciales
	else:
		start_button.visible = false
	
	start_button.pressed.connect(_on_start_pressed)
	main_vbox.add_child(start_button)

	# CORRECCIÓN DE ARQUITECTURA: 
	# Conectamos la interfaz a las señales custom de tu SteamNetwork
	SteamNetwork.player_list_changed.connect(_update_player_list)
	SteamNetwork.role_updated.connect(_on_remote_role_updated)

	# Llenar lista inicial al entrar
	_update_player_list()

func _update_player_list():
	# Limpiar lista actual en la UI
	for child in player_list_vbox.get_children():
		child.queue_free()
	
	if not SteamNetwork.is_steam_running or SteamNetwork.lobby_id == 0:
		return
		
	# Obtener miembros del lobby desde Steam
	var members_count = Steam.getNumLobbyMembers(SteamNetwork.lobby_id)
	
	for i in range(members_count):
		var steam_id = Steam.getLobbyMemberByIndex(SteamNetwork.lobby_id, i)
		
		# SOLUCIÓN AL ERROR: Usamos getFriendPersonaName para IDs externos
		var player_name = Steam.getFriendPersonaName(steam_id)
		
		# Conseguimos el rol que guardó este jugador en los metadatos de la sala
		var player_role = Steam.getLobbyMemberData(SteamNetwork.lobby_id, steam_id, "role")
		if player_role == "":
			player_role = "Selecting..." # Rol por defecto si no eligió aún

		var label = Label.new()
		label.text = "[ " + player_name + " ] - " + player_role
		
		if steam_id == Steam.getLobbyOwner(SteamNetwork.lobby_id):
			label.text += " (HOST)"
		
		player_list_vbox.add_child(label)

func _on_role_selected(index):
	var role_name = role_selector.get_item_text(index)
	print("Has seleccionado localmente el rol: ", role_name)
	
	# Guardamos el rol en Steam para que se sincronice con el resto
	if SteamNetwork.is_steam_running and SteamNetwork.lobby_id != 0:
		Steam.setLobbyMemberData(SteamNetwork.lobby_id, "role", role_name)
		# Forzamos actualización local inmediata de la lista
		_update_player_list()

func _on_remote_role_updated(_steam_id, _role_name):
	# Cuando tu SteamNetwork avisa que alguien cambió de rol, redibujamos la lista
	_update_player_list()

func _on_start_pressed():
	print("Iniciando secuencia de descenso...")
