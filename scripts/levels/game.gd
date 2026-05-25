extends Node


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		SceneManager.change_scene("res://scenes/ui/MainMenu.tscn")