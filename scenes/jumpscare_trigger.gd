extends Area3D

@export var jumpscare_scene : PackedScene

func _on_body_entered(body):
	if body.is_in_group("Player") or body.name == "Player":
		print("Jumpscare Triggered!")
		var jumpscare = jumpscare_scene.instantiate()
		get_tree().root.add_child(jumpscare)
		jumpscare.trigger()
		queue_free() # Only trigger once
