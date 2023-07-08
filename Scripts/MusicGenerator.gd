extends Node

@export var music_description = "Drums, tribal, indigenous, dangerous"
@export var load_on_ready = false
@export var duration = 30.0
@export var loops = 3

func _ready():
	if load_on_ready:
		do_load()

func do_load():
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", self._http_request_completed)
	
	var request_data = {
		"text": music_description,
		"duration": duration,
		"loops": loops
	}
	
	var json_request = JSON.stringify(request_data)

	var inference_url = PlayerPrefs.get_pref("inference_url")
	var error = http_request.request(
		inference_url + "/generate_music", [], HTTPClient.METHOD_POST, json_request)
	if error != OK:
		print("Audio request failed")

func _http_request_completed(result, response_code, headers, body):
	if result == OK and response_code == 200:
		var audio_data = JSON.parse_string(body.get_string_from_utf8())["audio"]
		var decoded_audio_data = Marshalls.base64_to_raw(audio_data)
			
		var audio_stream = AudioStreamWAV.new()
		audio_stream.data = decoded_audio_data
		audio_stream.mix_rate = 32000
		audio_stream.format = AudioStreamWAV.FORMAT_8_BITS
		
		#var audio_sample = AudioStreamPlayer.new()
		#add_child(audio_sample)
		#audio_sample.stream = audio_stream
		#audio_sample.play()
		
		var audio_player: AudioStreamPlayer = get_parent()
		audio_player.stream = audio_stream
		audio_player.play()
	else:
		print("Audio fail", result, "and", response_code)
