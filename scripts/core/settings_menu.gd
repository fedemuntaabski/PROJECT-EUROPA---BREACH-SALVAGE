extends Control

@onready var master_slider = $MainPanel/Content/MasterVolume
@onready var sfx_slider = $MainPanel/Content/SFXVolume
@onready var fullscreen = $MainPanel/Content/FullscreenToggle


func _ready():
	master_slider.value = SettingsManager.settings["master_volume"]
	sfx_slider.value = SettingsManager.settings["sfx_volume"]
	fullscreen.button_pressed = SettingsManager.settings["fullscreen"]


func _on_back_button_pressed():
	SettingsManager.save_settings()
	SceneManager.change_scene("res://scenes/ui/MainMenu.tscn")


# 🔊 MASTER
func _on_master_volume_value_changed(value):
	SettingsManager.set_setting("master_volume", value)


# 🔊 SFX
func _on_sfx_volume_value_changed(value):
	SettingsManager.set_setting("sfx_volume", value)


# 🖥 FULLSCREEN
func _on_fullscreen_toggle_toggled(value):
	SettingsManager.set_setting("fullscreen", value)