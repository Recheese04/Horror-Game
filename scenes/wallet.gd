extends StaticBody3D

# Wallet examine states
enum WalletState { CLOSED, EXAMINING, OPENED, DONE }
var scene_path = "res://scenes/wallet.tscn"
var state = WalletState.CLOSED

func get_interaction_prompt() -> String:
	if state == WalletState.DONE:
		return ""
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
			_take_coin(player)

func _open_wallet(player):
	state = WalletState.OPENED
	
	# Animate the flap opening on the clone
	var clone = player.examine_clone
	if clone:
		var flap = clone.get_node_or_null("Flap")
		if flap:
			var tween = player.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tween.tween_property(flap, "rotation_degrees:x", -160.0, 0.5)
		
		# Show the coin inside
		var coin = clone.get_node_or_null("Coin")
		if coin:
			coin.show()
	
	# Update prompt using the new separate CanvasLayer text
	if player.has_method("update_examine_prompt"):
		player.update_examine_prompt("[Mouse] Rotate   |   [ESC] Back   |   [E] Take")

func _take_coin(player):
	state = WalletState.DONE
	
	# End examine mode
	player.end_examine()
	
	# Show coin on screen briefly
	_show_coin_on_screen(player)
	
	# Add to inventory
	InventoryManager.add_item("coin", "Coin", "Usa ka sinsilyo gikan sa wallet.", "res://scenes/coin.tscn")
	
	# Show subtitle
	if player.has_method("show_subtitle"):
		player.show_subtitle("Nakuha na nako ang kwarta.")
		var timer = get_tree().create_timer(3.0)
		timer.timeout.connect(func(): player.hide_subtitle())
	
	# Update objective
	if player.has_method("show_objective"):
		player.show_objective("Adto sa tindahan ni Aling Rosa")

func cancel_examine(player):
	if state == WalletState.EXAMINING:
		state = WalletState.CLOSED
	player.end_examine()

func _show_coin_on_screen(player):
	var coin_scene = load("res://scenes/coin.tscn")
	if not coin_scene:
		return
	
	var coin_3d = coin_scene.instantiate()
	# Remove its script so it acts just as a prop
	coin_3d.set_script(null)
	
	# IMPORTANT: Delete its collision so it doesn't push the player and make them fly!
	for child in coin_3d.get_children():
		if child is CollisionShape3D:
			child.queue_free()
	
	# Add to camera
	player.camera.add_child(coin_3d)
	
	# Position in front of camera
	coin_3d.position = Vector3(0, -0.05, -0.25)
	
	# Align so its face points at camera
	coin_3d.rotation_degrees = Vector3(90, 0, 0)
	
	# Enlarge it slightly
	coin_3d.scale = Vector3(2.0, 2.0, 2.0)
	
	# Add a light so it glows
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.95, 0.8)
	light.light_energy = 3.0
	light.omni_range = 0.5
	light.position = Vector3(0, 0, 0.1)
	coin_3d.add_child(light)
	
	# Animate spin then delete
	var tween = player.create_tween()
	tween.tween_property(coin_3d, "rotation_degrees:y", 360.0 * 2, 2.0)
	tween.tween_callback(func(): coin_3d.queue_free())
