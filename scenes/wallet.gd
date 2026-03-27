extends StaticBody3D

# Wallet examine states
enum WalletState { CLOSED, EXAMINING, OPENED, DONE }
var state = WalletState.CLOSED

func get_interaction_prompt() -> String:
	return "Examine Wallet"

func interact():
	if state != WalletState.CLOSED:
		return
	
	state = WalletState.EXAMINING
	var player = get_tree().root.find_child("Player", true, false)
	if player and player.has_method("start_examine"):
		player.start_examine(self)

func examine_action(player):
	match state:
		WalletState.EXAMINING:
			_open_wallet(player)
		WalletState.OPENED:
			_take_money(player)

func _open_wallet(player):
	state = WalletState.OPENED
	
	# Animate the flap opening on the clone
	var clone = player.examine_clone
	if clone:
		var flap = clone.get_node_or_null("Flap")
		if flap:
			var tween = player.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tween.tween_property(flap, "rotation_degrees:x", -160.0, 0.5)
		
		# Show the money inside
		var money = clone.get_node_or_null("Money")
		if money:
			money.show()
	
	# Update prompt
	player.interact_label.text = "Press E to take money"
	player.interact_label.show()

func _take_money(player):
	state = WalletState.DONE
	
	# End examine mode
	player.end_examine()
	
	# Show subtitle
	if player.has_method("show_subtitle"):
		player.show_subtitle("Nakuha na nako ang kwarta.\n(I got the money.)")
		var timer = get_tree().create_timer(3.0)
		timer.timeout.connect(func(): player.hide_subtitle())
	
	# Update objective
	if player.has_method("show_objective"):
		player.show_objective("Adto sa tindahan ni Aling Rosa\n(Go to Aling Rosa's store)")
	
	# Remove the wallet from the world
	queue_free()
