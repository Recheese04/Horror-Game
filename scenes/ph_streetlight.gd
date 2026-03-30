extends Node3D

@export var is_flickering: bool = true
@export var min_energy: float = 0.0
@export var max_energy: float = 1.5
@export var base_emission: float = 3.0
@export var flicker_speed_mult: float = 1.0

@onready var spot_light = $SpotLight3D
@onready var ambient_light = $OmniLight_Ambient
@onready var bulb = $StaticBody3D/Bulb

var flicker_timer: float = 0.0

func _ready():
	if bulb and bulb.material:
		bulb.material = bulb.material.duplicate()

func _process(delta):
	if not is_flickering:
		return
		
	flicker_timer -= delta * flicker_speed_mult
	if flicker_timer <= 0:
		if randf() > 0.4:
			# Turn on
			var intensity = randf_range(max_energy * 0.7, max_energy)
			if spot_light: spot_light.light_energy = intensity
			if ambient_light: ambient_light.light_energy = intensity * 0.2
			if bulb and bulb.material:
				bulb.material.emission_energy_multiplier = base_emission
			flicker_timer = randf_range(0.05, 1.5)
		else:
			# Flicker off/dim
			var intensity = randf_range(min_energy, min_energy + 0.1)
			if spot_light: spot_light.light_energy = intensity
			if ambient_light: ambient_light.light_energy = intensity * 0.2
			if bulb and bulb.material:
				bulb.material.emission_energy_multiplier = intensity
			flicker_timer = randf_range(0.02, 0.2)
