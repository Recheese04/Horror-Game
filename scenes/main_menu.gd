extends Control

# This scene will fade into level_1.tscn when play is clicked.

@onready var start_button = $VBoxContainer/StartButton
@onready var day_2_button = $VBoxContainer/Day2Button
@onready var settings_button = $VBoxContainer/SettingsButton

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	start_button.pressed.connect(_on_start_pressed)
	day_2_button.pressed.connect(_on_day2_pressed)
	settings_button.pressed.connect(_on_settings_pressed)

func _on_start_pressed():
	_transition_to_scene("res://level_1.tscn")

func _on_day2_pressed():
	_transition_to_scene("res://level_2.tscn")

func _transition_to_scene(scene_path: String):
	# Transition animation logic
	var tween = create_tween()
	
	# Create a black overlay for transition out
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_preset(PRESET_FULL_RECT)
	add_child(overlay)
	
	tween.tween_property(overlay, "color:a", 1.0, 1.0)
	tween.tween_callback(func(): get_tree().change_scene_to_file(scene_path))

func _on_settings_pressed():
	print("Settings clicked - not implemented yet")
