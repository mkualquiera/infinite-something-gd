extends Node
class_name TextureGenerator

@export var texture_description = "Underwater"
@export var load_on_ready = false
@export var extra_meshes: Array[MeshInstance3D]

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
		"text": texture_description,
		"sampler": "sample_dpmpp_2m"
	}
	
	var json_request = JSON.stringify(request_data)

	# Perform the HTTP request. The URL below returns a PNG image as of writing.
	var inference_url = PlayerPrefs.get_pref("inference_url")
	var error = http_request.request(inference_url + "/generate_texture", [], 
		HTTPClient.METHOD_POST, json_request)
	if error != OK:
		push_error("An error occurred in the HTTP request.")


# Called when the HTTP request is completed.
func _http_request_completed(result, response_code, headers, body):
	var json = body.get_string_from_utf8()
	var img = JSON.parse_string(json)["image"]
	
	var data = Marshalls.base64_to_raw(img)
	
	var image = Image.new()
	var error = image.load_png_from_buffer(data)
	if error != OK:
		push_error("Couldn't load the image.")

	var texture = ImageTexture.create_from_image(image)

	#var material: BaseMaterial3D = get_parent().get_active_material(0)
	#material.albedo_texture = texture

	# Create new material
	var material: BaseMaterial3D = get_parent().get_active_material(0)
	material = material.duplicate()
	material.albedo_texture = texture

	# Set the material to the mesh
	var mesh_instance = get_parent()
	mesh_instance.material_override = material
	
	for mesh in extra_meshes:
		mesh.material_override = material
