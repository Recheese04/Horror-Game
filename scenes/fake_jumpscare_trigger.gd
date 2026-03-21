extends Area3D

@export var target_node: Node3D
@export var dialogue_text: String = "Oh, it's just you... Honey, you scared me, dear."
var triggered = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player" and not triggered:
		if is_instance_valid(target_node):
			triggered = true
			start_fake_jumpscare(body)
		else:
			print("Fake Jumpscare Error: target_node is Nil!")

func start_fake_jumpscare(player):
	print("Fake Jumpscare Triggered!")
	
	# Start intense music placeholder (could play a sound here)
	
	# Lock player into cinematic look
	if player.has_method("start_cinematic"):
		player.start_cinematic(target_node)
	
	await get_tree().create_timer(2.0).timeout
	
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
