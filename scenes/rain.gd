extends GPUParticles3D

var player: Node3D = null

func _ready():
	player = get_tree().root.find_child("Player", true, false)
	emitting = true
	
	if player and player.has_method("show_subtitle"):
		player.show_subtitle("Christian: Hala, ga ulan na.")
		await get_tree().create_timer(3.0).timeout
		if player.has_method("hide_subtitle"):
			player.hide_subtitle()

func _process(_delta):
	if player:
		# Follow the player's XZ location, but stay high up above the roof
		global_position = Vector3(player.global_position.x, player.global_position.y + 15.0, player.global_position.z)
