extends CharacterBody3D

@export var is_return_interaction: bool = false

@onready var interaction_zone = $InteractionZone
@onready var voice_player = $VoicePlayer

const SPEED = 0.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var is_in_cinematic = false
var interaction_count = 0

var dialogue_lines_intro = [
	"Nanay: Christian. Pag adto sa tindahan ni Aling Rosa. Wa tay asin ug posporo. Balik dayon.",
	"Christian: Ma gabii na man. Mo-uwan pa.",
	"Nanay: Kaduol ra. Dali lang anak.",
	"Nanay: Kuha og kwarta sa akong wallet."
]

var dialogue_lines_return = [
	"Christian: Ma, naa na ang 4 ka kandila ug posporo.",
	"Nanay: Ikaw ra sindi ana kay gikapoy ko."
]

func _ready():
	interaction_zone.body_entered.connect(_on_body_entered)
	add_to_group("Mothers")
	
	if is_return_interaction:
		add_to_group("Interactable")
		hide()
		process_mode = Node.PROCESS_MODE_DISABLED

func _physics_process(delta):
	if is_in_cinematic:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	
	if not is_on_floor():
		velocity.y -= gravity * delta
		move_and_slide()

func get_interaction_prompt() -> String:
	if is_return_interaction:
		return "Give candle and posporo to Nanay"
	return ""

func interact():
	if is_return_interaction:
		var player = get_tree().root.find_child("Player", true, false)
		if player:
			_start_dialogue(player)

func _on_body_entered(body):
	if is_return_interaction:
		return # Return interaction must be triggered manually via interact()
		
	if is_in_cinematic or interaction_count > 0:
		return
		
	if body.name == "Player" or body.is_in_group("Player"):
		_start_dialogue(body)

func _start_dialogue(body):
	is_in_cinematic = true
	
	# Play the voice line (only for Intro normally, but safe to play here too if generic)
	if voice_player and not is_return_interaction:
		voice_player.play()
	
	# Face the player
	var look_target = body.global_position
	look_target.y = global_position.y
	if global_position.distance_to(look_target) > 0.1:
		look_at(look_target, Vector3.UP)
	
	# Lock player into cinematic look
	if body.has_method("start_cinematic"):
		body.start_cinematic(self)
	
	# Determine which dialogue array to use
	var lines = dialogue_lines_return if is_return_interaction else dialogue_lines_intro
	
	# Play through dialogue one line at a time
	for line in lines:
		if body.has_method("show_subtitle"):
			body.show_subtitle(line)
		await get_tree().create_timer(3.5).timeout
	
	interaction_count += 1
		
	if body.has_method("hide_subtitle"):
		body.hide_subtitle()
		
	is_in_cinematic = false
	
	# Unlock player
	if body.has_method("end_cinematic"):
		body.end_cinematic()
	
	# Show objective after dialogue ends
	if body.has_method("show_objective"):
		if is_return_interaction:
			body.show_objective("Sindiha ang 4 ka kandila (0/4)")
			# ENABLE THE CANDLE PLACEMENT SPOT NOW
			get_tree().call_group("CandleSpots", "enable_candle")
		else:
			body.show_objective("Kuhaa ang pitaka sa lamesa")
