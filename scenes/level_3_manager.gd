extends Node3D

enum StoryState {
	SNEAKING_OUT,
	TALKED_TO_MANG_PEDRING,
	EAVESDROPPING,
	CHASE_SEQUENCE,
	ABANDONED_HOUSE,
	FINAL_CHOICE
}

var current_state: int = StoryState.SNEAKING_OUT
var chase_timer: float = 0.0
var chase_active: bool = false
var footstep_stream: AudioStream

@onready var world_environment = $WorldEnvironment
@onready var directional_light = $DirectionalLight3D
@onready var player = $Player
@onready var audio_player = AudioStreamPlayer3D.new()

func _ready():
	print("LOG: Level 3 Started")
	add_child(audio_player)
	audio_player.bus = "Master"
	
	# Force night environment (VERY DARK)
	if directional_light:
		directional_light.light_energy = 0.01 # Extremely low light
		directional_light.light_color = Color(0.1, 0.15, 0.3) # Dark blue tint
	
	var we = get_node_or_null("WorldEnvironment")
	var cam = null
	if player:
		cam = player.get_node_or_null("Camera3D")
		call_deferred("_setup_level3_player")
	
	if we and we.environment:
		we.environment.background_mode = Environment.BG_COLOR
		we.environment.background_color = Color(0, 0, 0) # Pitch black sky
		we.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		we.environment.ambient_light_color = Color(0.01, 0.02, 0.05)
		we.environment.ambient_light_energy = 0.02 # Almost no ambient light
		
		we.environment.fog_enabled = true
		we.environment.fog_light_color = Color(0, 0, 0)
		we.environment.fog_density = 0.05
		if cam:
			cam.environment = we.environment
			
	var rain_sound = load("res://assets/sounds/321173__inspectorj__ambience-rain-heavy-a.wav")
	if rain_sound:
		audio_player.stream = rain_sound
		if rain_sound.has_method("set_loop"):
			rain_sound.loop = true
		elif "loop_mode" in rain_sound:
			rain_sound.loop_mode = 1
		audio_player.play()
		
func _setup_level3_player():
	if not player: return
	
	print("LOG: Setting up player for Level 3")
	player.global_position = Vector3(-3.7, 0.5, 6.0)
	player.rotation.y = PI # Face away from door
	
	# Force show CP and turn on flashlight
	var cp = player.get_node_or_null("Camera3D/CP")
	if cp:
		cp.show()
		player.held_object = cp
		var flashlight = cp.get_node_or_null("Flashlight")
		if flashlight:
			flashlight.show() # Automatically turn flashlight on!
		
		var fl_ui = cp.get_node_or_null("SubViewport/FlashlightUI")
		if fl_ui:
			fl_ui.texture = load("res://assets/images/flashlighton.jpg")
	
	player.show_objective("Pangitaa si Mang Pedring")
		
	# Seamless Fade In
	var canvas = CanvasLayer.new()
	var fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.modulate.a = 1.0 # Start fully black
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(fade_rect)
	add_child(canvas)
	
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 2.0).set_delay(1.0)
	tween.tween_callback(func(): fade_rect.queue_free())

func advance_story(new_state: int):
	current_state = new_state
	
	if current_state == StoryState.TALKED_TO_MANG_PEDRING:
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
