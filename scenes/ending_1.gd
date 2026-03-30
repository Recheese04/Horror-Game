extends Control

var lines = [
	"Ramon: Christian.",
	"Ramon: Ako si Ramon. Anak sa tawo nga nagpatay sa imong Tatay.",
	"Christian: (tense) Nganong naa ka dinhi?",
	"Ramon: Para protektahan ka. Ang akong Tatay — nag-order na siya.",
	"Jake: (steps forward) Ang imong Tatay — mao ba ang...",
	"Ramon: Oo. Ang iyang Tatay.",
	"Jake: Niel. Moadto ta sa pulis.",
	"Christian: Jake — ang imong Tatay...",
	"Jake: Nahibaw-an ko. Pero sayop ang iyang gibuhat. Ug kinahanglan nako buhaton ang husto.",
	"Christian: Sige. Adto ta.",
	"...",
	"Months later.",
	"Jake: Okay ra ka?",
	"Christian: Dili pa. Pero sige ra.",
	"Jake: Ako sad.",
	"Christian: Friends pa ba ta?",
	"Jake: (small smile) Tanga. Pirme.",
	"DUGO SA DUGO — END",
	"Ang dugo nagbugkos. Pero ang pagpili — mas kusgan."
]

var label: Label
var index = 0

func _ready():
	var bg = ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 1)
	add_child(bg)
	
	label = Label.new()
	label.set_anchors_preset(PRESET_CENTER)
	label.add_theme_font_size_override("font_size", 48)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	
	_next_line()

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_next_line()

func _next_line():
	if index >= lines.size():
		# Return to main menu
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		return
	
	var txt = lines[index]
	label.text = txt
	
	var tween = create_tween()
	label.modulate.a = 0
	tween.tween_property(label, "modulate:a", 1.0, 1.0)
	
	index += 1
