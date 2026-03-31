extends AnimatableBody3D

@onready var anim = $AnimationPlayer
@export var jumpscare_scene: PackedScene
@export var is_front_door: bool = false
@export var is_level_2_front_door: bool = false

var jumpscare_triggered = false
var front_door_triggered = false
var door_audio: AudioStreamPlayer3D

func _ready():
	# Dynamically hook up the door creak sound effect
	door_audio = AudioStreamPlayer3D.new()
	door_audio.stream = load("res://assets/sounds/15419__pagancow__dorm-door-opening.wav")
	door_audio.max_distance = 15.0
	door_audio.bus = "Master"
	add_child(door_audio)

func interact():
	if is_front_door:
		_play_front_door_transition()
		return
		
	if is_level_2_front_door:
		var manager = get_tree().root.find_child("Level2", true, false)
		if manager and manager.current_state >= 2 and manager.current_state < 4:
			_play_level2_jake_arrival()
		elif manager and manager.current_state < 2:
			var player = get_tree().root.find_child("Player", true, false)
			if player and player.has_method("show_subtitle"):
				player.show_subtitle("Sirado ang pultahan.")
		return

	# Play the creaking sound effect immediately
	door_audio.pitch_scale = randfn(1.0, 0.1) # slight variation to sound organic
	door_audio.play()
	
	if get_meta("is_open", false):
		anim.play("door_close")
		set_meta("is_open", false)
	else:
		anim.play("door_open")
		set_meta("is_open", true)
		
		# Trigger jumpscare on first open if a scene is assigned
		if not jumpscare_triggered and jumpscare_scene:
			trigger_jumpscare()
			jumpscare_triggered = true

func trigger_jumpscare():
	print("Jumpscare Triggered from Door!")
	var jumpscare = jumpscare_scene.instantiate()
	get_tree().root.add_child(jumpscare)
	if jumpscare.has_method("trigger"):
		jumpscare.trigger()

