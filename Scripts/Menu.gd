extends Button

var game_scene = preload("res://test.tscn")


func open_game():
	get_tree().change_scene_to_packed(game_scene)
