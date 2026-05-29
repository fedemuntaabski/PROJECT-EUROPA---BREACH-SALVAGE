extends Control

const ROLE_CARD_SCENE := preload("res://scenes/ui/lobby/RoleCard.tscn")

var _role_cards: Dictionary = {}
var _role_resources: Array[CharacterClassResource] = []
var _local_steam_id: int = 0

@onready var _title_label: Label = $MarginContainer/MainVBox/HeaderContainer/TitleStack/TitleLabel
@onready var _subtitle_label: Label = $MarginContainer/MainVBox/HeaderContainer/TitleStack/SubtitleLabel
@onready var _version_label: Label = $MarginContainer/MainVBox/HeaderContainer/VersionLabel
@onready var _lobby_info_label: Label = $MarginContainer/MainVBox/LobbyInfoPanel/LobbyInfoLabel
@onready var _player_list_vbox: VBoxContainer = $MarginContainer/MainVBox/ContentContainer/PlayerListPanel/PlayerListVBox
@onready var _role_cards_grid: GridContainer = $MarginContainer/MainVBox/ContentContainer/RoleSelectionPanel/ScrollContainer/RoleCardsGrid
@onready var _ready_status_label: Label = $MarginContainer/MainVBox/ContentContainer/StatusColumn/ReadyPanel/ReadyVBox/ReadyStatusLabel
@onready var _ready_button: Button = $MarginContainer/MainVBox/ContentContainer/StatusColumn/ReadyPanel/ReadyVBox/ReadyButton
@onready var _chat_placeholder_label: Label = $MarginContainer/MainVBox/ContentContainer/StatusColumn/ChatPanel/ChatPlaceholderLabel
@onready var _launch_button: Button = $MarginContainer/MainVBox/FooterContainer/LaunchButton
@onready var _back_button: Button = $MarginContainer/MainVBox/FooterContainer/BackButton


func _ready() -> void:
	_local_steam_id = int(Steam.getSteamID()) if SteamNetwork.is_steam_running and Steam.has_method("getSteamID") else 0
	_connect_signals()
	_load_role_cards()
	_update_scene_labels()
	_refresh_ui()
	if SteamNetwork.lobby_id != 0:
		SteamNetwork.request_lobby_metadata_refresh()


func _connect_signals() -> void:
	if not SteamNetwork.player_list_changed.is_connected(_refresh_ui):
		SteamNetwork.player_list_changed.connect(_refresh_ui)
	if not SteamNetwork.role_updated.is_connected(_on_remote_role_updated):
		SteamNetwork.role_updated.connect(_on_remote_role_updated)
	if not SteamNetwork.ready_updated.is_connected(_on_remote_ready_updated):
		SteamNetwork.ready_updated.connect(_on_remote_ready_updated)
	if not SteamNetwork.lobby_state_changed.is_connected(_on_lobby_state_changed):
		SteamNetwork.lobby_state_changed.connect(_on_lobby_state_changed)
	if not _ready_button.pressed.is_connected(_on_ready_button_pressed):
		_ready_button.pressed.connect(_on_ready_button_pressed)
	if not _launch_button.pressed.is_connected(_on_launch_button_pressed):
		_launch_button.pressed.connect(_on_launch_button_pressed)
	if not _back_button.pressed.is_connected(_on_back_button_pressed):
		_back_button.pressed.connect(_on_back_button_pressed)


func _load_role_cards() -> void:
	_role_resources = CharacterRoleLibrary.load_roles()
	for child in _role_cards_grid.get_children():
		child.queue_free()

	_role_cards.clear()
	for role_resource in _role_resources:
		var role_card := ROLE_CARD_SCENE.instantiate()
		_role_cards_grid.add_child(role_card)
		role_card.populate_from_resource(role_resource)
		role_card.role_selected.connect(_on_role_selected)
		_role_cards[role_resource.role_id] = role_card


func _update_scene_labels() -> void:
	_title_label.text = "EXPEDITION LOBBY"
	_subtitle_label.text = "SPECIALIST ASSIGNMENT / READY CHECK / STEEL HULL PROTOCOL"
	_version_label.text = "BUILD %s" % SteamNetwork.DEFAULT_LOBBY_VERSION if SteamNetwork.DEFAULT_LOBBY_VERSION != "" else "BUILD"
	_chat_placeholder_label.text = "CHAT / COMMS CHANNEL: PLACEHOLDER"


