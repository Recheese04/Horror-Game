extends Node3D

@onready var video_player = $SubViewport/VideoStreamPlayer
@onready var screen_light = $TVScreen/OmniLight3D
@onready var tv_screen = $TVScreen

@export var is_on: bool = true

func _ready():
    # Setup the view port texture dynamically over the TV screen mesh
    var mat = StandardMaterial3D.new()
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.albedo_texture = $SubViewport.get_texture()
    tv_screen.material_override = mat
    
    _update_state()

func toggle():
    is_on = not is_on
    _update_state()

func interact():
    toggle()

func get_interaction_prompt() -> String:
    if is_on:
        return "Turn Off"
    else:
        return "Turn On"

func _update_state():
    if is_on:
        video_player.play()
        screen_light.visible = true
        if tv_screen.material_override:
            tv_screen.material_override.albedo_color = Color(1, 1, 1, 1)
        $SubViewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    else:
        video_player.stop()
        screen_light.visible = false
        if tv_screen.material_override:
            tv_screen.material_override.albedo_color = Color(0, 0, 0, 1)
        $SubViewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
