extends RigidBody3D

func get_interaction_prompt() -> String:
	return "Take Posporo"

func interact():
	var player = get_tree().root.find_child("Player", true, false)
	if player:
		player.has_posporo = true
		if player.has_method("show_subtitle"):
			player.show_subtitle("Christian: Nakuha nako ang posporo.")
			var timer = get_tree().create_timer(3.0)
			timer.timeout.connect(func(): player.hide_subtitle())
	
	InventoryManager.add_item("posporo", "Posporo", "Usa ka posporo.", "res://scenes/posporo.tscn")
			
	var root = get_tree().current_scene
	var tindera = root.find_child("Tindera", true, false)
	if tindera:
		var count = 0
		if tindera.has_meta("items_collected"):
			count = tindera.get_meta("items_collected")
		count += 1
		tindera.set_meta("items_collected", count)
		if count >= 2:
			if player and player.has_method("hide_objective"):
				player.hide_objective()
			tindera.set_meta("task_done", true)
			
			for m in get_tree().get_nodes_in_group("Mothers"):
				if m.get("is_return_interaction") == true:
					m.show()
					m.process_mode = Node.PROCESS_MODE_INHERIT
				else:
					m.queue_free()
			
	queue_free()
