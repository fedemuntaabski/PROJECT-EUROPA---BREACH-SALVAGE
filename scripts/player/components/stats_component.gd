extends Node

class_name StatsComponent


signal stats_changed


@export var movement_speed: float = 180.0
@export var repair_speed: float = 1.0
@export var flood_resistance: float = 0.0
@export var pressure_tolerance: float = 1.0
@export var extra_stats: Dictionary = {}


func get_movement_speed() -> float:
	return movement_speed


func get_repair_speed() -> float:
	return repair_speed


func get_flood_resistance() -> float:
	return flood_resistance


func get_pressure_tolerance() -> float:
	return pressure_tolerance


func get_stat(stat_name: StringName) -> Variant:
	match stat_name:
		&"movement_speed":
			return movement_speed
		&"repair_speed":
			return repair_speed
		&"flood_resistance":
			return flood_resistance
		&"pressure_tolerance":
			return pressure_tolerance
		_:
			return extra_stats.get(stat_name, null)


func set_stat(stat_name: StringName, value: Variant) -> void:
	match stat_name:
		&"movement_speed":
			movement_speed = float(value)
		&"repair_speed":
			repair_speed = float(value)
		&"flood_resistance":
			flood_resistance = float(value)
		&"pressure_tolerance":
			pressure_tolerance = float(value)
		_:
			extra_stats[stat_name] = value

	stats_changed.emit()


func set_extra_stat(stat_name: StringName, value: Variant) -> void:
	extra_stats[stat_name] = value
	stats_changed.emit()