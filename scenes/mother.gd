extends CharacterBody3D

@onready var interaction_zone = $InteractionZone
@onready var voice_player = $VoicePlayer

const SPEED = 0.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var is_in_cinematic = false
var interaction_count = 0

# Dialogue sequence: [speaker, bisaya, english]
var dialogue_sequence = [
	["Nanay", "Christian. Pag adto sa tindahan ni Aling Rosa. Wa tay asin ug posporo. Balik dayon.", "Christian. Go to Aling Rosa's store. We're out of salt and matches. Come right back."],
	["Christian", "Ma gabii na man. Mo-uwan pa.", "Mom it's already night. And it's about to rain."],
	["Nanay", "Kaduol ra. Dali lang anak.", "It's close by. Just hurry, anak."],
]

func _ready():
	interaction_zone.body_entered.connect(_on_body_entered)

func _physics_process(delta):
	if is_in_cinematic:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	
	if not is_on_floor():
		velocity.y -= gravity * delta
		move_and_slide()

func _on_body_entered(body):
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
		
		# Play through the full dialogue sequence
		for entry in dialogue_sequence:
			var speaker = entry[0]
			var bisaya = entry[1]
			var english = entry[2]
			
			# Show Bisaya line with speaker name and English subtitle below
			var display_text = speaker + ": \"" + bisaya + "\"\n" + english
			
			if body.has_method("show_subtitle"):
				body.show_subtitle(display_text)
			
			# Wait based on line length (longer lines get more time)
			var wait_time = max(3.5, bisaya.length() * 0.04)
			await get_tree().create_timer(wait_time).timeout
		
		interaction_count += 1
			
		if body.has_method("hide_subtitle"):
			body.hide_subtitle()
			
		is_in_cinematic = false
		
		# Unlock player
		if body.has_method("end_cinematic"):
			body.end_cinematic()
		
		# Show objective after dialogue ends
		if body.has_method("show_objective"):
			body.show_objective("Kuhaa ang pitaka sa lamesa\n(Take the wallet on the table)")
