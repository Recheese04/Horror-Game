extends CharacterBody3D

@export var interactable: bool = true

@onready var interaction_zone = $InteractionZone
@onready var voice_player = $VoicePlayer

const SPEED = 0.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var is_in_cinematic = false

var dialogue_morning = [
	"Christian: Maayong buntag Ma.",
	"Nanay: Maayong buntag. Kaon na. Luto na.",
	"Christian: Ma. Nahibaw-an nimo ang barangay alert kagahapon?",
	"Nanay: Oo. Mao nang dili ka angay mogawas sa gabii.",
	"Christian: Pero naa ko sa kalsada ana nga oras Ma.",
	"Nanay: Okay ra man ka diba? Nakabalik man ka."
]

var dialogue_asking = [
	"Christian: Ma. Naay estranghero nga nagpangutana nako. Nag-abang sa balay ni Nang Caring.",
	"Christian: Ma. Nahibaw-an nimo kung kinsa?",
	"Nanay: Ayaw tagda. Estranghero lang.",
	"Christian: Ma. Nganong pangutana siya nako specifically?",
	"Nanay: Ayaw og gawas karong gabii Christian. Promise ko.",
	"Christian: Ma—",
	"Nanay: Promise ko.",
	"Christian: ...Okay Ma. Promise."
]

var manager = null
var current_dialogue_state = 0 # 0 = Morning, 1 = Waiting, 2 = Asking, 3 = Done

func _ready():
	if interaction_zone:
		interaction_zone.body_entered.connect(_on_body_entered)
	add_to_group("Mothers")
	add_to_group("Interactable")
	
func get_interaction_prompt() -> String:
	var state = get_level_state()
	if state == 0 and current_dialogue_state == 0:
		return "Talk to Nanay"
	elif state == 3 and current_dialogue_state == 1:
		return "Pangutan-a si Nanay sa Estranghero"
	return ""

func _physics_process(delta):
	if is_in_cinematic:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	
	if not is_on_floor():
		velocity.y -= gravity * delta
		move_and_slide()

func interact():
	var state = get_level_state()
	
	if state == 0 and current_dialogue_state == 0:
		var player = get_tree().root.find_child("Player", true, false)
		if player: _start_dialogue(player, dialogue_morning)
		current_dialogue_state = 1
		
	elif state == 3 and current_dialogue_state == 1:
		var player = get_tree().root.find_child("Player", true, false)
		if player: _start_dialogue(player, dialogue_asking)
		current_dialogue_state = 3

func get_level_state() -> int:
	if not manager:
		manager = get_tree().root.find_child("Level2", true, false)
	if manager and manager.has_method("advance_story"):
		return manager.current_state
	return -1

func _on_body_entered(body):
	# Auto-trigger morning dialogue if they walk close enough
	var state = get_level_state()
	if state == 0 and current_dialogue_state == 0:
		if body.name == "Player" or body.is_in_group("Player"):
			interact()

func _start_dialogue(body, lines):
	is_in_cinematic = true
	
	var look_target = body.global_position
	look_target.y = global_position.y
	if global_position.distance_to(look_target) > 0.1:
		look_at(look_target, Vector3.UP)
	
	if body.has_method("start_cinematic"):
		body.start_cinematic(self)
	
	for line in lines:
		if body.has_method("show_subtitle"):
			body.show_subtitle(line)
			
		var t = 0.0
		while t < 3.5:
			await get_tree().create_timer(0.1).timeout
			t += 0.1
			if Input.is_physical_key_pressed(KEY_SPACE):
				break
				
	if body.has_method("hide_subtitle"):
		body.hide_subtitle()
		
	is_in_cinematic = false
	if body.has_method("end_cinematic"):
		body.end_cinematic()
		
	# Notify manager
	if manager and manager.has_method("advance_story"):
		if lines == dialogue_morning:
			manager.advance_story(1) # TALKED_TO_NANAY_MORNING
		elif lines == dialogue_asking:
			manager.advance_story(4) # ASKED_NANAY_ABOUT_STRANGER
