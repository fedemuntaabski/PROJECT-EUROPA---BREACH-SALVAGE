extends PanelContainer

signal role_selected(role_id)

const STAT_BAR_MAX := 10.0

var _role_resource: CharacterClassResource
var _role_id: String = ""
var _selected: bool = false
var _occupied: bool = false
var _locked: bool = false
var _ready_state: bool = false
var _hovered: bool = false
var _occupant_label: String = ""

@onready var _accent_bar: ColorRect = $MarginContainer/CardVBox/HeaderRow/AccentBar
@onready var _name_label: Label = $MarginContainer/CardVBox/HeaderRow/TextStack/NameLabel
@onready var _state_label: Label = $MarginContainer/CardVBox/HeaderRow/TextStack/StateLabel
@onready var _portrait_icon: TextureRect = $MarginContainer/CardVBox/PortraitPanel/PortraitIcon
@onready var _portrait_placeholder: Label = $MarginContainer/CardVBox/PortraitPanel/PortraitPlaceholder
@onready var _description_label: Label = $MarginContainer/CardVBox/DescriptionLabel
@onready var _traits_label: Label = $MarginContainer/CardVBox/TraitsLabel
@onready var _select_button: Button = $MarginContainer/CardVBox/SelectButton
@onready var _hp_bar: ProgressBar = $MarginContainer/CardVBox/StatsVBox/HPRow/HPBar
@onready var _combat_bar: ProgressBar = $MarginContainer/CardVBox/StatsVBox/CombatRow/CombatBar
@onready var _repair_bar: ProgressBar = $MarginContainer/CardVBox/StatsVBox/RepairRow/RepairBar
@onready var _utility_bar: ProgressBar = $MarginContainer/CardVBox/StatsVBox/UtilityRow/UtilityBar


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	if not _select_button.pressed.is_connected(_on_select_button_pressed):
		_select_button.pressed.connect(_on_select_button_pressed)
	_refresh_visual_state()


func populate_from_resource(role_resource: CharacterClassResource) -> void:
	_role_resource = role_resource
	_role_id = role_resource.role_id
	_name_label.text = role_resource.get_label()
	_description_label.text = role_resource.description
	_traits_label.text = _build_traits_text(role_resource.passive_traits)
	_accent_bar.color = role_resource.accent_color
	if role_resource.icon != null:
		_portrait_icon.texture = role_resource.icon
		_portrait_icon.visible = true
		_portrait_placeholder.visible = false
	else:
		_portrait_icon.texture = null
		_portrait_icon.visible = false
		_portrait_placeholder.text = role_resource.get_label().to_upper()
		_portrait_placeholder.visible = true

	_apply_stat_values(role_resource.starting_stats)
	_refresh_visual_state()


func set_selected(value: bool) -> void:
	_selected = value
	_refresh_visual_state()


func set_occupied(value: bool, occupant_label: String = "") -> void:
	_occupied = value
	_occupant_label = occupant_label
	_refresh_visual_state()


func set_locked(value: bool) -> void:
	_locked = value
	_refresh_visual_state()


func set_ready(value: bool) -> void:
	_ready_state = value
	_refresh_visual_state()


func _apply_stat_values(stats: CharacterStatsResource) -> void:
	if stats == null:
		stats = CharacterStatsResource.new()

	_hp_bar.max_value = STAT_BAR_MAX
	_combat_bar.max_value = STAT_BAR_MAX
	_repair_bar.max_value = STAT_BAR_MAX
	_utility_bar.max_value = STAT_BAR_MAX
	_animate_stat_bar(_hp_bar, stats.hp)
	_animate_stat_bar(_combat_bar, stats.combat)
	_animate_stat_bar(_repair_bar, stats.repair)
	_animate_stat_bar(_utility_bar, stats.utility)


func _animate_stat_bar(bar: ProgressBar, target_value: int) -> void:
	if bar == null:
		return

	var tween := create_tween()
	tween.tween_property(bar, "value", float(clampi(target_value, 0, int(STAT_BAR_MAX))), 0.2)


func _refresh_visual_state() -> void:
	if _role_resource == null:
		return

	var state_text := "AVAILABLE"
	if _locked:
		state_text = "LOCKED"
	elif _occupied and not _selected:
		state_text = "OCCUPIED"
		if not _occupant_label.is_empty():
			state_text = "OCCUPIED BY %s" % _occupant_label
		if _ready_state:
			state_text += " / READY"
	elif _selected and _ready_state:
		state_text = "READY"
	elif _selected:
		state_text = "SELECTED"
	elif _hovered:
		state_text = "INSPECT"

	if _occupied and _selected:
		state_text = "READY" if _ready_state else "SELECTED"

	_state_label.text = state_text
	_select_button.text = state_text if state_text != "AVAILABLE" else "SELECT"
	_select_button.disabled = _locked or (_occupied and not _selected)

	var tint := Color(0.96, 0.96, 0.96, 1.0)
	if _locked:
		tint = Color(0.45, 0.45, 0.48, 1.0)
	elif _occupied and not _selected:
		tint = Color(0.72, 0.72, 0.72, 1.0)
		if _ready_state:
			tint = Color(0.72, 0.95, 0.76, 1.0)
	elif _selected and _ready_state:
		tint = Color(0.82, 1.0, 0.82, 1.0)
	elif _selected:
		tint = Color(1.0, 0.96, 0.82, 1.0)
	elif _hovered:
		tint = Color(1.0, 1.0, 0.92, 1.0)

	modulate = tint


func _build_traits_text(traits: PackedStringArray) -> String:
	if traits.is_empty():
		return "NO PASSIVE TRAITS"

	return "PASSIVES: " + "  •  ".join(traits)


func _gui_input(event: InputEvent) -> void:
	if _locked or (_occupied and not _selected):
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_emit_role_selected()
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE):
		_emit_role_selected()


func _on_select_button_pressed() -> void:
	_emit_role_selected()


func _emit_role_selected() -> void:
	if _role_id.is_empty() or _locked or (_occupied and not _selected):
		return

	role_selected.emit(_role_id)


func _on_mouse_entered() -> void:
	_hovered = true
	_refresh_visual_state()


func _on_mouse_exited() -> void:
	_hovered = false
	_refresh_visual_state()
