extends Node2D


@onready var _world: Node = get_parent()

@export var move_speed: float = 180.0


func _ready() -> void:
	set_process(true)


func _process(_delta: float) -> void:
	var movement_direction: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if movement_direction != Vector2.ZERO:
		global_position += movement_direction.normalized() * move_speed * _delta

	if _world != null and _world.has_method("resolve_player_room"):
		_world.resolve_player_room()
