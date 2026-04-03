extends CharacterBody3D

@onready var interaction_zone = get_node_or_null("InteractionZone")

var is_in_cinematic = false

var dialogue_day2 = [
	"Mang Pedring: Bata. Gisultihan na tika kagahapon.",
	"Christian: Manong. Unsa gyud ang imong buot ipasabot? Ang utang ni Tatay?",
	"Mang Pedring: Ang imong Tatay — namatay dili tungod sa sakit.",
	"Christian: Unsa...?",
	"Mang Pedring: Naay nakahibaw sa butang nga dili angay mahibaw-an.",
	"Jake: Manong unsa iyang nahibaw-an?",
	"Mang Pedring: Hinumdumi ang imong Tatay anak. Kung unsa siya.",
	"Jake: Unsa iyang buot ipasabot niana?",
	"Christian: Wala ko kabalo."
]

var manager = null
var current_dialogue_state = 0 # 0 = Not ready, 1 = Ready, 2 = Done

func _ready():
	if interaction_zone:
		interaction_zone.body_entered.connect(_on_body_entered)
	add_to_group("Interactable")

func get_interaction_prompt() -> String:
	var state = get_level_state()
	if state == 5 and current_dialogue_state == 0:
		return "Talk to Mang Pedring"
	return ""

func interact():
	var state = get_level_state()
	if state == 5 and current_dialogue_state == 0:
		var player = get_tree().root.find_child("Player", true, false)
		if player: _start_dialogue(player, dialogue_day2)
		current_dialogue_state = 1

func get_level_state() -> int:
	if not manager:
		manager = get_tree().root.find_child("Level2", true, false)
	if manager and manager.has_method("advance_story"):
		return manager.current_state
	return -1

func _on_body_entered(body):
	var state = get_level_state()
	if state == 5 and current_dialogue_state == 0:
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
		
	if manager and manager.has_method("advance_story"):
		manager.advance_story(6) # TALKED_TO_MANG_PEDRING
