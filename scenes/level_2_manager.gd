extends Node3D

enum StoryState {
	MORNING_WAKEUP,
	TALKED_TO_NANAY_MORNING,
	JAKE_ARRIVED,
	TALKED_TO_JAKE,
	ASKED_NANAY_ABOUT_STRANGER,
	SNEAKING_OUT,
	TALKED_TO_MANG_PEDRING,
	EAVESDROPPING,
	CHASE_SEQUENCE,
	ABANDONED_HOUSE,
	FINAL_CHOICE
}

var current_state: int = StoryState.MORNING_WAKEUP
var chase_timer: float = 0.0
var chase_active: bool = false
var footstep_stream: AudioStream

@onready var world_environment = $WorldEnvironment
@onready var directional_light = $DirectionalLight3D
@onready var player = $Player
@onready var audio_player = AudioStreamPlayer3D.new()

func _ready():
	# Turn off all lightbulbs right at the start to ensure natural morning lighting
	var bulbs = get_tree().get_nodes_in_group("Bulbs")
	for b in bulbs:
		if b.has_method("turn_off"):
			b.turn_off()
			
	add_child(audio_player)
	audio_player.bus = "Master"
	# Position near the main door
	audio_player.global_position = Vector3(0, 1.5, 3.5) # Approximate door position
	
	# Disable global fog setup from Autoload so daytime appears correctly
	var fog_setup = get_tree().root.get_node_or_null("FogSetup")
	if fog_setup:
		var global_env = fog_setup.get_node_or_null("WorldEnvironment")
		if global_env:
			global_env.queue_free()
			
	# Explicitly attach our WorldEnvironment to the player's camera to guarantee Godot renders it
	var we = get_node_or_null("WorldEnvironment")
	var cam = null
	if player:
		cam = player.get_node_or_null("Camera3D")
	if we and we.environment and cam:
		cam.environment = we.environment
	
	# Basic lighting setup (User-preferred)
	if directional_light:
		directional_light.visible = true
		# Force the sun to point downwards so it's day (pitch -45, yaw -45)
		directional_light.rotation_degrees = Vector3(-45, -45, 0)
	
	# Wait a frame then start wake up logic
	call_deferred("_start_wakeup_sequence")

func _start_wakeup_sequence():
	if player:
		# Force hide the CP (phone) since the intro sequence no longer does this automatically
		var cp = player.get_node_or_null("Camera3D/CP")
		if cp:
			cp.hide()
			var flashlight = cp.get_node_or_null("Flashlight")
			if flashlight:
				flashlight.hide()
			if player.get("held_object") == cp:
				player.held_object = null
				
		_create_wake_up_eyelids(player)
		var camera = player.get_node_or_null("Camera3D")
		if camera:
			player.is_intro_playing = true
			player.in_cinematic = true
			if player.has_node("CanvasLayer/Crosshair"):
				player.get_node("CanvasLayer/Crosshair").hide()
			
			camera.position = Vector3(0, 0.3, 0)
			camera.rotation = Vector3(0.6, 0, 0)
			
			var tween = create_tween().set_parallel(true).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
			tween.tween_property(camera, "position", Vector3(0, 1.6, 0), 3.0).set_delay(2.5)
			tween.tween_property(camera, "rotation", Vector3(0, 0, 0), 3.0).set_delay(2.5)
			
			var slide_pos = player.global_position
			slide_pos.z += 1.0 # Slide off the bed slightly to avoid collision issues
			tween.tween_property(player, "global_position", slide_pos, 3.0).set_delay(2.5)
			
			tween.chain().tween_callback(func():
				player.is_intro_playing = false
				player.in_cinematic = false
				if player.has_node("CanvasLayer/Crosshair"):
					player.get_node("CanvasLayer/Crosshair").show()
				if player.has_method("show_objective"):
					player.show_objective("Pangitaa si Nanay sa sala")
			)
		else:
			if player.has_method("show_objective"):
				player.show_objective("Pangitaa si Nanay sa sala")

