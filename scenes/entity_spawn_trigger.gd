extends Area3D

@export var target_entity: NodePath
var entity_node: Node3D = null

var triggered: bool = false

# Direction and speed for the entity to glide when spawned
@export var slide_direction: Vector3 = Vector3(1, 0, 0)
@export var slide_speed: float = 1.2

func _ready():
	body_entered.connect(_on_body_entered)
	if not target_entity.is_empty():
		entity_node = get_node_or_null(target_entity)
		if entity_node:
			# Hide the entity initially until the trigger is crossed
			entity_node.hide()
			# If it has a collision shape, disable it temporarily
			_set_collision(entity_node, false)

func _on_body_entered(body):
	if body.name == "Player" and not triggered:
		if _has_required_items():
			triggered = true
			
			# Spawn the entity
			if entity_node:
				entity_node.show()
				_set_collision(entity_node, true)
				
				# Start gliding to its own right side
				if entity_node.has_method("start_gliding"):
					entity_node.start_gliding(entity_node.global_transform.basis.x, slide_speed)
			
			# Player dialogue line
			if body.has_method("show_subtitle"):
				body.show_subtitle("Christian: Hala yawa, unsa mana?\n(Oh my god, what is that?)")
				_hide_subtitle_later(body, 3.0)
			
			# DO NOT queue_free() here, because doing so destroys this node
			# and cancels the _hide_subtitle_later async timer!
			# `triggered = true` is already enough to prevent re-entry.

func _has_required_items() -> bool:
	var candles_count = 0
	var has_posporo = false
	
	# Check InventoryManager (Autoload)
	var inv = get_tree().root.get_node_or_null("InventoryManager")
	if inv and inv.has_method("get_items"):
		var items = inv.get_items()
		for item in items:
			var item_str = str(item).to_lower()
			if "candle" in item_str or "kandila" in item_str:
				candles_count += 1
			if "posporo" in item_str or "match" in item_str:
				has_posporo = true

	# Check player's held object just in case
	var player = get_tree().root.find_child("Player", true, false)
	if player and player.get("held_object") != null:
		var held = player.held_object
		if held.has_meta("item_id"):
			var hid = held.get_meta("item_id")
			if hid == "candle":
				candles_count += 1
			elif hid == "posporo":
				has_posporo = true
	
	# To be extremely safe, check if the "task_done" from the store was completed.
	# But actually we just count items:
	return candles_count >= 4 and has_posporo

func _hide_subtitle_later(player: Node, time: float):
	await get_tree().create_timer(time).timeout
	if is_instance_valid(player) and player.has_method("hide_subtitle"):
		player.hide_subtitle()

func _set_collision(node: Node, enabled: bool):
	if is_instance_valid(node) and node is CollisionShape3D:
		node.set_deferred("disabled", not enabled)
	for child in node.get_children():
		_set_collision(child, enabled)
