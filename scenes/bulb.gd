extends Node3D

@onready var light = $OmniLight3D
@onready var audio = $AudioStreamPlayer3D

@export var base_energy: float = 0.8

func _ready():
	light.light_energy = base_energy
	_disable_shadows(self)

func _disable_shadows(node: Node):
	if node is GeometryInstance3D:
		# Godot 4 constant for disabling shadows on a mesh!
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_disable_shadows(child)

func toggle():
	light.visible = not light.visible
	if audio.stream != null:
		audio.play()
