extends CharacterBody3D

@export var speed := 5.0
@export var mouse_sens := 0.002

@onready var camera = $Camera3D

var rotation_x = 0.0


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sens)
		
		rotation_x = clamp(rotation_x - event.relative.y * mouse_sens, -1.2, 1.2)
		camera.rotation.x = rotation_x


func _physics_process(delta):
	var direction = Vector3.ZERO

	if Input.is_action_pressed("ui"):
		direction -= transform.basis.z
	if Input.is_action_pressed("ui"):
		direction += transform.basis.z
	if Input.is_action_pressed("ui"):
		direction -= transform.basis.x
	if Input.is_action_pressed("ui"):
		direction += transform.basis.x

	direction = direction.normalized()

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0

	move_and_slide()