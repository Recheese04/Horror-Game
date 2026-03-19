extends CharacterBody3D

@export var speed := 5.0
@export var jump_velocity := 4.0
@export var mouse_sensitivity := 0.002

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera: Camera3D = $Camera3D
var held_object: Node3D = null
@onready var interact_label: Label = $CanvasLayer/InteractLabel
@onready var interact_ray: RayCast3D = $Camera3D/InteractRay

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	interact_label.hide()

func _unhandled_input(event: InputEvent) -> void:
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
						phone.position = Vector3(0.3, -0.3, -0.6)
						phone.rotation = Vector3(PI/2, 0, 0)
						if phone is CSGBox3D: phone.use_collision = false
						held_object = phone
				# Door interaction (works whether or not holding something)
				if collider.name == "Door":
					var anim = collider.get_node_or_null("AnimationPlayer")
					if anim:
						if collider.get_meta("is_open", false):
							anim.play("door_close")
							collider.set_meta("is_open", false)
						else:
							anim.play("door_open")
							collider.set_meta("is_open", true)
		elif event.keycode == KEY_F and event.pressed and not event.echo:
			if held_object != null:
				var light = held_object.get_node("Flashlight")
				if light:
					light.visible = not light.visible

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle interact label
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider.name == "Door":
			interact_label.show()
		elif held_object == null and (collider.name == "cellphone" or (collider.get_parent() and collider.get_parent().name == "cellphone")):
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
