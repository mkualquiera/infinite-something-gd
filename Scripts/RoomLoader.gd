extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	set_active(true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func set_active(is_active):
	visible = is_active
	for c in get_children():
		if c is NavigationRegion3D:
			c.process_mode = Node.PROCESS_MODE_INHERIT if is_active else Node.PROCESS_MODE_DISABLED
		if c is Node3D or c is Control:
			c.visible = is_active
