extends Area3D

@export var target_path: NodePath
var target_node: Node3D
@export var dialogue_text: String = "Oh, it's just you... Honey, you scared me, dear."
var triggered = false

func _ready():
	print("Fake Jumpscare Trigger Ready at ", global_position)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	print("Area3D Entered by: ", body.name)
	if body.name == "Player" and not triggered:
		if not target_node and not target_path.is_empty():
			target_node = get_node(target_path)
			
		if is_instance_valid(target_node):
			triggered = true
			start_fake_jumpscare(body)
		else:
			print("Fake Jumpscare Error: target_node is Nil! Path was: ", target_path)

func start_fake_jumpscare(player):
	print("Fake Jumpscare Cinematic Starting!")
	
	# Show the character sprite
	var sprite = target_node.get_node_or_null("CharacterSprite")
	if sprite:
		sprite.show()
	else:
		print("Fake Jumpscare Error: CharacterSprite not found in target!")
	
	# Play the intense sound
	var sfx = target_node.get_node_or_null("AudioStreamPlayer3D")
	if sfx:
		sfx.play()
	
	# Lock player into cinematic look
	if player.has_method("start_cinematic"):
		player.start_cinematic(target_node)
	
	# Reveal dialogue after a short delay
	await get_tree().create_timer(1.5).timeout
	
	# Play the voice dialogue
	var voice = target_node.get_node_or_null("VoicePlayer")
	if voice:
		voice.play()
	
	# Show dialogue
	if player.has_method("show_subtitle"):
		player.show_subtitle(dialogue_text)
	
	await get_tree().create_timer(3.0).timeout
	
	# End sequence
	if player.has_method("hide_subtitle"):
		player.hide_subtitle()
	
	if player.has_method("end_cinematic"):
		player.end_cinematic()
	
	# Optional: remove the trigger but keep the person
	# queue_free()
