extends AnimatableBody3D

@onready var anim = $AnimationPlayer
@export var jumpscare_scene: PackedScene
var jumpscare_triggered = false
var door_audio: AudioStreamPlayer3D

func _ready():
	# Dynamically hook up the door creak sound effect
	door_audio = AudioStreamPlayer3D.new()
	door_audio.stream = load("res://assets/sounds/15419__pagancow__dorm-door-opening.wav")
	door_audio.max_distance = 15.0
	door_audio.bus = "Master"
	add_child(door_audio)

func interact():
	# Play the creaking sound effect immediately
	door_audio.pitch_scale = randfn(1.0, 0.1) # slight variation to sound organic
	door_audio.play()
	
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
