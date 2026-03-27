extends StaticBody3D

var scene_path = "res://scenes/family_photo.tscn"

enum PhotoState { CLOSED, EXAMINING }
var state = PhotoState.CLOSED

func get_interaction_prompt() -> String:
	return "Examine Photo"

func get_examine_scale() -> float:
	return 0.3

func interact():
	if state != PhotoState.CLOSED:
		return
	
	state = PhotoState.EXAMINING
	var player = get_tree().root.find_child("Player", true, false)
	if player and player.has_method("start_examine"):
		player.start_examine(self)
		if player.has_method("update_examine_prompt"):
			player.update_examine_prompt("[Mouse] Rotate   |   [ESC] Back")

func cancel_examine(player):
	if state == PhotoState.EXAMINING:
		state = PhotoState.CLOSED
	player.end_examine()
