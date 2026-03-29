extends Node

## Global inventory manager — add as Autoload "InventoryManager"

signal inventory_changed
signal item_added(item_data: Dictionary)
signal item_removed(item_data: Dictionary)

var _items: Array[Dictionary] = []

func add_item(id: String, display_name: String, description: String, scene_path: String = "") -> void:
	var item := {
		"id": id,
		"name": display_name,
		"description": description,
		"scene_path": scene_path
	}
	_items.append(item)
	item_added.emit(item)
	inventory_changed.emit()

func remove_item(id: String) -> bool:
	for i in range(_items.size()):
		if _items[i]["id"] == id:
			var removed = _items[i]
			_items.remove_at(i)
			item_removed.emit(removed)
			inventory_changed.emit()
			return true
			
	var player = get_tree().root.find_child("Player", true, false)
	if player and player.held_object and player.held_object.has_meta("item_id"):
		if player.held_object.get_meta("item_id") == id:
			player.held_object.queue_free()
			player.held_object = null
			# Optionally emit inventory changed? No, it wasn't in list anyway
			return true
			
	return false

func has_item(id: String) -> bool:
	for item in _items:
		if item["id"] == id:
			return true
			
	var player = get_tree().root.find_child("Player", true, false)
	if player and player.held_object and player.held_object.has_meta("item_id"):
		if player.held_object.get_meta("item_id") == id:
			return true
			
	return false

func get_items() -> Array[Dictionary]:
	return _items

func get_item_count() -> int:
	return _items.size()

func clear() -> void:
	_items.clear()
	inventory_changed.emit()
