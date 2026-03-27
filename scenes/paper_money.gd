extends StaticBody3D

func get_interaction_prompt() -> String:
	return "Take Paper Money"

func interact():
	var player = get_tree().root.find_child("Player", true, false)
	if player and player.has_method("show_subtitle"):
		player.show_subtitle("Got ₱100.")
		var timer = get_tree().create_timer(2.0)
		timer.timeout.connect(func(): player.hide_subtitle())
	
	queue_free()
