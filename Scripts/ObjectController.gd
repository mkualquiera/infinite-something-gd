extends Node3D
class_name ObjectController

@export var obj_name: String = "undefined"
@export var metadata: Dictionary = {}
@export var interactions: Array = []
var texture_prompt: String = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

var loading_counter: int = 0
var loading_debounced: bool = false

signal on_done_loading()

func on_child_done_loading():
	if loading_debounced:
		return
	loading_counter -= 1
	if loading_counter <= 0:
		emit_signal("on_done_loading")
		loading_debounced = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func update_rendering(world):
	# Create an HTTP request node and connect its completion signal.
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", _on_prompt_generated)
	

	var request_data = {
		"world": world,
		"object": {
			"name": obj_name,
			"metadata": metadata
		}
	}
	
	var json_request = JSON.stringify(request_data)
	
	var inference_url = PlayerPrefs.get_pref("inference_url")
	var error = http_request.request(inference_url + "/object_texture_prompt", [], 
		HTTPClient.METHOD_POST, json_request)
	if error != OK:
		push_error("An error occurred in the HTTP request.")
	loading_counter += 1
		
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", _on_interactions_generated)
		
	inference_url = PlayerPrefs.get_pref("inference_url")
	error = http_request.request(inference_url + "/interact", [], 
		HTTPClient.METHOD_POST, json_request)
	if error != OK:
		push_error("An error occurred in the HTTP request.")
	loading_counter += 1

func _on_prompt_generated(result, response_code, headers, body):
	
	var json = body.get_string_from_utf8()
	var data = JSON.parse_string(json)
	
	var prompt = data["prompt"]
	print_debug(prompt)
	
	var texture_generator: MeshGenerator = get_parent().get_child(1)
	texture_generator.mesh_description = prompt
	texture_generator.connect("done_loading",on_child_done_loading)
	texture_generator.do_load()

func _on_interactions_generated(result, response_code, headers, body):
	
	var json = body.get_string_from_utf8()
	var data = JSON.parse_string(json)
	
	interactions = data["interactions"]
	on_child_done_loading()
	print_debug(interactions)
	
func do_interaction(index, arguments):
	var room_controller: RoomController = get_parent().get_parent()
	print_debug("Doing interaction")
	room_controller.do_interaction(self, interactions[index], arguments)
	
func destroy():
	get_parent().queue_free()
	
