extends StaticBody3D

# ── WALLET EXAMINE — 4-STEP PROFESSIONAL FLOW ───────────────────
#
# Step 1: EXAMINING  → Player sees wallet centered. Prompt: [E] Open
# Step 2: OPENED     → Flap opens, photo peeks out. Subtitle plays. Prompt: [E] Examine Photo
# Step 3: PHOTO      → Wallet hides, photo centers & is rotatable. Prompt: [E] Put Back
# Step 4: COIN_READY → Photo returns, wallet reappears showing coin. Prompt: [E] Take Coin
# After step 4 → DONE. Coin in inventory, examine ends.

enum WalletState { CLOSED, EXAMINING, OPENED, PHOTO, COIN_READY, DONE }
var scene_path = "res://scenes/wallet.tscn"
var state = WalletState.CLOSED
var _tween: Tween = null
var _photo_node: Node3D = null  # Reference to the reparented photo
var _saved_clone_pos: Vector3
var _saved_clone_rot: Vector3
var _saved_clone_scale: Vector3

func get_interaction_prompt() -> String:
	if state == WalletState.DONE:
		return ""
	return "Examine Wallet"

func interact():
	if state == WalletState.EXAMINING or state == WalletState.DONE:
		return
	state = WalletState.EXAMINING
	var player = get_tree().root.find_child("Player", true, false)
	if player and player.has_method("start_examine"):
		player.start_examine(self)

func examine_action(player):
	match state:
		WalletState.EXAMINING:
			_step_open(player)
		WalletState.OPENED:
			_step_photo(player)
		WalletState.PHOTO:
			_step_put_back(player)
		WalletState.COIN_READY:
			_step_take_coin(player)

func cancel_examine(player):
	_kill_tween()
	_cleanup_photo(player)
	if state != WalletState.DONE:
		state = WalletState.CLOSED
	player.end_examine()

# ── STEP 1: OPEN WALLET ─────────────────────────────────────────

func _step_open(player):
	state = WalletState.OPENED
	_kill_tween()
	
	if player.has_method("show_subtitle"):
		player.show_subtitle("Pila kaha dinhi...")
	
	var clone = player.examine_clone
	if not clone:
		return
	
	# Animate flap opening
	var flap = clone.get_node_or_null("Flap")
	if flap:
		var tw = player.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(flap, "rotation_degrees:x", -160.0, 0.5)
	
	# Create torn photo peeking out of the wallet
	if not clone.get_node_or_null("TornPhoto"):
		var photo = CSGBox3D.new()
		photo.name = "TornPhoto"
		photo.size = Vector3(0.045, 0.001, 0.035)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.85, 0.8, 0.7)  # Old yellowed paper
		photo.material_override = mat
		clone.add_child(photo)
		photo.position = Vector3(-0.02, 0.015, -0.01)
		photo.rotation_degrees = Vector3(-10, 15, 0)
	
	# After a beat, update prompt
	_tween = player.create_tween()
	_tween.tween_interval(2.5)
	_tween.tween_callback(func():
		if state == WalletState.OPENED:
			if player.has_method("hide_subtitle"): player.hide_subtitle()
			if player.has_method("update_examine_prompt"):
				player.update_examine_prompt("[Mouse] Rotate   |   [ESC] Back   |   [E] Examine Photo")
	)

# ── STEP 2: EXAMINE PHOTO (centered, rotatable) ─────────────────

func _step_photo(player):
	state = WalletState.PHOTO
	_kill_tween()
	
	if player.has_method("show_subtitle"):
		player.show_subtitle("Kinsa mani? Ngano gisi man ang litrato?")
	
	var clone = player.examine_clone
	if not clone:
		return
	
	# Save wallet clone's current transform so we can restore it later
	_saved_clone_pos = clone.position
	_saved_clone_rot = clone.rotation
	_saved_clone_scale = clone.scale
	
	var photo = clone.get_node_or_null("TornPhoto")
	if not photo:
		return
	
	# Reparent photo to camera so it's independent of the wallet
	photo.reparent(player.camera, false)
	_photo_node = photo
	
	# Hide the wallet clone
	clone.hide()
	
	# Animate photo to center of screen — same spot as examine_clone normally sits
	var tw = player.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(photo, "position", Vector3(0, -0.05, -0.35), 0.6)
	tw.parallel().tween_property(photo, "rotation_degrees", Vector3(0, 0, 0), 0.6)
	tw.parallel().tween_property(photo, "scale", Vector3(8.0, 8.0, 8.0), 0.6)
	
	# IMPORTANT: Swap the player's examine_clone reference to the photo
	# so the existing mouse-drag rotation code in player.gd works on it!
	player.examine_clone = photo
	
	# After subtitle, update prompt
	_tween = player.create_tween()
	_tween.tween_interval(3.5)
	_tween.tween_callback(func():
		if state == WalletState.PHOTO:
			if player.has_method("hide_subtitle"): player.hide_subtitle()
			if player.has_method("update_examine_prompt"):
				player.update_examine_prompt("[Mouse] Rotate   |   [ESC] Back   |   [E] Put Back Photo")
	)

