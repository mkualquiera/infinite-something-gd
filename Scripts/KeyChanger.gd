extends Node


@onready var text_box = $TextEdit
@onready var checkbox = $CheckBox
@onready var button = $Button


# Called when the node enters the scene tree for the first time.
func _ready():
	text_box.text = PlayerPrefs.get_pref("oai_key")
	checkbox.button_pressed = PlayerPrefs.get_pref("use_oai")
	update_button()


func update_button_(a):
	update_button()


func update_button():
	# since URLs change
	button.visible = true
#			((text_box.text != PlayerPrefs.get_pref("oai_key"))
#					or (checkbox.button_pressed != PlayerPrefs.get_pref("use_oai")))


func update_pref():
	var text: String = text_box.text
	if text.ends_with("/"):
		text = text.substr(0, len(text) - 1)
	PlayerPrefs.set_pref("oai_key", text)
	PlayerPrefs.set_pref("use_oai", checkbox.button_pressed)
	text_box.text = text
	update_button()
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	#http_request.connect("request_completed", _http_request_completed)
	
	#var request_data = {
	#	"text": texture_description + " texture, vfx asset,"+
	#	" texture of \"" + texture_description + "\" trending on artstation, 4K",
	#	"sampler": "sample_dpmpp_2m"
	#}
	var request_data = {
		"key": PlayerPrefs.get_pref("oai_key"),
		"use_key": PlayerPrefs.get_pref("use_oai")
	}
	
	var json_request = JSON.stringify(request_data)

	# Perform the HTTP request. The URL below returns a PNG image as of writing.
	var inference_url = PlayerPrefs.get_pref("inference_url")
	var error = http_request.request(inference_url + "/oai_key", [], 
		HTTPClient.METHOD_POST, json_request)
	if error != OK:
		push_error("An error occurred in the HTTP request.")
