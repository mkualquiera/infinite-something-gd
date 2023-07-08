extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	set_active(false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func set_active(is_active):
	visible = is_active
	for c in get_children():
		# c.process_mode = Node.PROCESS_MODE_INHERIT if is_active else Node.PROCESS_MODE_DISABLED
		c.visible = is_active
