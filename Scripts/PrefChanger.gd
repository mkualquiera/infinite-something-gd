extends Node


@export var pref_name = "inference_url"
@onready var text_box = $TextEdit
@onready var button = $Button


# Called when the node enters the scene tree for the first time.
func _ready():
	text_box.text = PlayerPrefs.get_pref(pref_name)
	update_button()


func update_button():
	button.visible = text_box.text != PlayerPrefs.get_pref(pref_name)


func update_pref():
	var text: String = text_box.text
	if text.ends_with("/"):
		text = text.substr(0, len(text) - 1)
	PlayerPrefs.set_pref(pref_name, text)
	text_box.text = text
	update_button()
