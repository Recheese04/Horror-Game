extends Control

var lines = [
	"Jake: Niel. Palihug. Isulti nako ang tinuod.",
	"Christian: Dili ko kahibalo Jake. Nagkinahanglan ko og panahon.",
	"Jake: (steps back) Nagkinahanglan ka og panahon? Pagkahuman sa tanan natong naagian?",
	"Christian: Dili sayon Jake. Ang akong Tatay... ang imong Tatay...",
	"Jake: (tears in eyes) Abi nakog lahi ka. Abi nakog mas labaw ka kaysa sa imong dugo.",
	"Jake: Sige. Kung mao na imong gusto.",
	"Christian: Jake—",
	"Jake: Ayaw ko gukda Niel. Ayaw na gyud.",
	"...",
	"The next day.",
	"Christian walks alone on the road.",
	"The rain has stopped, but the ground is still wet.",
	"He looks at Jake's house. The lights are off.",
	"Christian: (whispers) Pasayloa ko Jake.",
	"NAG-INUSARA — END",
	"Usahay, ang pagpili sa husto — nagpasabot og pagpabilin nga mag-inusara."
]

var label: Label
var index = 0

func _ready():
	var bg = ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.05, 0.1, 1) # Darker/Blueish tint
	add_child(bg)
	
	label = Label.new()
	label.set_anchors_preset(PRESET_CENTER)
	label.add_theme_font_size_override("font_size", 48)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(800, 0)
	add_child(label)
	
	_next_line()

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_next_line()

func _next_line():
	if index >= lines.size():
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		return
	
	var txt = lines[index]
	label.text = txt
	
	var tween = create_tween()
	label.modulate.a = 0
	tween.tween_property(label, "modulate:a", 1.0, 1.0)
	
	index += 1
