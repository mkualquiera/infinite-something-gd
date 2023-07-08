extends Node3D
class_name RoomManager

var rooms: Dictionary
var room_scene = preload("res://Scenes/room.tscn")
@export var player: CharacterBody3D 
@export var grid_size: int = 20
var room_queue: Array[Vector2i]

signal loading_finished(pos: Vector2i)

# Called when the node enters the scene tree for the first time.
func _ready():
	var core_room = instantiate_room(Vector2i(0,0))
	core_room.get_child(0)._on_player_enter()
	
func enqueue_room(pos: Vector2i):
	room_queue.append(pos)

func _loading_finished(pos: Vector2i):
	print_debug("Room finished loading ", pos)
	emit_signal("loading_finished", pos)
	var next_room = room_queue.pop_back()
	if next_room:
		instantiate_room(next_room)
	
func instantiate_room(pos: Vector2i):
	if rooms.has(pos):
		return null
	var instantiated = room_scene.instantiate()
	rooms[pos] = instantiated
	instantiated.position.x = pos.x * grid_size
	instantiated.position.z = pos.y * grid_size
	instantiated.connect("input_event",player._click)
	var controller: RoomController = instantiated.get_child(0)
	controller.room_manager = self
	controller.room_position = pos
	controller.connect("on_done_loading", _loading_finished)
	add_child(instantiated)
	return instantiated
