extends Control

@onready var master_slider = $MainPanel/Content/MasterVolume
@onready var sfx_slider = $MainPanel/Content/SFXVolume
@onready var fullscreen = $MainPanel/Content/FullscreenToggle


func _ready():
	master_slider.value = GameManager.settings["master_volume"]
	sfx_slider.value = GameManager.settings["sfx_volume"]
	fullscreen.button_pressed = GameManager.settings["fullscreen"]


func _on_back_button_pressed():
	GameManager.save_settings()
	GameManager.change_scene("res://scenes/ui/MainMenu.tscn")


# 🔊 MASTER
func _on_master_volume_value_changed(value):
	GameManager.settings["master_volume"] = value
	GameManager.apply_settings()


# 🔊 SFX
func _on_sfx_volume_value_changed(value):
	GameManager.settings["sfx_volume"] = value
	GameManager.apply_settings()


# 🖥 FULLSCREEN
func _on_fullscreen_toggle_toggled(value):
	GameManager.settings["fullscreen"] = value
	GameManager.apply_settings()