func _play_front_door_transition():
	var player = get_tree().root.find_child("Player", true, false)
	if not player: return
	
	# Lock player immediately
	if player.has_method("set_physics_process"):
		player.in_cinematic = true
	
	# 1. Professional Audio - Load and start fading in outside sounds

	var ambient_audio = AudioStreamPlayer.new()
	ambient_audio.stream = load("res://assets/sounds/234226__tyops__scary-environment.wav")
	ambient_audio.volume_db = -40
	ambient_audio.bus = "Master"
	get_tree().root.add_child(ambient_audio)
	ambient_audio.play()
	
	# 2. Camera reference (optional, for effect)
	var cam = player.get_node_or_null("Camera3D")
	var original_cam_pos = Vector3.ZERO
	if cam: original_cam_pos = cam.position
	
	# Play door open sound (no visual animation for front door transition)
	door_audio.pitch_scale = randfn(1.0, 0.1)
	door_audio.play()
	
	# Create fade to black UI dynamically
	var canvas = CanvasLayer.new()
	var fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.modulate.a = 0.0
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(fade_rect)
	add_child(canvas)
	
	var tw = create_tween().set_parallel(true)
	
	# Sequence: FAST fade out first to hide door move (AGAD!)
	tw.tween_property(fade_rect, "modulate:a", 1.0, 0.05)
	if cam: tw.tween_property(cam, "position", original_cam_pos + Vector3(0, 0, -1.0), 2.0).set_trans(Tween.TRANS_SINE)

	tw.tween_property(ambient_audio, "volume_db", -5.0, 3.0)
	
	# Flicker the flashlight out ONLY on the first interaction
	var flashlight = null
	var flashlight_ui = null
	if "held_object" in player and player.held_object != null:
		flashlight = player.held_object.get_node_or_null("Flashlight")
		flashlight_ui = player.held_object.get_node_or_null("SubViewport/FlashlightUI")
		
	if not flashlight:
		flashlight = player.get_node_or_null("Camera3D/SpotLight3D")
		
	if not front_door_triggered and flashlight and flashlight.visible:
		var base_energy = flashlight.light_energy
		if base_energy == 0: base_energy = 2.0
		var ftw = create_tween()
		for i in range(5):
			ftw.tween_property(flashlight, "light_energy", 0.1, 0.05)
			ftw.tween_interval(0.05)
			ftw.tween_property(flashlight, "light_energy", base_energy, 0.05)
			ftw.tween_interval(0.05)
		ftw.tween_callback(func(): 
			flashlight.hide()
			if flashlight_ui:
				flashlight_ui.texture = load("res://assets/images/flashlightoff.jpg")
		)
	
	# Wait in dark for a moment
	var stw = create_tween()
	stw.tween_interval(0.1) # Wait slightly for the 0.05 fade to finish
	stw.tween_interval(2.0)
	stw.tween_callback(func():
		# Bidirectional Teleport Logic
		var root = get_tree().root
		var out_spawn = root.find_child("OutsideSpawn", true, false)
		var in_spawn = root.find_child("InsideSpawn", true, false)
		
		# If both exist, teleport to the one FURTHEST away (i.e. cross the threshold)
		if out_spawn and in_spawn:
			var dist_to_out = player.global_position.distance_to(out_spawn.global_position)
			var dist_to_in = player.global_position.distance_to(in_spawn.global_position)
			
			if dist_to_in < dist_to_out:
				# Player is currently inside, so teleport outside
				player.global_position = out_spawn.global_position
				player.global_rotation = out_spawn.global_rotation
			else:
				# Player is currently outside, so teleport inside
				player.global_position = in_spawn.global_position
				player.global_rotation = in_spawn.global_rotation
		elif out_spawn:
			# Fallback if only outside exists
			player.global_position = out_spawn.global_position
			player.global_rotation = out_spawn.global_rotation
			
		if cam: cam.position = original_cam_pos
	)
	
	stw.tween_interval(1.0) # Stay in black for impact
	
	# Fade back in
	stw.tween_property(fade_rect, "modulate:a", 0.0, 2.0)
	stw.tween_callback(func():
		var in_spawn = get_tree().root.find_child("InsideSpawn", true, false)
		var is_going_outside = true
		if in_spawn and player.global_position.distance_to(in_spawn.global_position) > 5.0:
			is_going_outside = true
		else:
			is_going_outside = false
			
		if player.has_method("show_subtitle"):
			if is_going_outside and not front_door_triggered:
				player.show_subtitle("Arang ngitngita uy.")
	)
	
	stw.tween_interval(3.0)
	stw.tween_callback(func():
		if not front_door_triggered and player.has_method("show_subtitle"):
			player.show_subtitle("Press [F] to open flashlight again.")
		player.in_cinematic = false
		if canvas: canvas.queue_free()
	)
	
	# Auto-hide the "Press F" hint
	stw.tween_interval(3.0)
	stw.tween_callback(func():
		if not front_door_triggered and player.has_method("hide_subtitle"):
			player.hide_subtitle()
			
		front_door_triggered = true
	)

func _play_level2_jake_arrival():
	var player = get_tree().root.find_child("Player", true, false)
	if not player: return
	
	player.in_cinematic = true
	
	# Play door creak sound immediately
	door_audio.pitch_scale = randfn(1.0, 0.1)
	door_audio.play()
	
	# Create fade to black UI dynamically
	var canvas = CanvasLayer.new()
	var fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.modulate.a = 0.0
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(fade_rect)
	add_child(canvas)
	
	var tw = create_tween()
	
	# Fast fade out
	tw.tween_property(fade_rect, "modulate:a", 1.0, 0.5)
	
	tw.tween_callback(func():
		var jake = get_tree().get_nodes_in_group("Jake").front()
		if jake:
			# Teleport Jake just inside the door
			jake.global_position = Vector3(-3.7, 0.1, 3.5)
			# Face the player (approximate inside rotation)
			jake.global_rotation = Vector3(0, PI, 0)
			
			if jake.has_method("enable_interaction"):
				jake.enable_interaction()
	)
	
	tw.tween_interval(1.0)
	
	# Fade back in
	tw.tween_property(fade_rect, "modulate:a", 0.0, 1.0)
	tw.tween_callback(func():
		var jake = get_tree().get_nodes_in_group("Jake").front()
		if not jake or not jake.get("is_in_cinematic"):
			player.in_cinematic = false
		canvas.queue_free()
	)
