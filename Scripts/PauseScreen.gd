extends ColorRect


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if get_parent().is_loading:
		return
	if Input.is_action_just_released("pause"):
		get_tree().paused = not get_tree().paused
	visible = get_tree().paused


func resume():
	get_tree().paused = false
