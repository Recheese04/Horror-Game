@tool
extends SceneTree

func _init():
	var packed_scene = ResourceLoader.load("res://models/wall_fan.glb")
	if packed_scene:
		var scene = packed_scene.instantiate()
		scene.print_tree_pretty()
	else:
		print("Failed to load wall_fan.glb")
	quit()
