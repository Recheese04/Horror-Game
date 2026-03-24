extends Node3D

@export var target_bulb_path: NodePath

func get_interaction_prompt() -> String:
	if not target_bulb_path.is_empty():
		var target = get_node_or_null(target_bulb_path)
		if target:
			if "is_on" in target:
				return "Turn Off" if target.is_on else "Turn On"
			elif target.has_node("OmniLight3D"):
				return "Turn Off" if target.get_node("OmniLight3D").visible else "Turn On"
	return "Use Switch"

func interact():
	print("Switch interacted!")
	if not target_bulb_path.is_empty():
		var target_bulb = get_node_or_null(target_bulb_path)
		if target_bulb:
			print("Found target bulb, toggling...")
			if target_bulb.has_method("toggle"):
				target_bulb.toggle()
			elif target_bulb.has_node("OmniLight3D"):
				var light = target_bulb.get_node("OmniLight3D")
				light.visible = not light.visible
		else:
			print("Target bulb not found!")
	else:
		print("Target bulb path is empty!")
