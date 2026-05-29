extends Control

const LOBBY_VERSION_TEXT := "BUILD 0.1.0"

@onready var _browser_panel: PanelContainer = $MarginContainer/MainVBox/BrowserPanel
@onready var _browser_status_label: Label = $MarginContainer/MainVBox/BrowserPanel/BrowserVBox/BrowserHeader/BrowserStatusLabel
@onready var _browser_list_vbox: VBoxContainer = $MarginContainer/MainVBox/BrowserPanel/BrowserVBox/BrowserScroll/BrowserListVBox
@onready var _create_button: Button = $MarginContainer/MainVBox/ActionRow/CreateButton
@onready var _join_button: Button = $MarginContainer/MainVBox/ActionRow/JoinButton
@onready var _back_button: Button = $MarginContainer/MainVBox/ActionRow/BackButton
@onready var _refresh_button: Button = $MarginContainer/MainVBox/BrowserPanel/BrowserVBox/BrowserHeader/RefreshButton
@onready var _close_button: Button = $MarginContainer/MainVBox/BrowserPanel/BrowserVBox/BrowserHeader/CloseButton
@onready var _build_label: Label = $MarginContainer/MainVBox/BuildLabel


func _ready() -> void:
	AudioManager.start_menu_ambience()
	_browser_panel.visible = false
	_build_label.text = LOBBY_VERSION_TEXT
	_create_button.pressed.connect(_on_create_pressed)
	_join_button.pressed.connect(_on_join_pressed)
	_back_button.pressed.connect(_on_back_pressed)
	_refresh_button.pressed.connect(_on_refresh_pressed)
	_close_button.pressed.connect(_on_close_browser_pressed)
	if not SteamNetwork.lobby_browser_updated.is_connected(_on_lobby_browser_updated):
		SteamNetwork.lobby_browser_updated.connect(_on_lobby_browser_updated)


func _on_create_pressed() -> void:
	if not SteamNetwork.is_steam_running:
		_browser_status_label.text = "Steam is unavailable in this build."
		_browser_panel.visible = true
		return

	SteamNetwork.create_expedition_lobby()


func _on_join_pressed() -> void:
	_browser_panel.visible = true
	_browser_status_label.text = "Scanning for expeditions..."
	SteamNetwork.request_lobby_browser()


func _on_back_pressed() -> void:
	SceneManager.change_scene("res://scenes/ui/MainMenu.tscn")


func _on_refresh_pressed() -> void:
	_browser_panel.visible = true
	_browser_status_label.text = "Refreshing expedition list..."
	SteamNetwork.request_lobby_browser()


func _on_close_browser_pressed() -> void:
	_browser_panel.visible = false


func _on_lobby_browser_updated(lobbies: Array) -> void:
	for child in _browser_list_vbox.get_children():
		child.queue_free()

	if lobbies.is_empty():
		_browser_status_label.text = "No expeditions currently broadcasted."
		return

	_browser_status_label.text = "Select an expedition to join."
	for lobby_entry in lobbies:
		var lobby_button := Button.new()
		lobby_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lobby_button.text = _format_lobby_entry(lobby_entry)
		lobby_button.pressed.connect(func() -> void:
			SteamNetwork.join_expedition_lobby(int(lobby_entry.get("lobby_id", 0)))
		)
		_browser_list_vbox.add_child(lobby_button)


func _format_lobby_entry(lobby_entry: Dictionary) -> String:
	var lobby_name := String(lobby_entry.get("name", "Unnamed Expedition"))
	var member_count := int(lobby_entry.get("member_count", 0))
	var max_members := int(lobby_entry.get("max_members", 4))
	var state := String(lobby_entry.get("state", "UNKNOWN"))
	var version := String(lobby_entry.get("version", ""))
	return "%s\nSTATE: %s | CREW: %d/%d | VERSION: %s" % [lobby_name, state, member_count, max_members, version]
