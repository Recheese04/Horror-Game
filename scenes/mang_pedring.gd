extends CharacterBody3D

@export var trigger_radius: float = 6.0
var triggered = false

func _ready():
	# Automatically create a trigger zone around Mang Pedring
	var area = Area3D.new()
	var coll = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = trigger_radius
	coll.shape = shape
	area.add_child(coll)
	add_child(area)
	
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player" and not triggered:
		triggered = true
		_start_dialogue(body)

# Disable manual interaction prompt since it's automatic now
func get_interaction_prompt() -> String:
	return ""

func interact():
	pass

func _start_dialogue(player):
	# Lock player and look at Mang Pedring
	player.in_cinematic = true
	player.cinematic_target = self
	
	var dialogue_lines = [
		{"speaker": "MP", "text": "Uy bata. Asa ka?"},
		{"speaker": "C", "text": "Tindahan lang Manong. Sugo ni Nanay."},
		{"speaker": "MP", "text": "Mag-amping ka ha. Lahi karon nga gabii."},
		{"speaker": "C", "text": "Lahi? Nganong lahi man Manong?"},
		{"speaker": "MP", "text": "..."}, 
		{"speaker": "C", "text": "Weird na pod na siya."}
	]
	
	for i in range(dialogue_lines.size()):
		var line = dialogue_lines[i]
		if player.has_method("show_subtitle"):
			player.show_subtitle(line["text"])
		
		# Wait loop with SPACE interrupt skip
		var wait_time = 3.5
		var elapsed = 0.0
		while elapsed < wait_time:
			await get_tree().create_timer(0.1).timeout
			elapsed += 0.1
			if Input.is_physical_key_pressed(KEY_SPACE):
				break
				
	if player.has_method("hide_subtitle"):
		player.hide_subtitle()
		
	# Unlock player securely so camera doesn't snap
	if player.has_method("end_cinematic"):
		player.end_cinematic()
	else:
		player.in_cinematic = false
		player.cinematic_target = null
	
	if player.has_method("show_objective"):
		player.show_objective("Adto sa tindahan ni Aling Rosa")
