extends Control

@onready var ambient_audio = $Ambient
@onready var animation_player = $AnimationPlayer


func _ready():
	randomize()
	play_random_creaks()
	animation_player.play("intro")


func play_random_creaks():
	while true:
		var wait_time = randf_range(8.0, 20.0)
		await get_tree().create_timer(wait_time).timeout
		
		ambient_audio.pitch_scale = randf_range(0.9, 1.1)
		ambient_audio.play()


func _on_settings_button_pressed():
	GameManager.change_scene("res://scenes/ui/SettingsMenu.tscn")


func _on_exit_button_pressed():
	get_tree().quit()
