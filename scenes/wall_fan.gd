extends Node3D

@export var blades_path: NodePath
@export var fan_head_path: NodePath
@export_enum("X", "Y", "Z") var spin_axis: String = "Z"

@export var is_on: bool = true
@export var spin_speed: float = 60.0
@export var shake_amount: float = 0.05
@export var shake_speed: float = 30.0

var blades: Node3D
var fan_head: Node3D
var time_passed: float = 0.0

func _ready():
	if not blades_path.is_empty():
		blades = get_node_or_null(blades_path)
	if not fan_head_path.is_empty():
		fan_head = get_node_or_null(fan_head_path)
		
	# Auto-find if we didn't specify paths
	if blades == null:
		blades = _find_node_by_keyword(self, ["blade", "propeller", "spin", "fanblade"])
	if fan_head == null:
		fan_head = _find_node_by_keyword(self, ["head", "motor", "pivot"])

func _find_node_by_keyword(node: Node, keywords: Array) -> Node:
	var lower_name = node.name.to_lower()
	for kw in keywords:
		if kw in lower_name:
			return node
	for child in node.get_children():
		var found = _find_node_by_keyword(child, keywords)
		if found: return found
	return null

func _process(delta):
	if is_on:
		if blades:
			var amount = -spin_speed * delta
			if spin_axis == "X": blades.rotate_x(amount)
			elif spin_axis == "Y": blades.rotate_y(amount)
			else: blades.rotate_z(amount)
		
		# Shake fan head rapidly
		if fan_head:
			time_passed += delta
			fan_head.rotation.x = sin(time_passed * shake_speed) * shake_amount
			fan_head.rotation.z = cos(time_passed * shake_speed * 1.3) * shake_amount
	else:
		# Settle down
		if fan_head:
			fan_head.rotation.x = lerp(fan_head.rotation.x, 0.0, 5.0 * delta)
			fan_head.rotation.z = lerp(fan_head.rotation.z, 0.0, 5.0 * delta)

func toggle():
	is_on = not is_on
