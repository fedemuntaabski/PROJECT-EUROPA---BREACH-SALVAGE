extends Control

@onready var animation_player = $AnimationPlayer


func _ready():
	AudioManager.start_menu_ambience()
	animation_player.play("intro")

func _on_start_button_pressed() -> void:
	print("Iniciando Operación: Solicitando creación de lobby en Steam...")
	# Llamamos al manager global que maneja la red de Steam
	SteamNetwork.create_mission_lobby()
	
func _on_settings_button_pressed():
	SceneManager.change_scene("res://scenes/ui/SettingsMenu.tscn")

func _on_exit_button_pressed():
	get_tree().quit()
