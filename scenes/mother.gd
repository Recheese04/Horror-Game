extends CharacterBody3D

@export var is_return_interaction: bool = false

@onready var interaction_zone = $InteractionZone
@onready var voice_player = $VoicePlayer

const SPEED = 0.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var is_in_cinematic = false
var interaction_count = 0
var return_used = false

var dialogue_lines_intro = [
	"Christian. Pag adto sa tindahan ni Aling Rosa.",
	"Palit sag kandila ug posporo, ngitngit kaayo. Balik dayon ha.",
	"Ma, gabii na man. Mo-uwan pa.",
	"Kaduol ra anak. Lima minuto lang.",
	"(muttering) Kanunay na lang ko ang sugosugo...",
	"Uy. Nadunggan tika.",
	"Ang kwarta naa sa pitaka sa lamesa. Dali lang ha."
]

var dialogue_lines_return = [
	"Christian: Ma, naa na ang 4 ka kandila ug posporo.",
	"Nanay: Ikaw ra sindi ana kay gikapoy ko."
]

var dialogue_lines_sleep = [
	"Nanay: Hayag na. Maayong gabii Niel. Tug na.",
	"Christian: Sige Ma. Maayong gabii."
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
		if not return_used:
			return "Give candle and posporo to Nanay"
		var player = get_tree().root.find_child("Player", true, false)
		if player and player.lit_candles >= 4:
			return "Talk to Nanay (End Day 1)"
	return ""

func interact():
	if is_return_interaction:
		var player = get_tree().root.find_child("Player", true, false)
		if not player: return
		
		if not return_used:
			_start_dialogue(player, dialogue_lines_return)
		elif player.lit_candles >= 4:
			_start_dialogue(player, dialogue_lines_sleep)

func _on_body_entered(body):
	if is_return_interaction:
		return # Return interaction must be triggered manually via interact()
		
	if is_in_cinematic or interaction_count > 0:
		return
		
	if body.name == "Player" or body.is_in_group("Player"):
		_start_dialogue(body, dialogue_lines_intro)

func _start_dialogue(body, lines):
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
	
	# Play through dialogue one line at a time
	for line in lines:
		if body.has_method("show_subtitle"):
			body.show_subtitle(line)
			
		var t = 0.0
		while t < 3.5:
			await get_tree().create_timer(0.1).timeout
			t += 0.1
			if Input.is_physical_key_pressed(KEY_SPACE):
				break
	
	interaction_count += 1
		
	if body.has_method("hide_subtitle"):
		body.hide_subtitle()
		
	is_in_cinematic = false
	
	# Unlock player
	if body.has_method("end_cinematic"):
		body.end_cinematic()
	
	# Mark return interaction as used and hide prompt
	if is_return_interaction:
		return_used = true
	
	# Show objective after dialogue ends
	if body.has_method("show_objective"):
		if lines == dialogue_lines_sleep:
			# GO TO DAY 2
			get_tree().change_scene_to_file("res://level_2.tscn")
		elif lines == dialogue_lines_return:
			body.show_objective("Sindiha ang 4 ka kandila (0/4)")
			get_tree().call_group("CandleSpots", "enable_candle")
		elif lines == dialogue_lines_intro:
			body.show_objective("Kuhaa ang pitaka sa lamesa")
