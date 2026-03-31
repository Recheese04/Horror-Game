extends StaticBody3D

@export var max_bites: int = 3
var bites_left: int = 3
var manager = null
var initial_scale: Vector3

@onready var v_indicator = get_node_or_null("V_Indicator")

func _ready():
	add_to_group("Interactable")
	add_to_group("FoodItemsDay2")
	initial_scale = scale
	bites_left = max_bites
	
	if v_indicator:
		v_indicator.show()

func get_interaction_prompt() -> String:
	var state = get_level_state()
	if state == 1 and bites_left > 0:
		return "Kaon" # Eat
	return ""

func interact():
	var state = get_level_state()
	if state == 1 and bites_left > 0:
		bites_left -= 1
		
		# Shrink visually
		var tween = create_tween()
		tween.tween_property(self, "scale", initial_scale * (float(bites_left) / float(max_bites)), 0.2)
		
		var player = get_tree().root.find_child("Player", true, false)
		if player and player.has_method("show_subtitle"):
			player.show_subtitle("Yumm...")
			
		if bites_left == 0:
			if v_indicator:
				v_indicator.hide()
			collision_layer = 0
			collision_mask = 0
			visible = false
			_check_all_food_eaten()

func _check_all_food_eaten():
	var all_food = get_tree().get_nodes_in_group("FoodItemsDay2")
	var any_left = false
	for food in all_food:
		if food.get("bites_left") != null and food.bites_left > 0:
			any_left = true
			break
			
	if not any_left:
		await get_tree().create_timer(1.0).timeout
		var player = get_tree().root.find_child("Player", true, false)
		if player and player.has_method("show_subtitle"):
			player.show_subtitle("Busog nako. Salamat Ma!")
			
		# Stand up the player if they were sitting
		var chair = get_tree().root.find_child("Chair", true, false)
		if chair and chair.has_method("stand_up"):
			chair.stand_up()
			
		if not manager: manager = get_tree().root.find_child("Level2", true, false)
		if manager and manager.has_method("advance_story"):
			manager.advance_story(2) # FINISHED_EATING

func get_level_state() -> int:
	if not manager:
		manager = get_tree().root.find_child("Level2", true, false)
	if manager and manager.has_method("advance_story"):
		return manager.current_state
	return -1
