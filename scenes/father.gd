extends CharacterBody3D

@onready var interaction_zone = $InteractionZone
@onready var voice_player = $VoicePlayer

const SPEED = 0.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var is_in_cinematic = false
var interaction_count = 0

# The dialogue combined into one line
var dialogue_line = "Hoy buguk! Palit sag asin kaw."

func _ready():
	interaction_zone.body_entered.connect(_on_body_entered)

func _physics_process(delta):
	# Father is stationary again to avoid any lag
	if is_in_cinematic:
		# If somehow pushed, stop
		velocity = Vector3.ZERO
		move_and_slide()
		return
	
	if not is_on_floor():
		velocity.y -= gravity * delta
		move_and_slide()

func _on_body_entered(body):
	# If he already commanded or we are already talking, skip
	if is_in_cinematic or interaction_count > 0:
		return
		
	if body.name == "Player" or body.is_in_group("Player"):
		is_in_cinematic = true
		
		# Play the voice line
		if voice_player:
			voice_player.play()
		
		# Face the player
		var look_target = body.global_position
		look_target.y = global_position.y
		if global_position.distance_to(look_target) > 0.1:
			look_at(look_target, Vector3.UP)
		
		# Lock player into cinematic look
		if body.has_method("start_cinematic"):
			body.start_cinematic(self)
		
		# Show the combined single line of dialogue
		if body.has_method("show_subtitle"):
			body.show_subtitle(dialogue_line)
			await get_tree().create_timer(3.5).timeout
		
		interaction_count += 1
			
		if body.has_method("hide_subtitle"):
			body.hide_subtitle()
			
		is_in_cinematic = false
		
		# Unlock player
		if body.has_method("end_cinematic"):
			body.end_cinematic()
