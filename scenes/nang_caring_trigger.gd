extends Area3D

var eavesdropping_dialogue = [
	"Jake: (whispers) Naa siya.",
	"Christian: (whispers) Paminaw ta.",
	"Nang Caring: Dugay ka nang nagpaabot ani.",
	"Stranger: Kinse anyos. Oo.",
	"Nang Caring: Sigurado ka nga siya?",
	"Stranger: Nakita na nako siya. Susama kaayo sa iyang Tatay.",
	"Nang Caring: Palihug. Bata pa siya. Wala siya kabalo sa bisan unsa.",
	"Stranger: Mao nang kinahanglan nako siya makit-an una sa uban.",
	"Nang Caring: Ang uban — nahibaw-an na nila?",
	"Stranger: Nahibaw-an na nila kagahapon. Mao nga—",
	"** Floorboard creaks from inside **",
	"Jake: Naay lain!",
	"Christian: DAGAN!"
]

var triggered = false
var manager = null

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if triggered: return
	
	if not manager:
		manager = get_tree().root.find_child("Level2", true, false)
	
	if manager and manager.current_state >= 6: # Need to have talked to Mang Pedring
		if body.name == "Player" or body.is_in_group("Player"):
			triggered = true
			_start_eavesdrop(body)

func _start_eavesdrop(player):
	if player.has_method("start_cinematic"):
		player.start_cinematic(self) # lock them looking at house
		
	for line in eavesdropping_dialogue:
		if player.has_method("show_subtitle"):
			player.show_subtitle(line)
			
		var t = 0.0
		# Wait slightly longer for big story beats
		while t < 4.0:
			await get_tree().create_timer(0.1).timeout
			t += 0.1
			if Input.is_physical_key_pressed(KEY_SPACE):
				break
				
	if player.has_method("hide_subtitle"):
		player.hide_subtitle()
		
	if player.has_method("end_cinematic"):
		player.end_cinematic()
		
	# Trigger the chase!
	if manager and manager.has_method("advance_story"):
		manager.advance_story(8) # CHASE_SEQUENCE
		
	if player.has_method("show_objective"):
		player.show_objective("DAGAN! PANGITAA ANG DAAN NGA BALAY!")
