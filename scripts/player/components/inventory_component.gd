extends Node

class_name InventoryComponent


signal inventory_changed
signal item_added(item_id: StringName, amount: int)
signal item_removed(item_id: StringName, amount: int)


@export var starting_items: Dictionary = {}


var _items: Dictionary = {}


func _ready() -> void:
	# Inventory stays intentionally simple here so future item systems can plug in cleanly.
	_items = starting_items.duplicate(true)


func add_item(item_id: StringName, amount: int = 1) -> void:
	if amount <= 0:
		return

	_items[item_id] = get_item_count(item_id) + amount
	item_added.emit(item_id, amount)
	inventory_changed.emit()


func remove_item(item_id: StringName, amount: int = 1) -> bool:
	if amount <= 0 or not _items.has(item_id):
		return false

	var current_amount: int = get_item_count(item_id)
	if current_amount < amount:
		return false

	current_amount -= amount
	if current_amount <= 0:
		_items.erase(item_id)
	else:
		_items[item_id] = current_amount

	item_removed.emit(item_id, amount)
	inventory_changed.emit()
	return true


func get_item_count(item_id: StringName) -> int:
	return int(_items.get(item_id, 0))


func has_item(item_id: StringName, amount: int = 1) -> bool:
	return get_item_count(item_id) >= amount


func clear_inventory() -> void:
	if _items.is_empty():
		return

	_items.clear()
	inventory_changed.emit()


func get_item_ids() -> Array[StringName]:
	return _items.keys()