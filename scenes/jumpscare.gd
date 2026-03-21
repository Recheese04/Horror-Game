extends CanvasLayer

@onready var texture_rect = $TextureRect
@onready var timer = $Timer

func _ready():
	# Initially hidden
	texture_rect.hide()

func trigger():
	texture_rect.show()
	if $AudioStreamPlayer:
		$AudioStreamPlayer.play()
	timer.start()

func _on_timer_timeout():
	texture_rect.hide()
	queue_free() # Remove self after jumpscare