func _refresh_ui() -> void:
	if SteamNetwork.lobby_id == 0:
		_lobby_info_label.text = "No active expedition."
		_ready_status_label.text = "Awaiting lobby connection."
		_launch_button.disabled = true
		_ready_button.disabled = true
		return

	var lobby_state := SteamNetwork.get_lobby_state()
	_lobby_info_label.text = "Lobby %s | State: %s | Members: %d | Host: %s" % [
		str(SteamNetwork.lobby_id),
		lobby_state,
		SteamNetwork.get_sorted_lobby_member_ids().size(),
		str(Steam.getLobbyOwner(SteamNetwork.lobby_id))
	]

	_update_player_list()
	_update_role_card_states()
	_update_ready_panel()
	_launch_button.visible = SteamNetwork.is_host
	_launch_button.disabled = not SteamNetwork.can_host_launch()


func _update_player_list() -> void:
	for child in _player_list_vbox.get_children():
		child.queue_free()

	if SteamNetwork.lobby_id == 0:
		return

	var roster := SteamNetwork.get_lobby_roster()
	for index in range(roster.size()):
		var entry: Dictionary = roster[index]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var order_label := Label.new()
		order_label.text = "%02d" % (index + 1)
		row.add_child(order_label)

		var name_label := Label.new()
		var name_text := String(entry.get("name", "Unknown Crew"))
		if bool(entry.get("is_host", false)):
			name_text += " [HOST]"
		name_label.text = name_text
		row.add_child(name_label)

		var role_label := Label.new()
		var role_id := String(entry.get("role_id", ""))
		role_label.text = _resolve_role_display_name(role_id)
		row.add_child(role_label)

		var ready_label := Label.new()
		ready_label.text = "READY" if bool(entry.get("ready", false)) else "NOT READY"
		row.add_child(ready_label)

		_player_list_vbox.add_child(row)


func _update_role_card_states() -> void:
	var local_role_id := SteamNetwork.get_player_role_for_peer(_local_steam_id)
	var local_ready := SteamNetwork.get_player_ready_for_peer(_local_steam_id)

	for role_resource in _role_resources:
		var role_card: Control = _role_cards.get(role_resource.role_id, null)
		if role_card == null:
			continue

		var occupant_id := SteamNetwork.get_role_occupant(role_resource.role_id)
		var occupant_name := String(Steam.getFriendPersonaName(occupant_id)) if occupant_id > 0 else ""
		var occupied_by_other := occupant_id > 0 and occupant_id != _local_steam_id
		var occupant_ready := SteamNetwork.get_player_ready_for_peer(occupant_id) if occupant_id > 0 else false

		role_card.set_selected(local_role_id == role_resource.role_id)
		role_card.set_occupied(occupied_by_other, occupant_name)
		role_card.set_locked(occupied_by_other)
		role_card.set_ready(occupant_ready if occupant_id > 0 else local_ready)


func _update_ready_panel() -> void:
	var local_role_id := SteamNetwork.get_player_role_for_peer(_local_steam_id)
	var local_ready := SteamNetwork.get_player_ready_for_peer(_local_steam_id)
	var can_toggle_ready := not local_role_id.is_empty()

	_ready_button.disabled = not can_toggle_ready
	_ready_button.text = "UNREADY" if local_ready else "READY UP"
	_ready_status_label.text = "STATUS: %s | ROLE: %s" % [
		"READY" if local_ready else "NOT READY",
		_resolve_role_display_name(local_role_id)
	]


func _on_role_selected(role_id: String) -> void:
	if SteamNetwork.set_local_role(role_id):
		_refresh_ui()


func _on_ready_button_pressed() -> void:
	if SteamNetwork.toggle_local_ready():
		_refresh_ui()


func _on_launch_button_pressed() -> void:
	if not SteamNetwork.begin_expedition_launch():
		push_warning("Launch blocked until every specialist is selected and ready.")


func _on_back_button_pressed() -> void:
	SteamNetwork.leave_current_lobby(true)


func _on_remote_role_updated(_steam_id: int, _role_value: String) -> void:
	_refresh_ui()


func _on_remote_ready_updated(_steam_id: int, _ready_state: bool) -> void:
	_refresh_ui()


func _on_lobby_state_changed(_state: String) -> void:
	_refresh_ui()


func _resolve_role_display_name(role_id: String) -> String:
	if role_id.is_empty():
		return "SELECTING..."

	var role_resource := CharacterRoleLibrary.find_role(role_id)
	if role_resource != null:
		return role_resource.get_label()

	return role_id
