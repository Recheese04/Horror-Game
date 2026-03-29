extends CanvasLayer

var is_open := false
var _pickup_tween: Tween = null
var _rotators: Array[Node3D] = []
var current_index: int = 0

@onready var background: ColorRect = $Background
@onready var panel: Control = $CenterContainer/Panel
@onready var empty_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/EmptyLabel
@onready var title_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var pickup_notification: Label = $PickupNotification

@onready var prev_slot = $CenterContainer/Panel/MarginContainer/VBoxContainer/CarouselHBox/PrevSlot
@onready var center_slot = $CenterContainer/Panel/MarginContainer/VBoxContainer/CarouselHBox/CenterSlot
@onready var next_slot = $CenterContainer/Panel/MarginContainer/VBoxContainer/CarouselHBox/NextSlot
@onready var left_btn = $CenterContainer/Panel/MarginContainer/VBoxContainer/CarouselHBox/LeftBtn
@onready var right_btn = $CenterContainer/Panel/MarginContainer/VBoxContainer/CarouselHBox/RightBtn
@onready var item_name = $CenterContainer/Panel/MarginContainer/VBoxContainer/DetailsVBox/ItemName
@onready var item_desc = $CenterContainer/Panel/MarginContainer/VBoxContainer/DetailsVBox/ItemDesc
@onready var details_vbox = $CenterContainer/Panel/MarginContainer/VBoxContainer/DetailsVBox
@onready var carousel_hbox = $CenterContainer/Panel/MarginContainer/VBoxContainer/CarouselHBox

func _process(delta: float):
	if is_open:
		for r in _rotators:
			if is_instance_valid(r):
				r.rotate_y(delta * 1.5)

func _ready():
	layer = 20
	hide_inventory()
	pickup_notification.modulate.a = 0
	
	InventoryManager.inventory_changed.connect(_refresh_list)
	InventoryManager.item_added.connect(_show_pickup_notification)
	
	left_btn.pressed.connect(func(): _shift_carousel(-1))
	right_btn.pressed.connect(func(): _shift_carousel(1))
	
	# Give the panel a subtle brown border
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.06, 0.95)
	style.border_color = Color(0.3, 0.25, 0.2, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)

