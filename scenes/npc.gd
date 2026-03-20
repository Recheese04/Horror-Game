extends CharacterBody3D

@onready var interaction_zone = $InteractionZone

const SPEED = 1.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var is_in_cinematic = false
var target_position = Vector3.ZERO
var random = RandomNumberGenerator.new()
var move_timer = 0.0
var interaction_count = 0

var dialogue_lines = [
	"Who's there...?",
	"Did you hear that noise inside the walls?",
	"We shouldn't have come to this place.",
	"I feel like we are constantly being watched..."
]

func _ready():
	random.randomize()
	_pick_new_target()
	interaction_zone.body_entered.connect(_on_body_entered)

func _physics_process(delta):
	if is_in_cinematic:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	move_timer -= delta
	if move_timer <= 0:
		_pick_new_target()

	var direction = (target_position - global_position)
	direction.y = 0
	if direction.length() > 0.5:
		direction = direction.normalized()
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		# Softly rotate to face movement
		var look_target = global_position + direction
		look_target.y = global_position.y
		var look_transform = transform.looking_at(look_target, Vector3.UP)
		transform = transform.interpolate_with(look_transform, 5.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _pick_new_target():
	var random_offset = Vector3(random.randf_range(-4, 4), 0, random.randf_range(-4, 4))
	target_position = global_position + random_offset
	move_timer = random.randf_range(2.0, 5.0)

func _on_body_entered(body):
	if body.name == "Player" and not is_in_cinematic:
		# The user requested the NPC to strictly only interact ONE time forever.
		if interaction_count > 0:
			return
			
		is_in_cinematic = true
		
		# Face the player
		var look_target = body.global_position
		look_target.y = global_position.y
		look_at(look_target, Vector3.UP)
		
		# Lock player
		if body.has_method("start_cinematic"):
			body.start_cinematic(self)
		
		# Show full sequence of dialogue on first encounter, else short text
		if interaction_count == 0:
			for line in dialogue_lines:
				if body.has_method("show_subtitle"):
					body.show_subtitle(line)
					await get_tree().create_timer(3.0).timeout
				else:
					await get_tree().create_timer(0.2).timeout
		else:
			if body.has_method("show_subtitle"):
				body.show_subtitle("Leave me alone...")
				await get_tree().create_timer(2.0).timeout
			else:
				await get_tree().create_timer(0.5).timeout
			
		interaction_count += 1
			
		if body.has_method("hide_subtitle"):
			body.hide_subtitle()
			
		is_in_cinematic = false
		
		if body.has_method("end_cinematic"):
			body.end_cinematic()
