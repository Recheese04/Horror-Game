@tool
extends Node3D

@export var wood_texture: Texture2D:
	set(value):
		wood_texture = value
		if is_inside_tree():
			_update_materials()

@export var wall_floor_texture: Texture2D:
	set(value):
		wall_floor_texture = value
		if is_inside_tree():
			_update_materials()

@export var roof_texture: Texture2D:
	set(value):
		roof_texture = value
		if is_inside_tree():
			_update_materials()

func _ready():
	_update_materials()

func _update_materials():
	# Wood (Posts and Stairs)
	var posts = get_node_or_null("Posts")
	var stairs = get_node_or_null("Stairs")
	if posts and posts.get_child_count() > 0:
		var base_mat = posts.get_child(0).material_override as StandardMaterial3D
		if base_mat:
			# Force a unique duplicate so updating one Kubo doesn't affect others!
			var new_mat = base_mat.duplicate()
			if wood_texture:
				new_mat.albedo_texture = wood_texture
			for child in posts.get_children():
				if child is CSGPrimitive3D:
					child.material_override = new_mat
			if stairs:
				for child in stairs.get_children():
					if child is CSGPrimitive3D:
						child.material_override = new_mat
						
	# Bamboo (Walls & Floor)
	var floor_node = get_node_or_null("Floor")
	var walls = get_node_or_null("Walls")
	if floor_node:
		var base_mat = floor_node.material_override as StandardMaterial3D
		if base_mat:
			var new_mat = base_mat.duplicate()
			if wall_floor_texture:
				new_mat.albedo_texture = wall_floor_texture
			floor_node.material_override = new_mat
			if walls:
				for child in walls.get_children():
					if child is CSGPrimitive3D:
						child.material_override = new_mat
						
	# Nipa (Roof)
	var roof = get_node_or_null("Roof")
	if roof and roof.get_child_count() > 0:
		var base_mat = roof.get_child(0).material_override as StandardMaterial3D
		if base_mat:
			var new_mat = base_mat.duplicate()
			if roof_texture:
				new_mat.albedo_texture = roof_texture
			for child in roof.get_children():
				if child is CSGPrimitive3D or child is CSGPolygon3D:
					child.material_override = new_mat
