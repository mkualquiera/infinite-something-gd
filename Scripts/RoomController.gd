extends Node3D
class_name RoomController

@export var room_theme = "A videogame with the theme: Underwater"
@export var load_on_ready = false
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
		var room_obj: MeshInstance3D = room_obj_scene.instantiate()
		add_child(room_obj)
		
		var controller: ObjectController = room_obj.get_child(0)

		controller.obj_name = object["name"]
		controller.metadata = object["metadata"]
		print_debug("Created object "+ object["name"])

		# Move the object to a random place horizontally.
		var x = randf_range(-2, 2)
		var z = randf_range(-2, 2)
		room_obj.position.x = x
		room_obj.position.z = z
		
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
						objects.remove_at(counter)
						var child = get_child(counter)
						child.queue_free()
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
				var room_obj: MeshInstance3D = room_obj_scene.instantiate()
				add_child(room_obj)
				
				var controller: ObjectController = room_obj.get_child(0)
		
				controller.obj_name = object["name"]
				controller.metadata = object["metadata"]
				print_debug("Created object "+ object["name"])
		
				# Move the object to a random place horizontally.
				var x = randf_range(-2, 2)
				var z = randf_range(-2, 2)
				room_obj.position.x = x
				room_obj.position.z = z
				
				world["objects"].append(object)
				
				update_queue.append(controller)

	if data.has("overwrite_metadata"):
		if data["overwrite_metadata"] is Array:
			for update_metadata in data["overwrite_metadata"]:
				var objects: Array = world["objects"]
				var counter = 0
				for object in objects:
					if object["name"] == update_metadata["name"]:
						for key in update_metadata["metadata"].keys():
							object["metadata"]["key"] = update_metadata["metadata"]["key"]
						var child = get_child(counter)
						var controller: ObjectController = child.get_child(counter)
						controller.metadata = object["metadata"]
						
						update_queue.append(controller)
						
					counter += 1 
				
	for controller in update_queue:
		controller.update_rendering(world)
	
