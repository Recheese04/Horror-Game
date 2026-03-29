extends GPUParticles3D

var player: Node3D = null
var rain_audio: AudioStreamPlayer = null

func _ready():
	player = get_tree().root.find_child("Player", true, false)
	emitting = true
	
	# Create and play the ambient rain sound
	rain_audio = AudioStreamPlayer.new()
	var stream = load("res://assets/sounds/321173__inspectorj__ambience-rain-heavy-a.wav")
	rain_audio.stream = stream
	rain_audio.volume_db = -12.0 # Slightly quieter so it doesn't drown out everything
	rain_audio.bus = "Master"
	add_child(rain_audio)
	
	# Loop manually in case the WAV isn't imported as repeating
	rain_audio.finished.connect(func(): rain_audio.play())
	rain_audio.play()
	
	if player and player.has_method("show_subtitle"):
		player.show_subtitle("Christian: Hala, ga ulan na.")
		await get_tree().create_timer(3.0).timeout
		if player.has_method("hide_subtitle"):
			player.hide_subtitle()

func _physics_process(delta):
	if player:
		# Follow the player's XZ location, but stay high up above the roof
		global_position = Vector3(player.global_position.x, player.global_position.y + 15.0, player.global_position.z)
		
		# Detect if we are indoors by casting a ray straight UP from the player
		var space_state = get_world_3d().direct_space_state
		var origin = player.global_position + Vector3(0, 0.5, 0) # Start slightly above feet
		var end = origin + Vector3(0, 15.0, 0) # Cast 15 meters straight up
		
		var query = PhysicsRayQueryParameters3D.create(origin, end)
		# Ensure we don't accidentally hit the player's own physics body
		if player is CollisionObject3D:
			query.exclude = [player.get_rid()]
			
		var result = space_state.intersect_ray(query)
		var target_volume = -12.0 # Normal loud rain
		
		if result:
			# The ray hit a roof or ceiling! Muffle the rain.
			target_volume = -28.0
			
		if rain_audio:
			# Smoothly ease the volume so it doesn't instantly snap
			rain_audio.volume_db = lerpf(rain_audio.volume_db, target_volume, delta * 3.0)
