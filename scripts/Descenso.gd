extends Control

const GAMEPLAY_SCENE_PATH := "res://scenes/gameplay/MainGameplay.tscn"

var terminal_label: RichTextLabel
var _sequence_active: bool = false

var alert_lines: Array = [
	"ESTABLISHING LINK WITH STATION NODE 04-B...",
	"CRITICAL ALERT: STATION LIFE SUPPORT SYSTEM IS [ OFFLINE ].",
	"EXTERNAL HYDROSTATIC PRESSURE: 400 ATM (CRITICAL).",
	"HULL INTEGRITY COMPROMISED IN ADJACENT SECTORS.",
	"DOCKING TETHER: ENGAGED.",
	"READY FOR EXTRACTION MIGRATION. PRESSURE RECHECKS MANDATORY."
]

func _ready() -> void:
	_sequence_active = true
	# 1. Configuración de pantalla completa
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	# Fondo negro clínico de terminal
	var bg = ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.02)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# 2. Configurar el RichTextLabel por código para el efecto typewriter
	terminal_label = RichTextLabel.new()
	terminal_label.custom_minimum_size = Vector2(800, 500)
	# Habilitamos efectos como ondas o parpadeos nativos de Godot
	terminal_label.bbcode_enabled = true 
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	center.add_child(terminal_label)
	
	# Arrancar la secuencia de comandos cinematográfica
	_run_terminal_sequence()


func _exit_tree() -> void:
	_sequence_active = false

func _run_terminal_sequence() -> void:
	if not _sequence_active:
		return

	terminal_label.text = ""
	
	for line in alert_lines:
		if not _sequence_active or not is_inside_tree():
			return

		var formatted_line = line
		# Si la línea contiene alertas, le ponemos color de terminal industrial por BBCode
		if "CRITICAL" in line or "OFFLINE" in line:
			formatted_line = "[color=red]" + line + "[/color]"
		else:
			formatted_line = "[color=green]" + line + "[/color]"
			
		# Efecto máquina de escribir línea por línea
		terminal_label.append_text(formatted_line + "\n")
		
		# Un pequeño sonido sutil de click de terminal por cada línea quedaría brutal aquí:
		# AudioManager.play_terminal_click() 
		
		await get_tree().create_timer(0.8).timeout # Pausa dramática entre escaneos
		if not _sequence_active or not is_inside_tree():
			return
		
	if not _sequence_active or not is_inside_tree():
		return

	await get_tree().create_timer(1.5).timeout
	if not _sequence_active or not is_inside_tree():
		return

	_open_capsule_doors()

func _open_capsule_doors() -> void:
	if not _sequence_active or not is_inside_tree():
		return

	print("Secuencia de comandos finalizada. Abriendo compuertas hacia la Safe Zone...")
	if not SteamNetwork.is_host or SteamNetwork.lobby_id == 0:
		return

	var generated_seed := randi()
	Steam.setLobbyData(SteamNetwork.lobby_id, "world_seed", str(generated_seed))
	SceneManager.change_scene(GAMEPLAY_SCENE_PATH)
	# Aquí es donde la UI se desvanece y le da paso al entorno 2D/3D jugable