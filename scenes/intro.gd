extends Node

# Self-contained intro cutscene controller
# Uses the 3D CP (cellphone) model from player's Camera3D

var player: CharacterBody3D
var camera: Camera3D
var phone_3d: Node3D

# UI references
var canvas_layer: CanvasLayer
var dark_overlay: ColorRect
var subtitle_label: Label

var _is_skipping: bool = false
var _active_tweens: Array[Tween] = []

func _ready():
	player = get_tree().root.find_child("Player", true, false)
	if not player:
		push_error("Intro: Player not found!")
		queue_free()
		return
	camera = player.get_node("Camera3D")
	phone_3d = camera.get_node("CP")
	
	# Disable player movement
	player.is_intro_playing = true
	player.in_cinematic = true
	if player.has_node("CanvasLayer/Crosshair"):
		player.get_node("CanvasLayer/Crosshair").hide()
	
	# Show the 3D phone and position it in front of face (laying down view)
	phone_3d.show()
	phone_3d.position = Vector3(0, -0.02, -0.22)
	phone_3d.rotation = Vector3(-0.57, 0, 0)
	phone_3d.get_node("Screen").show()
	
	# Position camera at bed level, looking up slightly
	camera.position = Vector3(0, 0.3, 0)
	camera.rotation = Vector3(0.6, 0, 0)
	
	_build_ui()
	
	# Small hint for skipping in debug builds
	if OS.is_debug_build():
		print("DEBUG: Press SPACE/ESC to skip intro")
		
	_start_sequence()

func _input(event):
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
		if not _is_skipping:
			_instant_skip()

func _add_tween(tween: Tween) -> Tween:
	_active_tweens.append(tween)
	tween.finished.connect(func(): _active_tweens.erase(tween))
	return tween

func _build_ui():
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10
	add_child(canvas_layer)
	
	# Dark overlay (starts fully black for fade-in)
	dark_overlay = ColorRect.new()
	dark_overlay.color = Color(0, 0, 0, 1)
	dark_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	dark_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_layer.add_child(dark_overlay)
	
	# Subtitle label (hidden initially)
	subtitle_label = Label.new()
	subtitle_label.text = ""
	subtitle_label.add_theme_font_size_override("font_size", 28)
	subtitle_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	subtitle_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	subtitle_label.add_theme_constant_override("shadow_offset_x", 2)
	subtitle_label.add_theme_constant_override("shadow_offset_y", 2)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	subtitle_label.offset_top = -100
	subtitle_label.offset_bottom = -40
	subtitle_label.modulate.a = 0
	canvas_layer.add_child(subtitle_label)

# ── SEQUENCE ─────────────────────────────────────────────────────

func _start_sequence():
	if _is_skipping: return
	
	# Hide the manual Facebook UI immediately - we only use the video
	var ui_control = phone_3d.get_node_or_null("SubViewport/Control")
	if ui_control: ui_control.hide()
	
	# Start video immediately (plays under the fade-in)
	var video_player = phone_3d.get_node_or_null("SubViewport/VideoPlayer")
	if video_player and video_player.stream:
		video_player.volume_db = -15.0
		video_player.play()
	
	# Fade in from black
	var fade_in = _add_tween(create_tween())
	fade_in.tween_property(dark_overlay, "color:a", 0.0, 5.0)
	await fade_in.finished
	if _is_skipping: return
	
	# Wait 25 seconds then trigger brownout
	var timer = get_tree().create_timer(25.0)
	await timer.timeout
	if _is_skipping: return
	
	_trigger_brownout()

func _instant_skip():
	_is_skipping = true
	print("Intro: Skipping sequence...")
	
	# Kill all active tweens
	for t in _active_tweens:
		if t and t.is_valid():
			t.kill()
	_active_tweens.clear()
	
	# Instantly perform world changes that happen during brownout
	get_tree().call_group("Bulbs", "turn_off")
	get_tree().call_group("Electronics", "turn_off")
	var dir_light = get_tree().root.find_child("DirectionalLight3D", true, false)
	if dir_light:
		dir_light.visible = false
	
	# Ensure overlay is gone
	if dark_overlay:
		dark_overlay.color.a = 0.0
	
	# Final standing position for camera and phone
	camera.position = Vector3(0, 1.6, 0)
	camera.rotation = Vector3(0, 0, 0)
	
	_end_intro()

func _trigger_brownout():
	# CP stays on during brownout - don't hide the screen
	
	# Lock camera so player can't look around during brownout sequence
	player.in_cinematic = true
	
	# Flash a brief black overlay
	dark_overlay.color = Color(0, 0, 0, 1.0)
	
	# Turn off all lights
	get_tree().call_group("Bulbs", "turn_off")
	# Turn off TV, VCD, and other electronics
	get_tree().call_group("Electronics", "turn_off")
	# Stop the fan
	get_tree().call_group("Fans", "turn_off")
	var dir_light = get_tree().root.find_child("DirectionalLight3D", true, false)
	if dir_light:
		dir_light.visible = false
	
	# Brief pause in total darkness
	await get_tree().create_timer(0.5).timeout
	
	# Fade out the dark overlay to reveal the pitch-black 3D world
	var fade = create_tween()
	fade.tween_property(dark_overlay, "color:a", 0.0, 1.0)
	
	# Lower the phone out of view
	var phone_drop = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	phone_drop.tween_property(phone_3d, "position", Vector3(0.1, -0.5, -0.15), 0.8)
	
	await fade.finished
	_look_at_bulb()

