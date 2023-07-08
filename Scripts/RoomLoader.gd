extends Node3D

signal input_event(camera:Node, event:InputEvent, position:Vector3, normal:Vector3, shape_idx:int)

func input_event_daisy(camera:Node, event:InputEvent, position:Vector3, normal:Vector3, shape_idx:int):
	emit_signal("input_event", camera, event, position, normal, shape_idx)	

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
