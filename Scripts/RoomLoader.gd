extends Node3D
class_name RoomLoader

@export var door_px: DoorController
@export var door_nx: DoorController
@export var door_pz: DoorController
@export var door_nz: DoorController

@export var door_map: Dictionary

signal input_event(camera:Node, event:InputEvent, position:Vector3, normal:Vector3, shape_idx:int)

func input_event_daisy(camera:Node, event:InputEvent, position:Vector3, normal:Vector3, shape_idx:int):
	emit_signal("input_event", camera, event, position, normal, shape_idx)	

signal on_door_crossed(pos, offset)

func _on_door_crossed(offset):
	emit_signal("on_door_crossed", get_child(0).room_position, offset)

# Called when the node enters the scene tree for the first time.
func _ready():
	door_map[Vector2i(1,0)] = door_px
	door_map[Vector2i(-1,0)] = door_nx
	door_map[Vector2i(0,1)] = door_pz
	door_map[Vector2i(0,-1)] = door_nz
	door_px.connect("on_door_crossed", _on_door_crossed)
	door_nx.connect("on_door_crossed", _on_door_crossed)
	door_pz.connect("on_door_crossed", _on_door_crossed)
	door_nz.connect("on_door_crossed", _on_door_crossed)
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