func _look_at_bulb():
	var bulb = get_tree().root.find_child("Bulb2", true, false)
	if bulb:
		var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		var target = camera.global_transform.looking_at(bulb.global_position, Vector3.UP)
		tween.tween_property(camera, "global_transform:basis", target.basis, 1.5)
		await tween.finished
	
	# Show Bisaya subtitle
	subtitle_label.text = "Atay... brownout."
	var sub_in = create_tween()
	sub_in.tween_property(subtitle_label, "modulate:a", 1.0, 0.5)
	
	# Hold for 3 seconds
	await get_tree().create_timer(3.0).timeout
	
	# Fade out subtitle
	var sub_out = create_tween()
	sub_out.tween_property(subtitle_label, "modulate:a", 0.0, 0.5)
	await sub_out.finished
	
	if _is_skipping: return
	
	# Allow player to look around again after 1 second
	await get_tree().create_timer(1.0).timeout
	player.in_cinematic = false
	
	_rain_and_dialogue()

func _show_subtitle(text: String, duration: float):
	if _is_skipping: return
	subtitle_label.text = text
	var sub_in = create_tween()
	sub_in.tween_property(subtitle_label, "modulate:a", 1.0, 0.5)
	await sub_in.finished
	if _is_skipping: return
	await get_tree().create_timer(duration).timeout
	if _is_skipping: return
	var sub_out = create_tween()
	sub_out.tween_property(subtitle_label, "modulate:a", 0.0, 0.5)
	await sub_out.finished

func _rain_and_dialogue():
	if _is_skipping: return
	# Look at ceiling (straight up)
	var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(camera, "rotation", Vector3(1.0, 0, 0), 2.0)
	await tween.finished
	
	if _is_skipping: return
	await _show_subtitle("[Sound of rain starting outside...]", 3.0)
	if _is_skipping: return
	
	_stand_up()

func _stand_up():
	var tween = create_tween().set_parallel(true).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	# Rise from bed to standing height
	tween.tween_property(camera, "position", Vector3(0, 1.6, 0), 2.0)
	tween.tween_property(camera, "rotation", Vector3(0, 0, 0), 2.0)
	# Bring phone back into held position
	tween.tween_property(phone_3d, "position", Vector3(0.07, -0.08, -0.15), 2.0)
	tween.tween_property(phone_3d, "rotation", Vector3(0, 0, 0), 2.0)
	await tween.finished
	
	_end_intro()

func _end_intro():
	player.is_intro_playing = false
	player.in_cinematic = false
	if player.has_node("CanvasLayer/Crosshair"):
		player.get_node("CanvasLayer/Crosshair").show()
	
	# Set phone to final held position
	phone_3d.show()
	phone_3d.position = Vector3(0.07, -0.08, -0.15)
	phone_3d.rotation = Vector3(0, 0, 0)
	phone_3d.get_node("Screen").show()
	player.held_object = phone_3d
	
	# Stop the video and show flashlight UI on phone screen
	var video_player = phone_3d.get_node_or_null("SubViewport/VideoPlayer")
	if video_player:
		video_player.stop()
		video_player.hide()
	
	# Hide the scroll UI
	var ui_control = phone_3d.get_node_or_null("SubViewport/Control")
	if ui_control:
		ui_control.hide()
	
	# Show flashlight off image on the phone screen initially
	var flashlight_ui = TextureRect.new()
	flashlight_ui.name = "FlashlightUI"
	flashlight_ui.texture = load("res://assets/images/flashlightoff.jpg")
	flashlight_ui.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	flashlight_ui.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	flashlight_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	phone_3d.get_node("SubViewport").add_child(flashlight_ui)
	
	# Turn on the 3D flashlight automatically
	# (Removed based on user feedback: let the player turn it on)
	
	# Show flashlight hint
	var hint = Label.new()
	hint.text = "Press F to toggle flashlight"
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	hint.add_theme_constant_override("shadow_offset_x", 1)
	hint.add_theme_constant_override("shadow_offset_y", 1)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.offset_top = -60
	hint.offset_bottom = -30
	hint.offset_left = -200
	hint.offset_right = 200
	hint.modulate.a = 0
	canvas_layer.add_child(hint)
	
	var hint_in = create_tween()
	hint_in.tween_property(hint, "modulate:a", 1.0, 0.5)
	await hint_in.finished
	await get_tree().create_timer(4.0).timeout
	var hint_out = create_tween()
	hint_out.tween_property(hint, "modulate:a", 0.0, 1.0)
	await hint_out.finished
	
	
	
	queue_free()
