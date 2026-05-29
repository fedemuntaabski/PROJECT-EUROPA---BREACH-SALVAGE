extends Control

const ROLE_DATA_KEY := "role"
const DESCENT_SCENE_PATH := "res://scenes/ui/Descenso.tscn"
const ROLE_DEFINITIONS := [
	{
		"id": "electrical_engineer",
		"label": "Ingeniero Electrónico",
		"summary": "Administra energía, distribución y optimización de módulos.",
	},
	{
		"id": "mechanic_welder",
		"label": "Mecánico / Soldador",
		"summary": "Ejecuta reparaciones, soldadura y contención de daños.",
	},
	{
		"id": "security_officer",
		"label": "Oficial de Seguridad",
		"summary": "Protege al equipo, controla amenazas y asegura el perímetro.",
	},
	{
		"id": "medic_scientist",
		"label": "Médico / Científico",
		"summary": "Sostiene la salud del equipo y apoya la investigación vital.",
	},
]

var ui_built: bool = false
var player_list_vbox: VBoxContainer
var start_button: Button
var _role_selector_node: OptionButton

@onready var role_selector: OptionButton = _ensure_role_selector()

func _ready() -> void:
	_populate_roles()
	_sync_initial_role_selection()
	_update_start_button_state()

	if not SteamNetwork.player_list_changed.is_connected(_update_player_list):
		SteamNetwork.player_list_changed.connect(_update_player_list)
	if not SteamNetwork.role_updated.is_connected(_on_remote_role_updated):
		SteamNetwork.role_updated.connect(_on_remote_role_updated)

	_update_player_list()

func _ensure_role_selector() -> OptionButton:
	if ui_built and is_instance_valid(_role_selector_node):
		return _role_selector_node

	_build_ui()
	return _role_selector_node

func _build_ui() -> void:
	if ui_built:
		return

	anchor_right = 1.0
	anchor_bottom = 1.0

	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.07, 0.1)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var main_vbox := VBoxContainer.new()
	main_vbox.custom_minimum_size = Vector2(400, 0)
	main_vbox.add_theme_constant_override("separation", 20)
	center.add_child(main_vbox)

	var title := Label.new()
	title.text = "MISSION PREPARATION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	main_vbox.add_child(title)

	var list_panel := PanelContainer.new()
	main_vbox.add_child(list_panel)

	player_list_vbox = VBoxContainer.new()
	player_list_vbox.add_theme_constant_override("separation", 10)
	list_panel.add_child(player_list_vbox)

	var role_label := Label.new()
	role_label.text = "SELECT YOUR ROLE:"
	main_vbox.add_child(role_label)

	_role_selector_node = OptionButton.new()
	_role_selector_node.name = "RoleSelector"
	_role_selector_node.item_selected.connect(_on_role_selected)
	main_vbox.add_child(_role_selector_node)

	start_button = Button.new()
	start_button.name = "StartButton"
	start_button.text = "Iniciar Descenso"
	start_button.pressed.connect(_on_start_pressed)
	main_vbox.add_child(start_button)

	ui_built = true

func _populate_roles() -> void:
	role_selector.clear()

	for role_data in ROLE_DEFINITIONS:
		role_selector.add_item(role_data["label"])
		role_selector.set_item_metadata(role_selector.get_item_count() - 1, role_data)

func _sync_initial_role_selection() -> void:
	if role_selector.get_item_count() == 0:
		return

	role_selector.select(0)

	if SteamNetwork.is_steam_running and SteamNetwork.lobby_id != 0:
		_on_role_selected(0)

func _update_start_button_state() -> void:
	if not is_instance_valid(start_button):
		return

	start_button.visible = SteamNetwork.is_host
	start_button.disabled = not SteamNetwork.is_host

func _update_player_list() -> void:
	if not is_instance_valid(player_list_vbox):
		return

	for child in player_list_vbox.get_children():
		child.queue_free()

	if not SteamNetwork.is_steam_running or SteamNetwork.lobby_id == 0:
		return

	var members_count := Steam.getNumLobbyMembers(SteamNetwork.lobby_id)
	for i in range(members_count):
		var steam_id := Steam.getLobbyMemberByIndex(SteamNetwork.lobby_id, i)
		var player_name := Steam.getFriendPersonaName(steam_id)
		var player_role_value := Steam.getLobbyMemberData(SteamNetwork.lobby_id, steam_id, ROLE_DATA_KEY)
		var player_role_label := _resolve_role_label(player_role_value)

		if player_role_label.is_empty():
			player_role_label = "Seleccionando..."

		var label := Label.new()
		label.text = "[ " + player_name + " ] - " + player_role_label
		if steam_id == Steam.getLobbyOwner(SteamNetwork.lobby_id):
			label.text += " (HOST)"

		player_list_vbox.add_child(label)

func _on_role_selected(index: int) -> void:
	var role_data := _get_role_definition(index)
	if role_data.is_empty():
		return

	if not SteamNetwork.is_steam_running or SteamNetwork.lobby_id == 0:
		return

	var role_id := String(role_data.get("id", ""))
	if role_id.is_empty():
		return

	Steam.setLobbyMemberData(SteamNetwork.lobby_id, ROLE_DATA_KEY, role_id)
	_update_player_list()

func _on_remote_role_updated(_steam_id: int, _role_value: String) -> void:
	_update_player_list()

func _on_start_pressed() -> void:
	if not SteamNetwork.is_host:
		push_warning("Only the host can start the descent.")
		return

	if not SteamNetwork.is_steam_running:
		push_warning("Steam is not initialized.")
		return

	if SteamNetwork.lobby_id == 0:
		push_warning("No active lobby to start.")
		return

	Steam.setLobbyData(SteamNetwork.lobby_id, "match_state", "descending")
	SceneManager.change_scene(DESCENT_SCENE_PATH)

func _get_role_definition(index: int) -> Dictionary:
	if index < 0 or index >= role_selector.get_item_count():
		return {}

	var role_data = role_selector.get_item_metadata(index)
	if role_data is Dictionary:
		return role_data

	return {}

func _resolve_role_label(role_value: String) -> String:
	if role_value.is_empty():
		return ""

	for role_data in ROLE_DEFINITIONS:
		if role_value == role_data["id"] or role_value == role_data["label"]:
			return role_data["label"]

	return role_value
