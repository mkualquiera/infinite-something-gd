extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	get_child(0).set_active(true)
	get_child(1).set_active(false)
