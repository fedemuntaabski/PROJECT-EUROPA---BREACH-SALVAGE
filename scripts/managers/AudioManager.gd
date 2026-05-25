extends Node

const AUDIO_BUS_MASTER := "Master"
const AUDIO_BUS_SFX := "SFX"
const AUDIO_BUS_MUSIC := "Music"
const AUDIO_BUS_AMBIENT := "Ambient"
const AUDIO_BUS_UI := "UI"

@onready var menu_ambience_player: AudioStreamPlayer = AudioStreamPlayer.new()

var _menu_ambience_active := false


func _ready() -> void:
	randomize()
	add_child(menu_ambience_player)
	menu_ambience_player.bus = AUDIO_BUS_AMBIENT
	menu_ambience_player.stream = preload("res://assets/audio/ambient/drone.mp3")
	SettingsManager.settings_changed.connect(_on_settings_changed)
	_on_settings_changed(SettingsManager.settings)


func _on_settings_changed(settings: Dictionary) -> void:
	_apply_bus_volume(AUDIO_BUS_MASTER, settings["master_volume"])
	_apply_bus_volume(AUDIO_BUS_SFX, settings["sfx_volume"])


func _apply_bus_volume(bus_name: String, value) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return

	AudioServer.set_bus_volume_db(bus_index, linear_to_db(clampf(float(value), 0.0, 1.0)))


func start_menu_ambience() -> void:
	if _menu_ambience_active:
		return

	_menu_ambience_active = true
	_ensure_menu_ambience_loop()


func _ensure_menu_ambience_loop() -> void:
	while _menu_ambience_active:
		if not menu_ambience_player.playing:
			menu_ambience_player.pitch_scale = randf_range(0.9, 1.1)
			menu_ambience_player.play()

		await get_tree().process_frame


func stop_menu_ambience() -> void:
	_menu_ambience_active = false

	if menu_ambience_player.playing:
		menu_ambience_player.stop()