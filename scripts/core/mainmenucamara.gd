extends Camera3D

var time := 0.0
var base_position : Vector3

func _ready():
	base_position = position

func _process(delta):
	time += delta
	
	position.y = base_position.y + sin(time * 0.5) * 0.05
	rotation.z = sin(time * 0.3) * 0.01