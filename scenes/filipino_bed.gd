extends Node3D

var interaction_count = 0

func _ready():
	add_to_group("Interactable")
	if has_node("V_Indicator"):
		$V_Indicator.hide()

func _process(delta):
	if interaction_count == 0:
		var player = get_tree().root.find_child("Player", true, false)
		if player and player.lit_candles >= 4:
			if has_node("V_Indicator") and not $V_Indicator.visible:
				$V_Indicator.show()

func get_interaction_prompt() -> String:
	if interaction_count == 0:
		return "[E] Matulog (Go to bed)"
	return ""

func interact():
	if interaction_count > 0:
		return
		
	var player = get_tree().root.find_child("Player", true, false)
	if player and player.lit_candles >= 4:
		interaction_count += 1
		var v_ind = get_node_or_null("V_Indicator")
		if v_ind: v_ind.hide()
		_start_sleeping_cinematic(player)
	elif player:
		if player.has_method("show_subtitle"):
			player.show_subtitle("Christian: Dili pa ko duka. Naa pa koy buhaton.\n(I'm not sleepy yet.)")
			var timer = get_tree().create_timer(3.0)
			timer.timeout.connect(func(): if is_instance_valid(player) and player.has_method("hide_subtitle"): player.hide_subtitle())

func _start_sleeping_cinematic(player):
	if player.has_method("start_cinematic"):
		player.start_cinematic(self)
	
	if player.has_method("hide_objective"):
		player.hide_objective()
	
	# Play suspense subtle audio
	var audio = AudioStreamPlayer.new()
	audio.stream = load("res://assets/sounds/234226__tyops__scary-environment.wav")
	audio.volume_db = -15.0
	get_tree().root.add_child(audio)
	audio.play()
	
	# Lay down animation: Rotate camera up, move down to bed level
	var cam = player.get_node_or_null("Camera3D")
	if cam:
		var target_pos = global_position + Vector3(0, 0.4, 0)
		var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		# Move player slowly to lay on bed
		tween.tween_property(player, "global_position", target_pos, 2.0)
		
		# Camera rotates to look slightly at ceiling and side (like laying on pillow)
		tween.tween_property(cam, "rotation_degrees:x", 65.0, 2.5)
		tween.tween_property(cam, "rotation_degrees:y", 20.0, 2.5)
		tween.tween_property(cam, "rotation_degrees:z", -15.0, 2.5)
		
		# Turn off flashlight if on
		if player.held_object and player.held_object.has_node("Flashlight"):
			player.held_object.get_node("Flashlight").visible = false
			
		await get_tree().create_timer(3.0).timeout
		
		# Close eyes animation
		_create_eyelids(player)

func _create_eyelids(player):
	var canvas = player.get_node_or_null("CanvasLayer")
	if not canvas:
		return
		
	var screen_h = canvas.get_viewport().get_visible_rect().size.y
		
	var top_lid = ColorRect.new()
	top_lid.color = Color.BLACK
	top_lid.set_anchors_preset(Control.PRESET_FULL_RECT)
	top_lid.position.y = -screen_h
	canvas.add_child(top_lid)
	
	var bot_lid = ColorRect.new()
	bot_lid.color = Color.BLACK
	bot_lid.set_anchors_preset(Control.PRESET_FULL_RECT)
	bot_lid.position.y = screen_h
	canvas.add_child(bot_lid)
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Blink 1 (Heavy eyes)
	tween.tween_property(top_lid, "position:y", -screen_h * 0.7, 1.2)
	tween.tween_property(bot_lid, "position:y", screen_h * 0.7, 1.2)
	tween.chain().set_parallel(true).tween_property(top_lid, "position:y", -screen_h * 0.9, 0.5)
	tween.tween_property(bot_lid, "position:y", screen_h * 0.9, 0.5)
	
	# Blink 2 (Heavier)
	tween.chain().set_parallel(true).tween_property(top_lid, "position:y", -screen_h * 0.4, 1.2)
	tween.tween_property(bot_lid, "position:y", screen_h * 0.4, 1.2)
	tween.chain().set_parallel(true).tween_property(top_lid, "position:y", -screen_h * 0.7, 0.5)
	tween.tween_property(bot_lid, "position:y", screen_h * 0.7, 0.5)
	
	# Final close
	tween.chain().set_parallel(true).tween_property(top_lid, "position:y", 0.0, 2.5)
	tween.tween_property(bot_lid, "position:y", 0.0, 2.5)
