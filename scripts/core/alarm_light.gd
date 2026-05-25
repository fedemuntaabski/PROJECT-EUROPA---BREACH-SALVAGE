extends OmniLight3D

var time := 0.0
var base_energy := 1.5

func _process(delta):
	time += delta
	
	var flicker = sin(time * 8.0) * 0.15
	light_energy = base_energy + flicker