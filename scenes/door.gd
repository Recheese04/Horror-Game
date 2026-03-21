extends AnimatableBody3D

@onready var anim = $AnimationPlayer
@export var jumpscare_scene: PackedScene
var jumpscare_triggered = false

func interact():
	if get_meta("is_open", false):
		anim.play("door_close")
		set_meta("is_open", false)
	else:
		anim.play("door_open")
		set_meta("is_open", true)
		
		# Trigger jumpscare on first open if a scene is assigned
		if not jumpscare_triggered and jumpscare_scene:
			trigger_jumpscare()
			jumpscare_triggered = true

func trigger_jumpscare():
	print("Jumpscare Triggered from Door!")
	var jumpscare = jumpscare_scene.instantiate()
	get_tree().root.add_child(jumpscare)
	if jumpscare.has_method("trigger"):
		jumpscare.trigger()