func _create_wake_up_eyelids(player):
	var canvas = player.get_node_or_null("CanvasLayer")
	if not canvas: return
		
	var screen_h = canvas.get_viewport().get_visible_rect().size.y
		
	var top_lid = ColorRect.new()
	top_lid.color = Color.BLACK
	top_lid.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(top_lid)
	
	var bot_lid = ColorRect.new()
	bot_lid.color = Color.BLACK
	bot_lid.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bot_lid)
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Opening eyes (blurred/slow)
	tween.tween_property(top_lid, "position:y", -screen_h * 0.8, 2.0)
	tween.tween_property(bot_lid, "position:y", screen_h * 0.8, 2.0)
	
	# Blink 1
	tween.chain().set_parallel(true).tween_property(top_lid, "position:y", -screen_h * 0.5, 0.4)
	tween.tween_property(bot_lid, "position:y", screen_h * 0.5, 0.4)
	tween.chain().set_parallel(true).tween_property(top_lid, "position:y", -screen_h * 1.5, 0.8)
	tween.tween_property(bot_lid, "position:y", screen_h * 1.5, 0.8)
	
	# Final cleanup
	tween.chain().tween_callback(func(): 
		top_lid.queue_free()
		bot_lid.queue_free()
	)

func advance_story(new_state: int):
	current_state = new_state
	
	if current_state == StoryState.TALKED_TO_NANAY_MORNING:
		# Nanay told the player to eat, door knock happens shortly after
		if player: player.show_objective("Kinsa nang nanuktok?")
		_trigger_jake_arrival()
		
	elif current_state == StoryState.TALKED_TO_JAKE:
		if player: player.show_objective("Pangutan-a si Nanay bahin sa estranghero")
		
	elif current_state == StoryState.ASKED_NANAY_ABOUT_STRANGER:
		if player: player.show_objective("Gawas kauban ni Jake")
		
	elif current_state == StoryState.SNEAKING_OUT:
		_transition_to_night()
		if player: player.show_objective("Pangitaa si Mang Pedring")

	elif current_state == StoryState.TALKED_TO_MANG_PEDRING:
		if player: player.show_objective("Adto sa balay ni Nang Caring")

	elif current_state == StoryState.CHASE_SEQUENCE:
		chase_active = true
		chase_timer = 0.0

	elif current_state == StoryState.ABANDONED_HOUSE:
		chase_active = false
		if player: player.show_objective("Susiha ang sulod sa balay")

func _process(delta):
	if chase_active:
		chase_timer += delta
		if chase_timer > 0.4:
			chase_timer = 0.0
			# Simulate heavy running/footstep logic
			# if footstep_stream: audio_player.play()
			# Alternatively rely on native footsteps scaled up.

func _trigger_jake_arrival():
	print("TRIGGER: Jake arrival starting...")
	# Play knock sound
	# Attempt to load the M4A or any knock sound found
	var knock_path = "res://assets/sounds/437589__wakaproduction2018__3-knock-101.m4a"
	if FileAccess.file_exists(knock_path):
		var knock_sound = load(knock_path)
		if knock_sound:
			audio_player.stream = knock_sound
			audio_player.play()
			print("SOUND: Knock played")
		else:
			print("ERROR: Knock sound failed to load as resource (may need editor reimport)")
	else:
		print("ERROR: Knock sound file not found at " + knock_path)
	
	await get_tree().create_timer(3.0).timeout
	var jake = get_tree().get_nodes_in_group("Jake").front()
	if jake:
		jake.enable_interaction()
		print("JAKE: Interaction enabled")

func _transition_to_night():
	if player:
		player.in_cinematic = true
		
	var canvas = CanvasLayer.new()
	var fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.modulate.a = 0.0
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(fade_rect)
	add_child(canvas)
	
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 2.0)
	
	tween.tween_callback(func():
		# The screen is now perfectly black so you can add subtitles or scenes later.
		# We'll also change the actual environment behind the scenes so whenever you DO fade back in, it will be night.
		if directional_light:
			directional_light.light_energy = 0.05
			directional_light.light_color = Color(0.2, 0.3, 0.5)
		
		var we = get_node_or_null("WorldEnvironment")
		if we and we.environment:
			we.environment.fog_enabled = true
			we.environment.ambient_light_energy = 0.1
			
		# Play rain sound
		var rain_sound = load("res://assets/sounds/321173__inspectorj__ambience-rain-heavy-a.wav")
		if rain_sound:
			audio_player.stream = rain_sound
			if rain_sound.has_method("set_loop"):
				rain_sound.loop = true
			elif "loop_mode" in rain_sound:
				rain_sound.loop_mode = 1
			audio_player.play()
	)
