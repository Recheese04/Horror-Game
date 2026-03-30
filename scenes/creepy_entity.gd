extends Node3D

@export var disappear_distance: float = 12.0
var disappeared: bool = false
var is_gliding: bool = false
var glide_dir: Vector3 = Vector3.ZERO
var glide_spd: float = 0.0

func _ready():
	var area = $DisappearArea
	if area:
		area.body_entered.connect(_on_body_entered)
		# Update the actual collision shape size from the Inspector variable
		var coll = area.get_node_or_null("CollisionShape3D")
		if coll and coll.shape is SphereShape3D:
			coll.shape = coll.shape.duplicate()
			coll.shape.radius = disappear_distance

func _process(delta):
	# Slowly glide if instructed
	if is_gliding and not disappeared:
		global_position += glide_dir * glide_spd * delta

func start_gliding(direction: Vector3, speed: float):
	glide_dir = direction.normalized()
	glide_spd = speed
	is_gliding = true

func force_disappear():
	disappeared = true
	if has_node("Visuals"):
		$Visuals.hide()
	queue_free()

func _on_body_entered(body):
	if body.name == "Player" and not disappeared:
		force_disappear()
