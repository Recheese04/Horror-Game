extends StaticBody3D

func get_interaction_prompt() -> String:
	return "Take Wallet"

func interact():
	var player = get_tree().root.find_child("Player", true, false)
	if player:
		if player.has_method("show_subtitle"):
			player.show_subtitle("Nakuha na nako ang kwarta.")
			# clear it after 3 seconds
			var timer = get_tree().create_timer(3.0)
			timer.timeout.connect(func(): player.hide_subtitle())
		
		if player.has_method("show_objective"):
			player.show_objective("Adto sa tindahan ni Aling Rosa\n(Palit asin, posporo og kandila)")
	
	queue_free()
