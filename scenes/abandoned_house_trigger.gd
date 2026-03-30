extends Area3D

var manager = null
var triggered = false

var dialogue_inside = [
	"Jake: Niel... unsa gyud kana?",
	"Christian: Wala ko kabalo.",
	"Jake: Nganong gidalagan ta?",
	"Christian: Ang estranghero — naghisgot siya og uban. Nga nahibaw-an na nila.",
	"Jake: Nahibaw-an og unsa?",
	"Christian: Jake.",
	"Jake: Unsa?",
	"Christian: Tan-awa ni.",
	"Jake: Si Nanay nimo...? Nag-estar siya dinhi?",
	"Christian: Kini... kini dili si Tatay.",
	"Jake: Niel...",
	"Christian: Lahi ang tawo sa iyang kiliran.",
	"** ABRI SA BAUL **",
	"Jake: Niel... ang akong Tatay...",
	"Jake: Ang iyang ngalan... nagsugod og R.",
	"Christian: Nahibaw-an ko.",
	"Jake: Niel. Wala ko kabalo. Gisumpa ko sa Ginoo. Wala ko kabalo sa bisan unsa.",
	"Jake: Niel. Tan-awa ko. Palihug.",
	"Jake: Friends pa ba ta?"
]

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if triggered: return
	
	if not manager:
		manager = get_tree().root.find_child("Level2", true, false)
		
	if manager and manager.current_state == 8: # CHASE_SEQUENCE
		if body.name == "Player" or body.is_in_group("Player"):
			triggered = true
			manager.advance_story(9) # ABANDONED_HOUSE (Stops chase)
			_start_climax(body)

func _start_climax(player):
	if player.has_method("start_cinematic"):
		player.start_cinematic(self)
		
	for line in dialogue_inside:
		if player.has_method("show_subtitle"):
			player.show_subtitle(line)
			
		var t = 0.0
		var wait_time = 4.0 if "Baul" not in line else 2.0
		while t < wait_time:
			await get_tree().create_timer(0.1).timeout
			t += 0.1
			if Input.is_physical_key_pressed(KEY_SPACE):
				break
				
	if player.has_method("hide_subtitle"):
		player.hide_subtitle()
		
	show_final_choice(player)

func show_final_choice(player):
	# Create a simple Choice UI dynamically
	var canvas = CanvasLayer.new()
	var control = Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	
	var btn_a = Button.new()
	btn_a.text = "A) Tuo ko nimo Jake"
	btn_a.custom_minimum_size = Vector2(400, 80)
	btn_a.add_theme_font_size_override("font_size", 24)
	
	var btn_b = Button.new()
	btn_b.text = "B) Dili ko kahibalo Jake. Nagkinahanglan ko og panahon."
	btn_b.custom_minimum_size = Vector2(400, 80)
	btn_b.add_theme_font_size_override("font_size", 24)
	
	vbox.add_child(btn_a)
	vbox.add_child(btn_b)
	control.add_child(vbox)
	canvas.add_child(control)
	add_child(canvas)
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	btn_a.pressed.connect(func(): _on_choice_made(true, canvas, player))
	btn_b.pressed.connect(func(): _on_choice_made(false, canvas, player))

func _on_choice_made(chose_a: bool, canvas: CanvasLayer, player):
	canvas.queue_free()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if chose_a:
		print("Load Good Ending")
		get_tree().change_scene_to_file("res://scenes/ending_1.tscn")
	else:
		print("Load Sad Ending")
		get_tree().change_scene_to_file("res://scenes/ending_2.tscn")
