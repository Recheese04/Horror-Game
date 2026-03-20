extends CharacterBody3D

@export var walk_anim_name : String = "Walking"
@export var use_animations : bool = false

@onready var interaction_zone = $InteractionZone
@onready var mesh_pivot = $MeshScaleWrapper
@onready var anim_player : AnimationPlayer = find_animation_player(self)

func find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result = find_animation_player(child)
		if result: return result
	return null

const SPEED = 1.5
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
	
	if anim_player:
		var anims = anim_player.get_animation_list()
		print("Available animations: ", anims)
		
		# Robustly find the walking animation because FBX files randomly rename them!
		if not anim_player.has_animation(walk_anim_name):
			for a in anims:
				var an = a.to_lower()
				if "walk" in an or "run" in an or "macato" in an or "mixamo" in an or "armature" in an:
					walk_anim_name = a
					break
			if not anim_player.has_animation(walk_anim_name) and anims.size() > 0:
				for a in anims:
					if a != "RESET" and a != "default":
						walk_anim_name = a
						break
		
		# Delete the scale tracks from the FBX so it literally CANNOT shrink him!
		for anim_name in anims:
			var anim = anim_player.get_animation(anim_name)
			for i in range(anim.get_track_count() - 1, -1, -1):
				var path_str = str(anim.track_get_path(i))
				if "scale" in path_str or "Scale" in path_str:
					anim.remove_track(i)
		
		if use_animations and anim_player.has_animation(walk_anim_name):
			anim_player.get_animation(walk_anim_name).loop_mode = Animation.LOOP_LINEAR
			print("Successfully locked onto animation: ", walk_anim_name)
		else:
			print("Animations are currently disabled!")
		
		# Stop any animation at the start until he moves
		anim_player.stop()

func _physics_process(delta):
	if is_in_cinematic:
		velocity = Vector3.ZERO
		move_and_slide()
		if anim_player:
			anim_player.stop()
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
		
		# Softly rotate ONLY the mesh pivot, and flip it 180 degrees (PI) since the model is exported backwards
		var look_target = mesh_pivot.global_position + direction
		look_target.y = mesh_pivot.global_position.y
		if mesh_pivot.global_position.distance_to(look_target) > 0.1:
			var look_transform = mesh_pivot.global_transform.looking_at(look_target, Vector3.UP)
			look_transform = look_transform.rotated_local(Vector3.UP, PI)
			mesh_pivot.global_transform = mesh_pivot.global_transform.interpolate_with(look_transform, 5.0 * delta)
		
		if use_animations and anim_player and walk_anim_name != "" and anim_player.current_animation != walk_anim_name:
			anim_player.play(walk_anim_name)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
		if anim_player and anim_player.is_playing() and anim_player.current_animation == walk_anim_name:
			anim_player.stop()

	move_and_slide()

func _pick_new_target():
	var random_offset = Vector3(random.randf_range(-15, 15), 0, random.randf_range(-15, 15))
	target_position = global_position + random_offset
	move_timer = random.randf_range(2.0, 5.0)
	print("Macato picked new target: ", target_position, " - Starting to walk!")

func _on_body_entered(body):
	if body.name == "Player" and not is_in_cinematic:
		print("Player triggered Macato's dialog zone! He will stop and talk.")
		is_in_cinematic = true
		
		# Face the player using the mesh_pivot, and flip 180 degrees
		var look_target = body.global_position
		look_target.y = mesh_pivot.global_position.y
		if mesh_pivot.global_position.distance_to(look_target) > 0.1:
			mesh_pivot.look_at(look_target, Vector3.UP)
			mesh_pivot.rotate_object_local(Vector3.UP, PI)
		
		if anim_player:
			anim_player.stop()
		
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
					# If your player doesn't have subtitles yet, just wait 1 second total so he doesn't freeze forever!
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
		print("Macato finished talking! Resuming wander.")
		
		if body.has_method("end_cinematic"):
			body.end_cinematic()
