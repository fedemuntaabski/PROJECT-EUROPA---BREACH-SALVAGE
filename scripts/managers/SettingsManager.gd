extends Node

signal settings_changed(settings: Dictionary)

const SAVE_PATH := "user://settings.cfg"
const SECTION := "settings"
const DEFAULT_SETTINGS := {
	"master_volume": 1.0,
	"sfx_volume": 1.0,
	"fullscreen": false,
}

var settings: Dictionary = DEFAULT_SETTINGS.duplicate(true)
var _save_request_id := 0


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	settings = DEFAULT_SETTINGS.duplicate(true)

	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		for key in DEFAULT_SETTINGS:
			if config.has_section_key(SECTION, key):
				settings[key] = config.get_value(SECTION, key)

	apply_settings()


func save_settings() -> void:
	_save_request_id += 1

	var config := ConfigFile.new()

	for key in settings:
		config.set_value(SECTION, key, settings[key])

	config.save(SAVE_PATH)


func set_setting(key: String, value) -> void:
	if not settings.has(key):
		return

	settings[key] = value
	apply_settings()
	schedule_save()


func apply_settings() -> void:
	_apply_display()
	settings_changed.emit(settings.duplicate(true))


func schedule_save() -> void:
	_save_request_id += 1
	var request_id := _save_request_id

	await get_tree().create_timer(0.5).timeout
	if request_id == _save_request_id:
		save_settings()


func _apply_display() -> void:
	if settings["fullscreen"]:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)