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
	add_child(audio_player)
	audio_player.bus = "Master"
	# Position near the main door
	audio_player.global_position = Vector3(0, 1.5, 3.5) # Approximate door position
	
	# Basic lighting setup (User-preferred)
	if directional_light:
		directional_light.visible = true
	
	# Wait a frame then start wake up logic
	call_deferred("_start_wakeup_sequence")

func _start_wakeup_sequence():
	if player:
		_create_wake_up_eyelids(player)
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
	# Transition the lighting to night and add rain
	var tween = create_tween()
	if directional_light:
		tween.tween_property(directional_light, "light_energy", 0.05, 3.0)
		tween.parallel().tween_property(directional_light, "light_color", Color(0.2, 0.3, 0.5), 3.0)
	
	if world_environment and world_environment.environment:
		world_environment.environment.fog_enabled = true
		tween.parallel().tween_property(world_environment.environment, "ambient_light_energy", 0.1, 3.0)
	
	await tween.finished
	# Play rain sound
	var rain_sound = load("res://assets/sounds/321173__inspectorj__ambience-rain-heavy-a.wav")
	if rain_sound:
		audio_player.stream = rain_sound
		# In Godot 4, loop mode is set on the AudioStream resource itself, not the player.
		# For WAV files, it's .loop_mode. For MP3/Ogg, it's .loop.
		if rain_sound.has_method("set_loop"):
			rain_sound.loop = true
		elif "loop_mode" in rain_sound:
			rain_sound.loop_mode = 1 # LOOP_FORWARD
		
		audio_player.play()
	# Show rainy night elements here
