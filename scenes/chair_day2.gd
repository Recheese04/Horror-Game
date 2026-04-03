extends StaticBody3D

var manager = null
var is_sitting = false
var original_player_pos: Vector3
var original_player_rot: Vector3

func _ready():
	add_to_group("Interactable")

func get_interaction_prompt() -> String:
	if not manager:
		manager = get_tree().root.find_child("Level2", true, false)
	
	if manager and manager.current_state == 1: # TALKED_TO_NANAY_MORNING
		if not is_sitting:
			return "Linkod aron mokaon" # Sit to eat
		else:
			return "" # Already sitting
	return ""

func interact():
	if not manager:
		manager = get_tree().root.find_child("Level2", true, false)
		
	if manager and manager.current_state == 1 and not is_sitting:
		var player = get_tree().root.find_child("Player", true, false)
		if player:
			is_sitting = true
			player.is_sitting = true
			player.in_cinematic = true # Lock movement
			
			# Store original pos to stand up later? 
			original_player_pos = player.global_position
			
			# Teleport player to the chair
			# We'll use the chair's position but offset for sitting
			var sit_pos = global_position + Vector3(0, 0.6, 0) # Offset for sitting camera height
			player.global_position = sit_pos
			
			# Make player look at the table (center of plate area)
			# Plates are around X=-8.3, Z=4.3
			var look_target = Vector3(-8.3, 0.8, 4.3)
			var eye_pos = player.global_position + Vector3(0, 0.8, 0) # Camera's approximate global pos?
			if player.has_node("Camera3D"):
				eye_pos = player.get_node("Camera3D").global_position
			var target_dir = (look_target - eye_pos).normalized()
			
			var target_yaw = atan2(-target_dir.x, -target_dir.z)
			var target_pitch = asin(target_dir.y)
			
			player.rotation.y = target_yaw
			if player.has_node("Camera3D"):
				var cam = player.get_node("Camera3D")
				cam.rotation.x = target_pitch
				cam.rotation.y = 0
				cam.rotation.z = 0
			
			if player.has_method("show_subtitle"):
				player.show_subtitle("Lami-a sa baho sa pagkaon...")

func stand_up():
	if is_sitting:
		is_sitting = false
		var player = get_tree().root.find_child("Player", true, false)
		if player:
			player.is_sitting = false
			player.in_cinematic = false
			# Return to standing height from chair
			player.global_position.y += 0.8
