extends Node2D


@onready var _world: Node = get_parent()


func _ready() -> void:
	set_process(true)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_left"):
		_request_move(&"left")
	elif Input.is_action_just_pressed("ui_right"):
		_request_move(&"right")
	elif Input.is_action_just_pressed("ui_up"):
		_request_move(&"up")
	elif Input.is_action_just_pressed("ui_down"):
		_request_move(&"down")


func _request_move(direction: StringName) -> void:
	if _world != null and _world.has_method("try_move"):
		_world.try_move(direction)