# ── STEP 3: PUT PHOTO BACK, SHOW COIN ───────────────────────────

func _step_put_back(player):
	state = WalletState.COIN_READY
	_kill_tween()
	
	var clone_ref = null
	# Find the original wallet clone (it's still in the camera, just hidden)
	for child in player.camera.get_children():
		if child.scene_file_path == scene_path or child.name.begins_with("wallet") or child.name.begins_with("Wallet"):
			clone_ref = child
			break
	
	# If we can't find it by name/path, find the hidden StaticBody3D that isn't the photo
	if not clone_ref:
		for child in player.camera.get_children():
			if child != _photo_node and child is Node3D and not child.visible and child != player.get_node_or_null("Camera3D/CP"):
				clone_ref = child
				break
	
	# Clean up the photo from the camera
	if _photo_node and is_instance_valid(_photo_node):
		_photo_node.queue_free()
		_photo_node = null
	
	# Restore the wallet clone reference and show it
	if clone_ref:
		clone_ref.show()
		player.examine_clone = clone_ref
		
		# Restore original transform
		clone_ref.position = _saved_clone_pos
		clone_ref.rotation = _saved_clone_rot
		clone_ref.scale = _saved_clone_scale
		
		# Show coin prominently
		var coin = clone_ref.get_node_or_null("Coin")
		if coin:
			coin.show()
	
	if player.has_method("update_examine_prompt"):
		player.update_examine_prompt("[Mouse] Rotate   |   [ESC] Back   |   [E] Take Coin")

# ── STEP 4: TAKE THE COIN ───────────────────────────────────────

func _step_take_coin(player):
	state = WalletState.DONE
	_kill_tween()
	_cleanup_photo(player)
	
	# End examine mode
	player.end_examine()
	
	# Show coin pickup animation
	_show_coin_on_screen(player)
	
	# Add to inventory
	InventoryManager.add_item("coin", "Sinsilyo", "Usa ka sinsilyo gikan sa pitaka ni Nanay.", "res://scenes/coin.tscn")
	
	# Clean up subtitles
	if player.has_method("hide_subtitle"):
		player.hide_subtitle()
	
	# Update objective
	if player.has_method("show_objective"):
		player.show_objective("Adto sa tindahan ni Aling Rosa")

# ── HELPERS ──────────────────────────────────────────────────────

func _kill_tween():
	if _tween and _tween.is_valid():
		_tween.kill()

func _cleanup_photo(player):
	if _photo_node and is_instance_valid(_photo_node):
		_photo_node.queue_free()
		_photo_node = null
	# Also check camera directly
	var leftover = player.camera.get_node_or_null("TornPhoto")
	if leftover:
		leftover.queue_free()

func _show_coin_on_screen(player):
	var coin_scene = load("res://scenes/coin.tscn")
	if not coin_scene:
		return
	
	var coin_3d = coin_scene.instantiate()
	coin_3d.set_script(null)
	
	for child in coin_3d.get_children():
		if child is CollisionShape3D:
			child.queue_free()
	
	player.camera.add_child(coin_3d)
	coin_3d.position = Vector3(0, -0.05, -0.25)
	coin_3d.rotation_degrees = Vector3(90, 0, 0)
	coin_3d.scale = Vector3(2.0, 2.0, 2.0)
	
	var light = OmniLight3D.new()
	light.light_color = Color(1.0, 0.95, 0.8)
	light.light_energy = 3.0
	light.omni_range = 0.5
	light.position = Vector3(0, 0, 0.1)
	coin_3d.add_child(light)
	
	var tween = player.create_tween()
	tween.tween_property(coin_3d, "rotation_degrees:y", 360.0 * 2, 2.0)
	tween.tween_callback(func(): coin_3d.queue_free())
