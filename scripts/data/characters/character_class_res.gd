extends Resource
class_name CharacterClassResource

@export var role_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var starting_stats: CharacterStatsResource
@export var icon: Texture2D
@export var accent_color: Color = Color(0.7, 0.8, 0.9, 1.0)
@export var passive_traits: PackedStringArray = []
@export var upgrade_hooks: PackedStringArray = []

func get_label() -> String:
	if display_name.is_empty():
		return role_id

	return display_name
