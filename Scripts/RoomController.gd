extends Node3D
class_name RoomController

@export var room_theme = "A videogame with the theme: Jungle"
@export var load_on_ready = false
@export var floor: MeshInstance3D
@export var l_wall: MeshInstance3D
@export var music_gen: MusicGenerator
@export var obj_padding: float = 0.5
@export var room_manager: RoomManager
@export var room_position: Vector2i
var controllers: Array[ObjectController]
var world: Dictionary
@export var audio: AudioStreamPlayer
@export var env_generator: EnvironmentGenerator

var loading_counter: int = 0

signal on_done_loading(pos)

func on_child_done_loading():
	loading_counter -= 1
	print_debug("Loading counter ", loading_counter)
	if loading_counter <= 0:
		emit_signal("on_done_loading", room_position)

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
	
	env_generator.environment_description = room_theme
	env_generator.do_load()
		
func _on_room_texture_prompts_generated(result, response_code, headers, body):
	var json = body.get_string_from_utf8()
	var data = JSON.parse_string(json)
	
	if data == null:
		print("Retrying room texture generation")
		# Create an HTTP request node and connect its completion signal.
		var http_request = HTTPRequest.new()
		add_child(http_request)
		http_request.connect("request_completed", _on_room_texture_prompts_generated)

		var request_data = {
			"world_desc": room_theme
		}
		
		var json_request = JSON.stringify(request_data)

		# Perform the HTTP request. The URL below returns a PNG image as of writing.
		var inference_url = PlayerPrefs.get_pref("inference_url")
		var error = http_request.request(inference_url + "/gen_room_textures", [], 
			HTTPClient.METHOD_POST, json_request)
		if error != OK:
			push_error("An error occurred in the HTTP request.")
		return
	
	var floor_gen: TextureGenerator = floor.get_child(0)
	floor_gen.texture_description = data["floor_texture"]
	loading_counter += 1
	floor_gen.connect("done_loading",on_child_done_loading)
	floor_gen.do_load()
	
	var wall_l_gen: TextureGenerator = l_wall.get_child(0)
	wall_l_gen.texture_description = data["wall_texture"]
	loading_counter += 1
	wall_l_gen.connect("done_loading",on_child_done_loading)
	wall_l_gen.do_load()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

var room_obj_scene = preload("res://Scenes/room_object.tscn")

# Called when the HTTP request is completed.
func _on_room_generated(result, response_code, headers, body):
	var json = body.get_string_from_utf8()
	var data = JSON.parse_string(json)
	if data == null:
		print("Retrying room generation")
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
		return
	world = data
	
	for object in data["objects"]:
		loading_counter += 1
		var controller = _create_object(object, false)
		controllers.append(controller)
		controller.update_rendering(data)		
		controller.connect("on_done_loading", on_child_done_loading)
	
	# Create an HTTP request node and connect its completion signal.
	var http_request = HTTPRequest.new()
	add_child(http_request)

	var request_data = {
		"theme": room_theme
	}
	
	var json_request = JSON.stringify(request_data)

	var music_prompt = ""
	while true:
		# Perform the HTTP request. The URL below returns a music prompt at the time of writing.
		var inference_url = PlayerPrefs.get_pref("inference_url")
		var error = http_request.request(inference_url + "/music_prompt", [], 
			HTTPClient.METHOD_POST, json_request)
		if error != OK:
			push_error("An error occurred in the HTTP request.")
		body = (await http_request.request_completed)[3]
		json = body.get_string_from_utf8()
		data = JSON.parse_string(json)
		if data == null:
			continue
		print("Music prompt ", data)
		music_prompt = data["prompt"]
		break
	print_debug("Music prompt: ", music_prompt)
	loading_counter += 1
	music_gen.connect("done_loading",on_child_done_loading)
	music_gen.music_description = music_prompt
	music_gen.do_load()

func do_interaction(object: ObjectController, interaction, arguments):
	# Create an HTTP request node and connect its completion signal.
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var new_interaction = interaction.duplicate()
	new_interaction.arguments = arguments

	print_debug("Doing interaction ", new_interaction)

	var request_data = {
		"world": world,
		"object": {
			"name": object.obj_name,
			"metadata": object.metadata
		}, 
		"interaction": new_interaction
	}
	
	var json_request = JSON.stringify(request_data)
	
	var inference_url = PlayerPrefs.get_pref("inference_url")
	var error = http_request.request(inference_url + "/do_interaction", [], 
		HTTPClient.METHOD_POST, json_request)
	if error != OK:
		push_error("An error occurred in the HTTP request.")
	
	var body = (await http_request.request_completed)[3]
	var json = body.get_string_from_utf8()
	var data = JSON.parse_string(json)
	if data == null:
		await do_interaction(object, interaction, arguments)
		return
	
	if data.has("delete_objects"):
		if data["delete_objects"] is Array:
			for to_delete in data["delete_objects"]:
				var objects: Array = world["objects"]
				var counter = 0
				for obj in objects:
					if obj["name"] == to_delete["name"]:
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
			for obj in data["create_objects"]:
				var controller = _create_object(obj)
				controllers.append(controller)
				update_queue.append(controller)
				world["objects"].append(obj)

	if data.has("overwrite_metadata"):
		if data["overwrite_metadata"] is Array:
			for update_metadata in data["overwrite_metadata"]:
				var objects: Array = world["objects"]
				var counter = 0
				for obj in objects:
					if obj["name"] == update_metadata["name"]:
						for key in update_metadata["metadata"].keys():
							obj["metadata"][key] = update_metadata["metadata"][key]
						var controller: ObjectController = controllers[counter]
						controller.metadata = obj["metadata"]
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
	
	if add:
		world["objects"].append(object)
	return controller


func _on_player_enter():
	pass
	room_manager.enqueue_room(room_position + Vector2i(1,0))
	room_manager.enqueue_room(room_position + Vector2i(0,1))
	room_manager.enqueue_room(room_position + Vector2i(-1,0))
	room_manager.enqueue_room(room_position + Vector2i(0,-1))
	audio.play(0)
	
func _on_player_leave():
	audio.stop()
