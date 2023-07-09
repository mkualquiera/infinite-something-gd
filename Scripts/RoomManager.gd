extends Node3D
class_name RoomManager

var rooms: Dictionary
var loaded_rooms: Dictionary
var room_scene = preload("res://Scenes/room.tscn")
@export var player: CharacterBody3D 
@export var grid_size: int = 20
var room_queue: Array[Vector2i]
var is_loading: bool = true

signal loading_finished(pos: Vector2i)

func on_door_crossed(pos, offset):
	rooms[pos + offset].door_map[-offset].debounce = true
	rooms[pos].get_child(0)._on_player_leave()
	rooms[pos + offset].get_child(0)._on_player_enter()

func enable_neighboring_doors(pos):
	var neighbors = [
		Vector2i(1,0),
		Vector2i(-1,0),
		Vector2i(0,1),
		Vector2i(0,-1),
	]
	
	for neighbor in neighbors:
		var neighbor_pos = neighbor + pos
		var inverse_door = -neighbor
		if loaded_rooms.has(neighbor_pos):
			var neighbor_room: RoomLoader = rooms[neighbor_pos]
			neighbor_room.door_map[inverse_door].set_enabled(true)
			var this_room: RoomLoader = rooms[pos]
			this_room.door_map[neighbor].set_enabled(true)

# Called when the node enters the scene tree for the first time.
func _ready():
	var core_room = instantiate_room(Vector2i(0,0))
	core_room.get_child(0)._on_player_enter()
	
func enqueue_room(pos: Vector2i):
	room_queue.append(pos)

func _loading_finished(pos: Vector2i):
	print_debug("Room finished loading ", pos)
	emit_signal("loading_finished", pos)
	loaded_rooms[pos] = true
	enable_neighboring_doors(pos)
	is_loading = false
	
func _process(delta):
	if !is_loading:
		load_next()
		
func load_next():
	var next_room = room_queue.pop_back()
	if next_room:
		instantiate_room(next_room)
	
func instantiate_room(pos: Vector2i):
	if rooms.has(pos):
		return null
		
	is_loading = true
		
	var instantiated = room_scene.instantiate()
	rooms[pos] = instantiated
	instantiated.position.x = pos.x * grid_size
	instantiated.position.z = pos.y * grid_size
	instantiated.connect("input_event",player._click)
	instantiated.connect("on_door_crossed",on_door_crossed)
	var controller: RoomController = instantiated.get_child(0)
	controller.room_manager = self
	controller.room_position = pos
	controller.connect("on_done_loading", _loading_finished)
	add_child(instantiated)
	return instantiated
