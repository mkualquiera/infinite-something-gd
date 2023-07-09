extends WorldEnvironment
class_name EnvironmentGenerator

@export var environment_description = "Underwater"
@export var sigma = 4.2
@export var load_on_ready = false
var colors = null

func _ready():
	if load_on_ready:
		do_load()

func do_load():
	return
	
	# Create an HTTP request node and connect its completion signal.
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", _http_request_completed)
	
	var request_data = {
		"theme": environment_description,
		"sigma": sigma,
		"res": 17,
		"res_high": 17,
	}
	
	var json_request = JSON.stringify(request_data)

	# Perform the HTTP request. The URL below returns a PNG image as of writing.
	var inference_url = PlayerPrefs.get_pref("inference_url")
	var error = http_request.request(inference_url + "/gen_color", [], 
		HTTPClient.METHOD_POST, json_request)
	if error != OK:
		push_error("An error occurred in the HTTP request.")


# Called when the HTTP request is completed.
func _http_request_completed(result, response_code, headers, body):
	var json = body.get_string_from_utf8()
	json = JSON.parse_string(json)
	if json == null:
		do_load()
		return
	var img = json["lut"]
	colors = json["colors"]
	
	var data = Marshalls.base64_to_raw(img)
	
	var image = Image.new()
	var error = image.load_png_from_buffer(data)
	if error != OK:
		push_error("Couldn't load the image.")

	var texture = ImageTexture3D.new()
	var images = []
	for i in range(0, 17 * 17, 17):
		var img_cut = Image.create(17, 17, false, Image.FORMAT_RGB8)
		img_cut.blit_rect(image, Rect2i(i, 0, 17, 17), Vector2i.ZERO)
		images.append(img_cut)
	texture.create(Image.FORMAT_RGB8, 17, 17, 17, false, Array(images))

	environment.adjustment_color_correction = texture
