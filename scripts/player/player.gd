extends CharacterBody2D

class_name CharacterController


signal interaction_requested(target: Node)
signal interacted(target: Node)
signal facing_changed(direction: Vector2)


const INTERACTABLE_GROUP := &"interactable"


@export var fallback_move_speed: float = 180.0
@export var acceleration: float = 900.0
@export var deceleration: float = 1200.0
@export var move_left_action: StringName = &"left"
@export var move_right_action: StringName = &"right"
@export var move_up_action: StringName = &"up"
@export var move_down_action: StringName = &"down"
@export var interact_action: StringName = &"interact"

@onready var _stats_component: StatsComponent = get_node_or_null("Components/StatsComponent") as StatsComponent
@onready var _health_component: HealthComponent = get_node_or_null("Components/HealthComponent") as HealthComponent
@onready var _ability_component: AbilityComponent = get_node_or_null("Components/AbilityComponent") as AbilityComponent
@onready var _status_effect_component: StatusEffectComponent = get_node_or_null("Components/StatusEffectComponent") as StatusEffectComponent
@onready var _inventory_component: InventoryComponent = get_node_or_null("Components/InventoryComponent") as InventoryComponent
@onready var _interaction_area: Area2D = $InteractionArea
@onready var _animation_controller: CharacterAnimationController = get_node_or_null("AnimationController") as CharacterAnimationController


var _facing_direction: Vector2 = Vector2.DOWN
var _interaction_targets: Array[Node] = []


func _ready() -> void:
	# The root node owns movement and interaction routing; components own their own data.
	if is_instance_valid(_interaction_area):
		_interaction_area.body_entered.connect(_on_interaction_body_entered)
		_interaction_area.body_exited.connect(_on_interaction_body_exited)
		_interaction_area.area_entered.connect(_on_interaction_area_entered)
		_interaction_area.area_exited.connect(_on_interaction_area_exited)

	if is_instance_valid(_health_component):
		_health_component.died.connect(_on_health_component_died)

	if is_instance_valid(_animation_controller):
		_animation_controller.set_facing_direction(_facing_direction)


func _physics_process(delta: float) -> void:
	if is_instance_valid(_health_component) and not _health_component.is_alive():
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
		move_and_slide()
		return

	var movement_direction: Vector2 = Input.get_vector(move_left_action, move_right_action, move_up_action, move_down_action)
	var target_velocity: Vector2 = movement_direction * _get_move_speed()
	var response_rate: float = acceleration if movement_direction != Vector2.ZERO else deceleration
	velocity = velocity.move_toward(target_velocity, response_rate * delta)
	move_and_slide()

	if movement_direction != Vector2.ZERO:
		_set_facing_direction(movement_direction)

	if Input.is_action_just_pressed(interact_action):
		request_interaction()


func request_interaction() -> void:
	# This only chooses a target and forwards the request; actual interaction logic lives elsewhere.
	var target: Node = _get_best_interaction_target()
	if target == null:
		return

	interaction_requested.emit(target)
	if target.has_method("interact"):
		target.call("interact", self)
		interacted.emit(target)
	elif target.has_method("on_interact"):
		target.call("on_interact", self)
		interacted.emit(target)


func take_damage(amount: int, source: Node = null) -> int:
	if not is_instance_valid(_health_component):
		return 0
	return _health_component.apply_damage(amount, source)


func heal(amount: int, source: Node = null) -> int:
	if not is_instance_valid(_health_component):
		return 0
	return _health_component.heal(amount, source)


func get_movement_speed() -> float:
	if is_instance_valid(_stats_component):
		return _stats_component.get_movement_speed()
	return fallback_move_speed


func get_stat(stat_name: StringName) -> Variant:
	if is_instance_valid(_stats_component):
		return _stats_component.get_stat(stat_name)
	return null


func get_health_component() -> HealthComponent:
	return _health_component


func get_stats_component() -> StatsComponent:
	return _stats_component


func get_ability_component() -> AbilityComponent:
	return _ability_component


func get_status_effect_component() -> StatusEffectComponent:
	return _status_effect_component


func get_inventory_component() -> InventoryComponent:
	return _inventory_component


func _get_move_speed() -> float:
	if is_instance_valid(_stats_component):
		return _stats_component.get_movement_speed()
	return fallback_move_speed


func _set_facing_direction(direction: Vector2) -> void:
	var normalized_direction: Vector2 = direction.normalized()
	if normalized_direction == _facing_direction:
		return

	_facing_direction = normalized_direction
	facing_changed.emit(_facing_direction)
	if is_instance_valid(_animation_controller):
		_animation_controller.set_facing_direction(_facing_direction)


func _on_interaction_body_entered(body: Node) -> void:
	_register_interaction_target(body)


func _on_interaction_body_exited(body: Node) -> void:
	_unregister_interaction_target(body)


func _on_interaction_area_entered(area: Area2D) -> void:
	_register_interaction_target(area)


func _on_interaction_area_exited(area: Area2D) -> void:
	_unregister_interaction_target(area)


func _register_interaction_target(target: Node) -> void:
	if not _is_valid_interactable(target):
		return

	if not _interaction_targets.has(target):
		_interaction_targets.append(target)


func _unregister_interaction_target(target: Node) -> void:
	_interaction_targets.erase(target)


func _get_best_interaction_target() -> Node:
	var best_target: Node = null
	var best_distance: float = INF

	for target in _interaction_targets:
		if not is_instance_valid(target):
			continue

		if target is Node2D:
			var distance_to_target: float = global_position.distance_to((target as Node2D).global_position)
			if distance_to_target < best_distance:
				best_distance = distance_to_target
				best_target = target
		elif best_target == null:
			best_target = target

	return best_target


func _is_valid_interactable(target: Node) -> bool:
	return is_instance_valid(target) and (target.is_in_group(INTERACTABLE_GROUP) or target.has_method("interact") or target.has_method("on_interact") or target.has_method("can_interact"))


func _on_health_component_died() -> void:
	velocity = Vector2.ZERO
	if is_instance_valid(_animation_controller):
		_animation_controller.play_death()
