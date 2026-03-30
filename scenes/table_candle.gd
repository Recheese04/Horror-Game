extends StaticBody3D

@onready var candle_light = $OmniLight3D
@onready var candle_mesh = $CandleBody
@onready var fire_particles = $GPUParticles3D
@onready var v_indicator = $V_Indicator

var is_placed = false
var is_lit = false

func _ready():
	candle_mesh.hide()
	candle_light.hide()
	if v_indicator:
		v_indicator.hide()
	if fire_particles:
		fire_particles.emitting = false
	
	# Start disabled until Nanay says to light it
	process_mode = Node.PROCESS_MODE_DISABLED
	hide()
	add_to_group("Interactable")
	add_to_group("CandleSpots")

func enable_candle():
	show()
	process_mode = Node.PROCESS_MODE_INHERIT
	if v_indicator:
		v_indicator.show()


func get_interaction_prompt() -> String:
	if not is_placed:
		return "Ibutang ang kandila"
	if not is_lit:
		return "Sindihan ang kandila"
	return ""

func interact():
	var player = get_tree().root.find_child("Player", true, false)
	if not player: return
	
	if not is_placed:
		if InventoryManager.has_item("candle"):
			_place_candle(player)
		else:
			player.show_subtitle("Christian: Wala pa nako ang kandila.")
			_hide_sub_later(player)
		return
		
	if not is_lit:
		if InventoryManager.has_item("posporo"):
			_light_candle(player)
		else:
			player.show_subtitle("Christian: Kinahanglan nako ang posporo.")
			_hide_sub_later(player)

func _place_candle(player):
	is_placed = true
	candle_mesh.show()
	if v_indicator:
		v_indicator.hide()
	
	# Remove candle from inventory
	InventoryManager.remove_item("candle")
	
	player.show_subtitle("Christian: Okay, naa na ang kandila.")
	_hide_sub_later(player)

func _light_candle(player):
	is_lit = true
	candle_light.show()
	if fire_particles:
		fire_particles.emitting = true
		
	player.show_subtitle("Christian: Atay, hayag na.")
	_hide_sub_later(player)
	
	player.lit_candles += 1
	if player.has_method("show_objective"):
		if player.lit_candles >= 4:
			player.hide_objective()
		else:
			player.show_objective("Sindiha ang 4 ka kandila (" + str(player.lit_candles) + "/4)")
	_flicker()

func _hide_sub_later(player):
	var timer = get_tree().create_timer(2.5)
	timer.timeout.connect(func(): if player: player.hide_subtitle())

func _flicker():
	while is_lit:
		var target_energy = randf_range(0.8, 1.2)
		var tween = create_tween()
		tween.tween_property(candle_light, "light_energy", target_energy, randf_range(0.05, 0.15))
		await tween.finished
		await get_tree().create_timer(randf_range(0.01, 0.05)).timeout
