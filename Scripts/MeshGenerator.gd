extends Node
class_name MeshGenerator

@export var mesh_description = "Underwater"
@export var load_on_ready = false

func _ready():
	if load_on_ready:
		do_load()

func do_load():
	# Create an HTTP request node and connect its completion signal.
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", _http_request_completed)
	
	#var request_data = {
	#	"text": texture_description + " texture, vfx asset,"+
	#	" texture of \"" + texture_description + "\" trending on artstation, 4K",
	#	"sampler": "sample_dpmpp_2m"
	#}
	var request_data = {
		"text": mesh_description
	}
	
	var json_request = JSON.stringify(request_data)

	# Perform the HTTP request. The URL below returns a PNG image as of writing.
	var inference_url = PlayerPrefs.get_pref("inference_url")
	var error = http_request.request(inference_url + "/generate_mesh_shap_e", [], 
		HTTPClient.METHOD_POST, json_request)
	if error != OK:
		push_error("An error occurred in the HTTP request.")


# Called when the HTTP request is completed.
func _http_request_completed(result, response_code, headers, body):
	var json = JSON.parse_string(body.get_string_from_utf8())
	if json == null:
		return
	var obj = json["obj"]
	
	var mesh = ObjParse.load_obj_from_buffer(obj, {})
	
	# Set the material to the mesh
	var mesh_instance = get_parent()
	mesh_instance.mesh = mesh