func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			if is_open:
				hide_inventory()
			else:
				show_inventory()
			get_viewport().set_input_as_handled()
			
	if is_open:
		if event.is_action_pressed("ui_left") or (event is InputEventKey and event.keycode == KEY_A and event.pressed and not event.echo):
			if not left_btn.disabled: _shift_carousel(-1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_right") or (event is InputEventKey and event.keycode == KEY_D and event.pressed and not event.echo):
			if not right_btn.disabled: _shift_carousel(1)
			get_viewport().set_input_as_handled()

func show_inventory():
	var player = get_tree().root.find_child("Player", true, false)
	if player:
		if player.get("in_cinematic") == true or player.get("is_examining") == true or player.get("is_intro_playing") == true:
			return
	
	is_open = true
	background.show()
	panel.show()
	_refresh_list()
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	background.modulate.a = 0
	var bg_tween = create_tween()
	bg_tween.tween_property(background, "modulate:a", 1.0, 0.2)
	_refresh_list()

func hide_inventory():
	is_open = false
	background.hide()
	panel.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _shift_carousel(dir: int):
	current_index += dir
	_refresh_list()

func _refresh_list():
	var items = InventoryManager.get_items()
	
	for rotator in _rotators:
		if is_instance_valid(rotator):
			rotator.queue_free()
	_rotators.clear()
	
	for child in prev_slot.get_children(): child.queue_free()
	for child in center_slot.get_children(): child.queue_free()
	for child in next_slot.get_children(): child.queue_free()
	
	if items.size() == 0:
		empty_label.show()
		carousel_hbox.hide()
		details_vbox.hide()
		current_index = 0
		return
		
	empty_label.hide()
	carousel_hbox.show()
	details_vbox.show()
	
	if current_index >= items.size():
		current_index = max(0, items.size() - 1)
		
	# Keep them in the layout so the Panel doesn't abruptly resize and shift the UI!
	left_btn.disabled = (current_index <= 0)
	left_btn.modulate.a = 0.0 if current_index <= 0 else 1.0
	
	right_btn.disabled = (current_index >= items.size() - 1)
	right_btn.modulate.a = 0.0 if current_index >= items.size() - 1 else 1.0
	
	item_name.text = items[current_index].get("name", "???")
	item_desc.text = items[current_index].get("description", "")
	
	if current_index > 0:
		_build_slot(prev_slot, items[current_index - 1], 100, 0.3, false)
	if current_index < items.size() - 1:
		_build_slot(next_slot, items[current_index + 1], 100, 0.3, false)
		
	_build_slot(center_slot, items[current_index], 250, 1.0, true)

func _build_slot(parent_container: Control, item: Dictionary, size_px: int, opacity: float, is_center: bool):
	var icon_container = CenterContainer.new()
	icon_container.custom_minimum_size = Vector2(size_px, size_px)
	icon_container.modulate = Color(1, 1, 1, opacity)
	
	if is_center:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(size_px, size_px)
		btn.flat = true
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.pressed.connect(_on_item_clicked.bind(item))
		icon_container.add_child(btn)
	
	var shadow_rect = ColorRect.new()
	shadow_rect.color = Color(0, 0, 0, 0.6 if is_center else 0.4)
	shadow_rect.custom_minimum_size = Vector2(size_px - 10, size_px - 10)
	shadow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_container.add_child(shadow_rect)
	
	var vp_container = SubViewportContainer.new()
	vp_container.custom_minimum_size = Vector2(size_px - 10, size_px - 10)
	vp_container.stretch = true
	vp_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var viewport = SubViewport.new()
	viewport.transparent_bg = true
	viewport.own_world_3d = true 
	viewport.size = Vector2(size_px - 10, size_px - 10)
	vp_container.add_child(viewport)
	
	if item.get("scene_path"):
		var scene_res = load(item["scene_path"])
		if scene_res:
			var item_3d = scene_res.instantiate()
			_strip_logic(item_3d)
			
			var cam = Camera3D.new()
			var light1 = DirectionalLight3D.new()
			light1.rotation_degrees = Vector3(-45, 45, 0)
			var light2 = DirectionalLight3D.new()
			light2.rotation_degrees = Vector3(45, -135, 0)
			light2.light_energy = 0.5
			var rotator = Node3D.new()
			
			if item.get("id") == "coin":
				item_3d.rotation_degrees = Vector3(45, 0, 0)
				item_3d.scale = Vector3(2.5, 2.5, 2.5)
				cam.position = Vector3(0, 0, 0.2)
			elif item.get("id") == "posporo":
				item_3d.rotation_degrees = Vector3(20, 0, 0)
				item_3d.scale = Vector3(1.0, 1.0, 1.0)
				cam.position = Vector3(0, 0.02, 0.25)
			elif item.get("id") == "candle":
				item_3d.rotation_degrees = Vector3(10, 0, 0)
				item_3d.scale = Vector3(0.5, 0.5, 0.5)
				cam.position = Vector3(0, 0.08, 0.3)
			else:
				item_3d.rotation_degrees = Vector3(30, 0, 0)
				item_3d.scale = Vector3(1.0, 1.0, 1.0)
				cam.position = Vector3(0, 0, 0.3)
				
			rotator.add_child(item_3d)
			viewport.add_child(cam)
			viewport.add_child(light1)
			viewport.add_child(light2)
			viewport.add_child(rotator)
			
			_rotators.append(rotator)
			
	icon_container.add_child(vp_container)
	parent_container.add_child(icon_container)

func _on_item_clicked(item: Dictionary):
	var player = get_tree().root.find_child("Player", true, false)
	if player and player.has_method("equip_item"):
		player.equip_item(item)
		hide_inventory()

func _strip_logic(node: Node):
	node.set_script(null)
	node.set_process(false)
	node.set_physics_process(false)
	
	if node is RigidBody3D:
		node.freeze = true
		node.gravity_scale = 0.0
	
	if node is CollisionShape3D:
		node.queue_free()
	
	for child in node.get_children():
		_strip_logic(child)

func _show_pickup_notification(item_data: Dictionary):
	if _pickup_tween and _pickup_tween.is_valid():
		_pickup_tween.kill()
	
	pickup_notification.text = "+ " + item_data.get("name", "Item")
	pickup_notification.modulate.a = 0
	pickup_notification.show()
	
	_pickup_tween = create_tween()
	_pickup_tween.tween_property(pickup_notification, "modulate:a", 1.0, 0.3)
	_pickup_tween.tween_interval(2.5)
	_pickup_tween.tween_property(pickup_notification, "modulate:a", 0.0, 1.0)
