extends MeshInstance3D

var time := 0.0

func _process(delta):
	time += delta
	
	var emission = 1.8 + sin(time * 12.0) * 0.2
	
	var mat = get_active_material(0)
	
	if mat:
		mat.emission_energy_multiplier = emission