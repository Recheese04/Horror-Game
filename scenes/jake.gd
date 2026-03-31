extends CharacterBody3D

@onready var interaction_zone = $InteractionZone

var is_in_cinematic = false

var dialogue_arrival = [
	"Jake: NIEL! Nakabasa ka sa alert?",
	"Christian: Oo. Naa ko sa kalsada ana nga oras.",
	"Jake: NAKITA NIMO?!",
	"Christian: Ambot. Naay nakita ko pero—",
	"Jake: UNSAAAA?!",
	"Christian: Hilom! Si Nanay makabati.",
	"Jake: Niel. Naay bag-ong chismis. Naay estranghero nga nagpangutana kanimo.",
	"Christian: Pangutana nganong?",
	"Jake: Kung asa ka. Kung unsa imong hitsura. Kung kinsa imong Nanay.",
	"Christian: Kinsa siya?",
	"Jake: Nag-abang siya sa balay ni Nang Caring. Tulo ka adlaw na. Wala kabalo si Nang Caring kung kinsa."
]

var dialogue_sneak_out = [
	"Christian: Dili man mo tug an mama nako bai.",
	"Jake: Ngano kaha naa kaha gitaguan imo mama?",
	"Christian: Ambot laman bai, unya gabie mag investigate ta.",
	"Jake: Sge bai ingna lang ko."
]

var manager = null
var current_dialogue_state = 0 # 0 = Not intractable, 1 = Arrived, 2 = Following

func _ready():
	add_to_group("Jake")
	if interaction_zone:
		interaction_zone.body_entered.connect(_on_body_entered)

func enable_interaction():
	current_dialogue_state = 1
	add_to_group("Interactable")

func get_interaction_prompt() -> String:
	var state = get_level_state()
	if current_dialogue_state == 1:
		return "Talk to Jake"
	elif state == 5 and current_dialogue_state == 2:
		return "Go with Jake"
	return ""

func interact():
	var state = get_level_state()
	if current_dialogue_state == 1:
		var player = get_tree().root.find_child("Player", true, false)
		if player: _start_dialogue(player, dialogue_arrival)
		current_dialogue_state = 2
	elif state == 5 and current_dialogue_state == 2:
		var player = get_tree().root.find_child("Player", true, false)
		if player: _start_dialogue(player, dialogue_sneak_out)
		current_dialogue_state = 5

func get_level_state() -> int:
	if not manager:
		manager = get_tree().root.find_child("Level2", true, false)
	if manager and manager.has_method("advance_story"):
		return manager.current_state
	return -1

func _on_body_entered(body):
	if current_dialogue_state == 1:
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
		if lines == dialogue_arrival:
			manager.advance_story(4) # TALKED_TO_JAKE
		elif lines == dialogue_sneak_out:
			manager.advance_story(6) # SNEAKING_OUT
