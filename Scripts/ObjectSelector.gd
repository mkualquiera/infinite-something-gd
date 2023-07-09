extends Node

var camera
@export var item_list: ItemList
var current_controller: ObjectController
var all_arguments: Array
var selected_interaction: int
@export var argument_prompt: ArgumentPrompt

# Called when the node enters the scene tree for the first time.
func _ready():
	camera = get_parent()
	item_list.connect("item_selected", _on_item_selected)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.pressed:
			var mouse_pos = get_viewport().get_mouse_position()
			var ray_length = 100
			var from = camera.project_ray_origin(mouse_pos)
			var to = from + camera.project_ray_normal(mouse_pos) * ray_length
			var space = camera.get_world_3d().direct_space_state
			var ray_query = PhysicsRayQueryParameters3D.new()
			ray_query.from = from
			ray_query.to = to
			ray_query.collide_with_areas = true
			var raycast_result = space.intersect_ray(ray_query)
			
			if raycast_result:
				var coll_obj: Node3D = raycast_result.collider.get_parent()
				
				var num_children = coll_obj.get_child_count()
				if num_children > 1:
					var first_child = coll_obj.get_child(0)
					if first_child is ObjectController:
						var controller: ObjectController = first_child
						#print_debug(controller.interactions)
						current_controller = controller
						all_arguments = []
						item_list.clear()
						for interaction in controller.interactions:
							item_list.add_item(interaction.display_name)
							all_arguments.append(interaction.arguments)
						
						get_parent().get_parent().find_child("Player").set_movement_target(controller.global_position)

func _on_item_selected(index: int):
	if current_controller != null:
		item_list.clear()
		argument_prompt.ask_questions(all_arguments[index])
		selected_interaction = index
		#print_debug("Doing interaction")
		#current_controller.do_interaction(index)
		#current_controller = null
		
func on_questions_answered(answers):
	print_debug("Doing interaction")
	current_controller.do_interaction(selected_interaction, answers)
	current_controller = null
