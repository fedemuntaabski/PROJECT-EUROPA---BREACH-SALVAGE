extends Node

var settings = {
	"master_volume": 1.0,
	"sfx_volume": 1.0,
	"fullscreen": false
}

const SAVE_PATH = "user://settings.cfg"
const SECTION = "settings"


func _ready():
	load_settings()
	apply_settings()


# 💾 SAVE
func save_settings():
	var config = ConfigFile.new()

	for key in settings:
		config.set_value(SECTION, key, settings[key])

	config.save(SAVE_PATH)


# 📥 LOAD
func load_settings():
	var config = ConfigFile.new()

	if config.load(SAVE_PATH) != OK:
		return

	for key in settings.keys():
		if config.has_section_key(SECTION, key):
			settings[key] = config.get_value(SECTION, key)


# 🎛 APPLY
func apply_settings():
	_apply_audio()
	_apply_display()


func _apply_audio():
	var master_bus = AudioServer.get_bus_index("Master")
	var sfx_bus = AudioServer.get_bus_index("SFX")

	AudioServer.set_bus_volume_db(
		master_bus,
		linear_to_db(settings["master_volume"])
	)

	AudioServer.set_bus_volume_db(
		sfx_bus,
		linear_to_db(settings["sfx_volume"])
	)


func _apply_display():
	if settings["fullscreen"]:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


# 🔄 SCENE MANAGER SIMPLE
func change_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)