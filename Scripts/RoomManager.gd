extends Node3D
class_name RoomManager

var rooms: Dictionary
var room_scene = preload("res://Scenes/room.tscn")
@export var player: CharacterBody3D 
@export var grid_size: int = 20

# Called when the node enters the scene tree for the first time.
func _ready():
	var core_room = instantiate_room(Vector2i(0,0))
	core_room.get_child(0)._on_player_enter()
	
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
	add_child(instantiated)
	return instantiated
