extends StaticBody3D

@onready var interaction_zone = $InteractionZone
@onready var mesh_instance = $MeshInstance3D

var is_in_cinematic = false
var interaction_count = 0

var candle_scene = preload("res://scenes/candle.tscn")
var posporo_scene = preload("res://scenes/posporo.tscn")

# Suspense audio players
var suspense_audio: AudioStreamPlayer
var jumpscare_audio: AudioStreamPlayer

func _ready():
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
			set_meta("task_done", false)

func _on_body_entered(body):
	if interaction_count > 0:
		return
		
	if body.name == "Player" or body.is_in_group("Player"):
		interaction_count = 1
		_run_cinematic(body)

func _wait_or_skip(duration: float):
	var elapsed = 0.0
	while elapsed < duration:
		await get_tree().create_timer(0.1).timeout
		elapsed += 0.1
		if Input.is_physical_key_pressed(KEY_SPACE):
			# Small debounce for holding space
			await get_tree().create_timer(0.15).timeout
			break

func _run_cinematic(body):
	is_in_cinematic = true
	
	# -- SUSPENSE ATMOSPHERE --
	suspense_audio = AudioStreamPlayer.new()
	suspense_audio.stream = load("res://assets/sounds/234226__tyops__scary-environment.wav")
	suspense_audio.volume_db = -20.0
	suspense_audio.bus = "Master"
	get_tree().root.add_child(suspense_audio)
	suspense_audio.play()
	
	# Fade in suspense gradually
	var atw = create_tween()
	atw.tween_property(suspense_audio, "volume_db", -8.0, 4.0)
	
	# -- LINE 1: Christian calls out --
	if body.has_method("show_subtitle"):
		body.show_subtitle("Christian: Aling Rosa? Naa ka?")
	await _wait_or_skip(3.5)
	
	# -- LINE 2: Silence, then louder --
	if body.has_method("show_subtitle"):
		body.show_subtitle("Christian: Aling Rosaaaa?")
	await _wait_or_skip(3.0)
	
	if body.has_method("hide_subtitle"):
		body.hide_subtitle()
	await _wait_or_skip(0.5)
	
	# -- LOCK PLAYER into cinematic before jumpscare --
	if body.has_method("start_cinematic"):
		body.start_cinematic(self)
	
	# -- SUSPENSE BUILD: brief silence --
	await _wait_or_skip(1.0)
	
	# -- ALING ROSA POPS UP (jumpscare!) --
	mesh_instance.position = Vector3(0, -0.8, 0)
	mesh_instance.show()
	var tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(mesh_instance, "position", Vector3(0, 1.0, 0), 0.18)
	
	# Jumpscare sound
	jumpscare_audio = AudioStreamPlayer.new()
	jumpscare_audio.stream = load("res://assets/sounds/848150__torrent7x__jumpscare.wav")
	jumpscare_audio.volume_db = 0.0
	jumpscare_audio.bus = "Master"
	get_tree().root.add_child(jumpscare_audio)
	jumpscare_audio.play()
	
	# Fade suspense out after jumpscare
	var ftw = create_tween()
	ftw.tween_property(suspense_audio, "volume_db", -40.0, 3.0)
	ftw.tween_callback(func(): if suspense_audio: suspense_audio.queue_free())
	
	await _wait_or_skip(0.4)
	
	# -- ALING ROSA LINE --
	if body.has_method("show_subtitle"):
		body.show_subtitle("Aling Rosa: NAAAA!")
	await _wait_or_skip(2.5)
	
	# -- CHRISTIAN REACTION --
	if body.has_method("show_subtitle"):
		body.show_subtitle("Christian: AYYY! Susmaryosep!")
	await _wait_or_skip(3.0)
	
	# -- ALING ROSA LAUGHS --
	if body.has_method("show_subtitle"):
		body.show_subtitle("Aling Rosa: Hahaha! Ngano? Nahadlok ka?")
	await _wait_or_skip(3.5)
	
	# -- CHRISTIAN RECOVERS --
	if body.has_method("show_subtitle"):
		body.show_subtitle("Christian: Aling Rosa naman! Napalabog nimo akong kasingkasing!")
	await _wait_or_skip(4.5)
	
	# -- ALING ROSA RESTS --
	if body.has_method("show_subtitle"):
		body.show_subtitle("Aling Rosa: Nagpangita og lugar para matulog. Brownout man.")
	await _wait_or_skip(4.5)
	
	# -- CHRISTIAN BUYS --
	if body.has_method("show_subtitle"):
		body.show_subtitle("Christian: Paliton te upat ka kandila og posporo isa.")
	await _wait_or_skip(4.0)
	
	# -- ALING ROSA PAUSES, STUDIES CHRISTIAN --
	if body.has_method("show_subtitle"):
		body.show_subtitle("Aling Rosa: Anak ni Clara?")
	
	# Re-introduce suspense here — the story gets darker
	var suspense2 = AudioStreamPlayer.new()
	suspense2.stream = load("res://assets/sounds/234226__tyops__scary-environment.wav")
	suspense2.volume_db = -30.0
	suspense2.bus = "Master"
	get_tree().root.add_child(suspense2)
	suspense2.play()
	var stw2 = create_tween()
	stw2.tween_property(suspense2, "volume_db", -14.0, 3.0)
	
	await _wait_or_skip(4.0)
	
	# -- CHRISTIAN REPLIES --
	if body.has_method("show_subtitle"):
		body.show_subtitle("Christian: Oo. Anak ni Nanay Clara. Nganong?")
	await _wait_or_skip(4.0)
	
	# -- ALING ROSA — UNSETTLING PAUSE --
	if body.has_method("show_subtitle"):
		body.show_subtitle("Aling Rosa: Wala. Susama ra mo kaayo.")
	await _wait_or_skip(5.0)
	
	# -- SPAWN ITEMS ON COUNTER --
	_spawn_items()
	
	if body.has_method("show_subtitle"):
		body.show_subtitle("Aling Rosa: Mag-amping ha sa dalan. Ug—")
	await _wait_or_skip(3.5)
	
	# -- CHRISTIAN ASKS --
	if body.has_method("show_subtitle"):
		body.show_subtitle("Christian: Ug unsa Aling?")
	await _wait_or_skip(3.0)
	
	# -- ALING ROSA FORCES A SMILE --
	if body.has_method("show_subtitle"):
		body.show_subtitle("Aling Rosa: Balik dayon ha. Gabii na.")
	
	# Fade out 2nd suspense layer
	var etw = create_tween()
	etw.tween_property(suspense2, "volume_db", -40.0, 4.0)
	etw.tween_callback(func(): if suspense2: suspense2.queue_free())
	
	await _wait_or_skip(4.5)
	
	# -- FINAL WHISPER (monologue, player doesn't hear in-story) --
	if body.has_method("show_subtitle"):
		body.show_subtitle("Aling Rosa: (to herself) Ginoo ko. Susama jud kaayo.")
	await _wait_or_skip(5.0)
	
	# -- END CINEMATIC --
	if body.has_method("hide_subtitle"):
		body.hide_subtitle()
	
	is_in_cinematic = false
	if body.has_method("end_cinematic"):
		body.end_cinematic()
	
	set_meta("task_done", true)
	
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
			candle.global_position = global_position + forward * 1.0 + right * (i * 0.15 - 0.2) + Vector3(0, 1.0, 0)
	
	if posporo_scene:
		var posporo = posporo_scene.instantiate()
		level.add_child(posporo)
		posporo.global_position = global_position + forward * 1.0 + right * 0.4 + Vector3(0, 1.0, 0)
