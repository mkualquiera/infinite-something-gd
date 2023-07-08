extends Node3D
class_name RoomController

@export var room_theme = "A videogame with the theme: Underwater"
@export var load_on_ready = false
@export var floor: MeshInstance3D
@export var l_wall: MeshInstance3D
@export var obj_padding: float = 0.5
@export var room_manager: RoomManager
@export var room_position: Vector2i
var controllers: Array[ObjectController]
var world: Dictionary

# Called when the node enters the scene tree for the first time.
func _ready():
	if load_on_ready:
		load_room()

func load_room():
	
	# Create an HTTP request node and connect its completion signal.
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", _on_room_generated)
	
	#var request_data = {
	#	"text": texture_description + " texture, vfx asset,"+
	#	" texture of \"" + texture_description + "\" trending on artstation, 4K",
	#	"sampler": "sample_dpmpp_2m"
	#}
	var request_data = {
		"world_desc": room_theme,
		"cond": {
			"objects": [
				{
					"name": "player",
					"metadata": {
						"health": 100,
						"inventory": []
					}
				}
			]
		}
	}
	
	var json_request = JSON.stringify(request_data)

	# Perform the HTTP request. The URL below returns a PNG image as of writing.
	var inference_url = PlayerPrefs.get_pref("inference_url")
	var error = http_request.request(inference_url + "/gen_world", [], 
		HTTPClient.METHOD_POST, json_request)
	if error != OK:
		push_error("An error occurred in the HTTP request.")
		
	# Create an HTTP request node and connect its completion signal.
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", _on_room_texture_prompts_generated)

	request_data = {
		"world_desc": room_theme
	}
	
	json_request = JSON.stringify(request_data)

	# Perform the HTTP request. The URL below returns a PNG image as of writing.
	error = http_request.request(inference_url + "/gen_room_textures", [], 
		HTTPClient.METHOD_POST, json_request)
	if error != OK:
		push_error("An error occurred in the HTTP request.")
		
func _on_room_texture_prompts_generated(result, response_code, headers, body):
	var json = body.get_string_from_utf8()
	var data = JSON.parse_string(json)
	
	var floor_gen: TextureGenerator = floor.get_child(0)
	floor_gen.texture_description = data["floor_texture"]
	floor_gen.do_load()
	
	var wall_l_gen: TextureGenerator = l_wall.get_child(0)
	wall_l_gen.texture_description = data["wall_texture"]
	wall_l_gen.do_load()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

var room_obj_scene = preload("res://Scenes/room_object.tscn")

# Called when the HTTP request is completed.
func _on_room_generated(result, response_code, headers, body):
	var json = body.get_string_from_utf8()
	var data = JSON.parse_string(json)
	world = data
	
	for object in data["objects"]:
		var controller = _create_object(object, false)
		controllers.append(controller)
		controller.update_rendering(data)		

func do_interaction(object: ObjectController, interaction):
	# Create an HTTP request node and connect its completion signal.
	print_debug("Doing interaction")
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", _on_interaction_completed)
	

	var request_data = {
		"world": world,
		"object": {
			"name": object.obj_name,
			"metadata": object.metadata
		}, 
		"interaction": interaction
	}
	
	var json_request = JSON.stringify(request_data)
	
	var inference_url = PlayerPrefs.get_pref("inference_url")
	var error = http_request.request(inference_url + "/do_interaction", [], 
		HTTPClient.METHOD_POST, json_request)
	if error != OK:
		push_error("An error occurred in the HTTP request.")
		
func _on_interaction_completed(result, response_code, headers, body):
	
	var json = body.get_string_from_utf8()
	var data: Dictionary = JSON.parse_string(json)
	
	if data.has("delete_objects"):
		if data["delete_objects"] is Array:
			for to_delete in data["delete_objects"]:
				var objects: Array = world["objects"]
				var counter = 0
				for object in objects:
					if object["name"] == to_delete["name"]:
						var controller: ObjectController = controllers[counter]
						controller.destroy()
						controllers.remove_at(counter)
						objects.remove_at(counter)
						break
					counter += 1 
				
					
	if data.has("display_messages"):
		if data["display_messages"] is Array:
			for message in data["display_messages"]:
				print(message["message"])
			
	var update_queue = []		
	
	if data.has("create_objects"):
		if data["create_objects"] is Array:
			for object in data["create_objects"]:
				var controller = _create_object(object)
				controllers.append(controller)
				update_queue.append(controller)
				world["objects"].append(object)

	if data.has("overwrite_metadata"):
		if data["overwrite_metadata"] is Array:
			for update_metadata in data["overwrite_metadata"]:
				var objects: Array = world["objects"]
				var counter = 0
				for object in objects:
					if object["name"] == update_metadata["name"]:
						for key in update_metadata["metadata"].keys():
							object["metadata"][key] = update_metadata["metadata"][key]
						var controller: ObjectController = controllers[counter]
						controller.metadata = object["metadata"]
						update_queue.append(controller)
						
					counter += 1 
				
	for controller in update_queue:
		controller.update_rendering(world)
	


func _create_object(object, add=true):
	var room_obj: MeshInstance3D = room_obj_scene.instantiate()
	add_child(room_obj)
	
	var controller: ObjectController = room_obj.get_child(0)

	controller.obj_name = object["name"]
	controller.metadata = object["metadata"]
	print_debug("Created object "+ object["name"])

	# Move the object to a random place horizontally.
	var area_x = floor.scale.x / 2
	var area_z = floor.scale.z / 2
	var x = randf_range(-area_x + obj_padding, area_x - obj_padding)
	var z = randf_range(-area_z + obj_padding, area_z - obj_padding)
	room_obj.position.x = x
	room_obj.position.z = z
	room_obj.position.y = floor.position.y
	
	if add:
		world["objects"].append(object)
	return controller


func _on_player_enter():
	room_manager.instantiate_room(room_position + Vector2i(1,0))
	room_manager.instantiate_room(room_position + Vector2i(0,1))
	room_manager.instantiate_room(room_position + Vector2i(-1,0))
	room_manager.instantiate_room(room_position + Vector2i(0,-1))
	
