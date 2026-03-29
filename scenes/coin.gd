extends StaticBody3D

func get_interaction_prompt() -> String:
	return "Take Coin"

func interact():
	var player = get_tree().root.find_child("Player", true, false)
	if player and player.has_method("show_subtitle"):
		player.show_subtitle("Got a coin.")
		var timer = get_tree().create_timer(2.0)
		timer.timeout.connect(func(): player.hide_subtitle())
	
	InventoryManager.add_item("coin", "Coin", "Usa ka sinsilyo.", "res://scenes/coin.tscn")
	queue_free()
