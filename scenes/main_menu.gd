extends Control

# This scene will fade into level_1.tscn when play is clicked.

@onready var start_button = $VBoxContainer/StartButton
@onready var settings_button = $VBoxContainer/SettingsButton

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)

func _on_start_pressed():
	# Transition to level 1
	var tween = create_tween()
	
	# Create a black overlay for transition out
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_preset(PRESET_FULL_RECT)
	add_child(overlay)
	
	tween.tween_property(overlay, "color:a", 1.0, 1.0)
	tween.tween_callback(func(): get_tree().change_scene_to_file("res://level_1.tscn"))

func _on_settings_pressed():
	print("Settings clicked - not implemented yet")
