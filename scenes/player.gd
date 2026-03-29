extends CharacterBody3D

@export var speed := 3.0
@export var jump_velocity := 0.0
@export var mouse_sensitivity := 0.002

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera: Camera3D = $Camera3D
var held_object: Node3D = null
@onready var interact_label: Label = $CanvasLayer/InteractLabel
@onready var interact_ray: RayCast3D = $Camera3D/InteractRay
@onready var subtitle_label: Label = $CanvasLayer/SubtitleLabel
@onready var objective_label: Label = $CanvasLayer/ObjectiveLabel

var in_cinematic = false
var cinematic_target = null
var is_intro_playing = false

# Examine mode
var examining_object: Node3D = null
var examine_clone: Node3D = null
var is_examining = false

@onready var phone_3d: Node3D = $Camera3D/CP

var candles_count = 0
var lit_candles = 0
var has_posporo = false

func _ready() -> void:
	add_to_group("Player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	interact_label.hide()
	subtitle_label.hide()
	if objective_label: objective_label.hide()

func start_cinematic(target: Node3D):
	in_cinematic = true
	cinematic_target = target

func end_cinematic():
	in_cinematic = false
	cinematic_target = null
	# Smoothly reset camera to forward-facing
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(camera, "rotation", Vector3(0, 0, 0), 0.5)

func show_subtitle(text: String):
	subtitle_label.text = text
	subtitle_label.show()

func hide_subtitle():
	subtitle_label.hide()
	subtitle_label.text = ""

func show_objective(text: String):
	objective_label.text = "Sugu: " + text
	objective_label.show()

func hide_objective():
	objective_label.hide()

# ── EXAMINE MODE ─────────────────────────────────────────────────

var _flashlight_was_on: bool = false
var _examine_spot: OmniLight3D = null

func start_examine(original: Node3D):
	is_examining = true
	examining_object = original
	
	# Hide the original
	original.hide()
	
	# Disable collision on original
	if original is StaticBody3D:
		original.set_collision_layer(0)
		original.set_collision_mask(0)
	
	# Hide the phone (CP) so only the wallet is shown
	if phone_3d:
		phone_3d.hide()
	
	# Turn off flashlight if it's on
	if held_object and held_object.has_node("Flashlight"):
		var light = held_object.get_node("Flashlight")
		_flashlight_was_on = light.visible
		light.visible = false
	
	# Hide crosshair and objective during examine
	if has_node("CanvasLayer/Crosshair"):
		get_node("CanvasLayer/Crosshair").hide()
	if objective_label:
		objective_label.hide()
	interact_label.hide()
	
	# INSTEAD of using Godot's buggy duplicate(), we load a fresh instance from the file.
	# This guarantees the original object is completely untouched and never vanishes!
	var spawn_path = ""
	if "scene_path" in original:
		spawn_path = original.scene_path
	elif original.scene_file_path != "":
		spawn_path = original.scene_file_path
		
	if spawn_path != "":
		var scene = load(spawn_path)
		if scene:
			examine_clone = scene.instantiate()
		else:
			examine_clone = original.duplicate()
	else:
		examine_clone = original.duplicate()
		
	# Strip the script from the visual clone so it acts purely as a prop
	examine_clone.set_script(null)
	
	examine_clone.show()
	camera.add_child(examine_clone)
	examine_clone.position = Vector3(0, -0.05, -0.35)
	examine_clone.rotation = Vector3(0, 0, 0)
	
	if original.has_method("get_examine_scale"):
		examine_clone.scale = original.scale * original.get_examine_scale()
	else:
		examine_clone.scale = original.scale * 1.5
	
	# Disable collision on clone
	for child in examine_clone.get_children():
		if child is CollisionShape3D:
			child.disabled = true
	
	# Add a light attached to the camera (not the clone) so it stays stationary when rotating
	_examine_spot = OmniLight3D.new()
	_examine_spot.light_color = Color(1.0, 0.98, 0.95)
	_examine_spot.light_energy = 2.0
	_examine_spot.omni_range = 1.0
	_examine_spot.shadow_enabled = false
	_examine_spot.position = Vector3(0, -0.05, -0.1) # Just in front of camera
	camera.add_child(_examine_spot)
	
	# Prompt at top center
	if has_node("CanvasLayer/ExaminePromptLabel"):
		var prompt = get_node("CanvasLayer/ExaminePromptLabel")
		prompt.text = "[Mouse] Rotate   |   [ESC] Back   |   [E] Open"
		prompt.show()
	
	# Show cursor for rotating
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func update_examine_prompt(text: String):
	if has_node("CanvasLayer/ExaminePromptLabel"):
		get_node("CanvasLayer/ExaminePromptLabel").text = text

func end_examine():
	is_examining = false
	
	if examine_clone:
		examine_clone.queue_free()
		examine_clone = null
	
	# Show the original object again and restore its collision!
	if examining_object:
		examining_object.show()
		if examining_object is StaticBody3D:
			examining_object.set_collision_layer(1)
			examining_object.set_collision_mask(1)
	examining_object = null
	
	if _examine_spot:
		_examine_spot.queue_free()
		_examine_spot = null
	
	if has_node("CanvasLayer/ExaminePromptLabel"):
		get_node("CanvasLayer/ExaminePromptLabel").hide()
	
	# Show phone again
	if phone_3d:
		phone_3d.show()
	
	# Restore flashlight state
	if _flashlight_was_on and held_object and held_object.has_node("Flashlight"):
		held_object.get_node("Flashlight").visible = true
		_flashlight_was_on = false
	
	# Show crosshair
	if has_node("CanvasLayer/Crosshair"):
		get_node("CanvasLayer/Crosshair").show()
	
	examining_object = null
	interact_label.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	# During intro: allow looking around but block everything else
	if is_intro_playing:
		if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			# Save phone position so it stays still
			var phone_global = phone_3d.global_transform
			rotate_y(-event.relative.x * mouse_sensitivity)
			camera.rotate_x(-event.relative.y * mouse_sensitivity)
			camera.rotation.x = clamp(camera.rotation.x, -0.3, 1.2)
			# Restore phone so it doesn't move with the camera
			phone_3d.global_transform = phone_global
		return

	if in_cinematic:
		return
	
	# Examine mode input handling
	if is_examining:
		if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and examine_clone:
				examine_clone.rotate_y(-event.relative.x * 0.005)
				examine_clone.rotate_x(-event.relative.y * 0.005)
		elif event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_E:
				if examining_object and examining_object.has_method("examine_action"):
					examining_object.examine_action(self)
			elif event.keycode == KEY_ESCAPE:
				if examining_object and examining_object.has_method("cancel_examine"):
					examining_object.cancel_examine(self)
				else:
					end_examine()
		return
		
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -PI / 2, PI / 2)
	elif event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed and not event.echo:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif event.keycode == KEY_E and event.pressed and not event.echo:
			if interact_ray.is_colliding():
				var collider = interact_ray.get_collider()
				# Pick up cellphone (only if not already holding something)
				if held_object == null:
					var phone = null
					if collider.name == "cellphone":
						phone = collider
					elif collider.get_parent() and collider.get_parent().name == "cellphone":
						phone = collider.get_parent()
					if phone:
						phone.reparent(camera, false)
						phone.position = Vector3(0.07, -0.08, -0.15)
						phone.rotation = Vector3(0, 0, 0)
						if phone is CSGBox3D: phone.use_collision = false
						held_object = phone
				# Door interaction (works whether or not holding something)
				if collider.name == "Door":
					if collider.has_method("interact"):
						collider.interact()
					else:
						# Fallback for old/no script
						var anim = collider.get_node_or_null("AnimationPlayer")
						if anim:
							if collider.get_meta("is_open", false):
								anim.play("door_close")
								collider.set_meta("is_open", false)
							else:
								anim.play("door_open")
								collider.set_meta("is_open", true)
				elif collider.has_method("interact"):
					collider.interact()
				elif collider.get_parent() and collider.get_parent().has_method("interact"):
					collider.get_parent().interact()
		elif event.keycode == KEY_F and event.pressed and not event.echo:
			if held_object != null and held_object.has_node("Flashlight"):
				var light = held_object.get_node("Flashlight")
				light.visible = not light.visible
				# Update flashlight UI on phone screen
				var fl_ui = held_object.get_node_or_null("SubViewport/FlashlightUI")
				if fl_ui:
					if light.visible:
						fl_ui.texture = load("res://assets/images/flashlighton.jpg")
					else:
						fl_ui.texture = load("res://assets/images/flashlightoff.jpg")

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Block movement during examine
	if is_examining:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		move_and_slide()
		interact_label.hide()
		return

	if in_cinematic:
		# Stop walking
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		move_and_slide()
		
		# Smoothly rotate head to look at NPC face (approximate Y offset)
		if is_instance_valid(cinematic_target):
			var face_pos = cinematic_target.global_position + Vector3(0, 1.5, 0)
			var look_target = camera.global_transform.looking_at(face_pos, Vector3.UP)
			# Slerp the rotation basis specifically for much smoother results
			camera.global_transform.basis = camera.global_transform.basis.slerp(look_target.basis, 5.0 * delta)
		
		# Zoom FOV in
		camera.fov = lerp(camera.fov, 40.0, 3.0 * delta)
		
		interact_label.hide()
		return
		
	# Smoothly return FOV back to normal if escaping cinematic
	camera.fov = lerp(camera.fov, 75.0, 5.0 * delta)

	# Handle interact label
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if not is_instance_valid(collider):
			interact_label.hide()
			return
		
		var target = null
		
		# Find the actual interactive target (could be parent)
		if collider.has_method("interact"):
			target = collider
		elif collider.get_parent() and collider.get_parent().has_method("interact"):
			target = collider.get_parent()
		
		# Determine the label to show
		var label_text = ""
		
		if collider.name == "Door":
			label_text = "Open/Close"
		elif held_object == null and (collider.name == "cellphone" or (collider.get_parent() and collider.get_parent().name == "cellphone")):
			label_text = "Pick Up"
		elif target != null:
			if target.has_method("get_interaction_prompt"):
				label_text = target.get_interaction_prompt()
			else:
				label_text = "Interact"
				
		if label_text != "":
			interact_label.text = label_text
			interact_label.show()
		else:
			interact_label.hide()
	else:
		interact_label.hide()

	# Handle Jump.
	if Input.is_physical_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction.
	var input_dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_D):
		input_dir.x += 1
	if Input.is_physical_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_physical_key_pressed(KEY_S):
		input_dir.y += 1
	if Input.is_physical_key_pressed(KEY_W):
		input_dir.y -= 1
		
	input_dir = input_dir.normalized()
	
	# Handle movement
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
