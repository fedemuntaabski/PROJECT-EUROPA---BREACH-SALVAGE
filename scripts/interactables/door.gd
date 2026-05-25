extends Node3D

@onready var door_mesh: MeshInstance3D = $DoorMesh
@onready var door_body_collision: CollisionShape3D = $DoorBody/CollisionShape3D
@onready var interact_area: Area3D = $InteractArea

var is_open := false
var player_inside := false


func _ready() -> void:
	interact_area.body_entered.connect(_on_interact_area_body_entered)
	interact_area.body_exited.connect(_on_interact_area_body_exited)
	close_door()


func _physics_process(_delta: float) -> void:
	if player_inside and Input.is_action_just_pressed("interact"):
		toggle_door()


func _on_interact_area_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		player_inside = true


func _on_interact_area_body_exited(body: Node3D) -> void:
	if body.name == "Player":
		player_inside = false


func toggle_door() -> void:
	is_open = !is_open

	if is_open:
		open_door()
	else:
		close_door()


func open_door() -> void:
	door_mesh.rotation_degrees.y = 90.0
	door_body_collision.disabled = true


func close_door() -> void:
	door_mesh.rotation_degrees.y = 0.0
	door_body_collision.disabled = false