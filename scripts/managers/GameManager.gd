extends Node

var settings: Dictionary:
	get:
		return SettingsManager.settings


func save_settings() -> void:
	SettingsManager.save_settings()


func load_settings() -> void:
	SettingsManager.load_settings()


func apply_settings() -> void:
	SettingsManager.apply_settings()


func change_scene(scene_path: String) -> void:
	SceneManager.change_scene(scene_path)