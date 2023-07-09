extends Node3D
class_name RoomManager

var rooms: Dictionary
var loaded_rooms: Dictionary
var room_scene = preload("res://Scenes/room.tscn")
@export var player: CharacterBody3D 
@export var grid_size: int = 20
var room_queue: Array[Vector2i]
var theme_queue: Array[String]
var is_loading: bool = true
var loaded_first_level = false
@export var loading_screen: Control
@onready var message_log = $MessageLog
@export var theme_name: Label

signal loading_finished(pos: Vector2i)

func on_door_crossed(pos, offset):
	rooms[pos + offset].door_map[-offset].debounce = true
	rooms[pos].get_child(0)._on_player_leave()
	rooms[pos + offset].get_child(0)._on_player_enter()
	var theme = rooms[pos + offset].get_child(0).room_theme
	if theme == null:
		theme = ""
	theme_name.text = theme

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
	var core_room = instantiate_room("Hub", Vector2i(0,0))

	
func enqueue_room(pos: Vector2i):
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var inference_url = PlayerPrefs.get_pref("inference_url")
	var error = http_request.request(inference_url + "/gen_theme", [], HTTPClient.METHOD_GET)
	if error != OK:
		push_error("An error occurred in the HTTP request.")
	var body = (await http_request.request_completed)[3]
	var theme: String = body.get_string_from_utf8()
	if theme.is_empty() or theme == "null" or theme == null:
		enqueue_room(pos)
		return
	print_debug("Room ", pos, " Theme: ", theme)
	room_queue.append(pos)
	theme_queue.append(theme)

func _loading_finished(pos: Vector2i, theme: String):
	if !loaded_first_level:
		loaded_first_level = true
		loading_screen.hide()
		rooms[pos].get_child(0)._on_player_enter()
		
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
		instantiate_room(theme_queue.pop_back(), next_room)
	
func instantiate_room(theme: String, pos: Vector2i):
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
	controller.room_theme = theme
	controller.connect("on_done_loading", _loading_finished)
	controller.connect("show_message", add_message)
	add_child(instantiated)
	return instantiated

func add_message(message):
	message_log.text = message + "\n" + message_log.text
