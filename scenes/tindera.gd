extends StaticBody3D

@onready var interaction_zone = $InteractionZone
@onready var mesh_instance = $MeshInstance3D

var is_in_cinematic = false
var interaction_count = 0

var candle_scene = preload("res://scenes/candle.tscn")
var posporo_scene = preload("res://scenes/posporo.tscn")

func _ready():
	# Tindera is initially hidden
	mesh_instance.hide()
	interaction_zone.body_entered.connect(_on_body_entered)
	interaction_zone.body_exited.connect(_on_body_exited)

func _on_body_exited(body):
	if body.name == "Player" or body.is_in_group("Player"):
		if has_meta("task_done") and get_meta("task_done") == true:
			var rain_scene = load("res://scenes/rain.tscn")
			if rain_scene:
				var rain = rain_scene.instantiate()
				get_tree().current_scene.add_child(rain)
			set_meta("task_done", false) # Ensure rain only triggers once

func _on_body_entered(body):
	if interaction_count > 0:
		return
		
	if body.name == "Player" or body.is_in_group("Player"):
		interaction_count = 1
		
		# 1. Player calls out, NOT locked in cinematic yet
		if body.has_method("show_subtitle"):
			body.show_subtitle("Christian: Ayooo. Ayooo. Ayooo.")
		
		# 2. Wait 6 seconds
		await get_tree().create_timer(6.0).timeout
		
		# 3. NOW start cinematic
		is_in_cinematic = true
		if body.has_method("start_cinematic"):
			body.start_cinematic(self)
		
		# 4. Tindera Jumpscare (pops up cleanly from crouching)
		mesh_instance.position = Vector3(0, -0.8, 0)
		mesh_instance.scale = Vector3(1, 1, 1)
		mesh_instance.show()
		
		var tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tween.tween_property(mesh_instance, "position", Vector3(0, 1.0, 0), 0.2)
		
		# Briefly wait for Tindera to "settle"
		await get_tree().create_timer(1.0).timeout
		
		# 4. Player asks to buy
		if body.has_method("show_subtitle"):
			body.show_subtitle("Christian: Paliton te upat ka kandila og posporo isa.")
			
		await get_tree().create_timer(4.0).timeout
		
		# 5. Tindera replies
		if body.has_method("show_subtitle"):
			body.show_subtitle("Tindera: Kani ra?")
			
		await get_tree().create_timer(3.5).timeout
		
		# 6. Tindera gives items (spawn them on the counter)
		_spawn_items()
			
		if body.has_method("hide_subtitle"):
			body.hide_subtitle()
			
		is_in_cinematic = false
		
		# Unlock player
		if body.has_method("end_cinematic"):
			body.end_cinematic()
		
		# Show objective to take the items
		if body.has_method("show_objective"):
			body.show_objective("Kuhaa ang kandila ug posporo")

func _spawn_items():
	var level = get_tree().current_scene
	
	var forward = -global_transform.basis.z.normalized()
	var right = global_transform.basis.x.normalized()
	
	if candle_scene:
		for i in range(4):
			var candle = candle_scene.instantiate()
			level.add_child(candle)
			# Spawn slightly above the counter (1.0) so they drop safely
			candle.global_position = global_position + forward * 1.0 + right * (i * 0.15 - 0.2) + Vector3(0, 1.0, 0)
	
	if posporo_scene:
		var posporo = posporo_scene.instantiate()
		level.add_child(posporo)
		# Spawn slightly to the right of the candle and above the counter
		posporo.global_position = global_position + forward * 1.0 + right * 0.4 + Vector3(0, 1.0, 0)

