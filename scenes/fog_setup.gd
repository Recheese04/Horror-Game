extends Node

# Attach this to the Level root node to force thick fog on at runtime.
# This bypasses any .tscn serialization issues.

func _ready():
	# Wait one frame to make sure WorldEnvironment is loaded
	await get_tree().process_frame
	
	var world_env = _find_world_env(get_tree().root)
	if not world_env:
		print("FogSetup: No WorldEnvironment found, creating one...")
		world_env = WorldEnvironment.new()
		world_env.environment = Environment.new()
		add_child(world_env)
	
	var env = world_env.environment
	if not env:
		env = Environment.new()
		world_env.environment = env
	
	# Force thick Patintero-style depth fog
	env.fog_enabled = true
	env.fog_light_color = Color(0.058, 0.058, 0.082, 1.0)
	env.fog_light_energy = 0.02
	env.fog_sun_scatter = 0.0
	env.fog_density = 0.25
	env.fog_sky_affect = 1.0
	env.fog_aerial_perspective = 1.0
	
	print("FogSetup: Thick fog activated!")

func _find_world_env(node: Node) -> WorldEnvironment:
	if node is WorldEnvironment:
		return node
	for child in node.get_children():
		var result = _find_world_env(child)
		if result:
			return result
	return null
