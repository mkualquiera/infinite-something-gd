extends CharacterBody3D
class_name PlayerMover

var movement_speed: float = 2.0
var navigation_agent: NavigationAgent3D = null
@onready var vis: Node3D = $vis
@onready var player_player: AnimationPlayer = $vis/AnimationPlayer

func set_movement_target(movement_target: Vector3):
	movement_target.y = global_position.y
	navigation_agent = NavigationAgent3D.new()
	add_child(navigation_agent)
	navigation_agent.path_desired_distance = 0.1
	navigation_agent.target_desired_distance = 0.1
	navigation_agent.set_target_position(movement_target)

func _physics_process(delta):
	if navigation_agent != null and navigation_agent.is_navigation_finished():
		navigation_agent = null
	if navigation_agent == null:
		player_player.current_animation = "idle"
		return

	player_player.current_animation = "walk001"
	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()

	var new_velocity: Vector3 = next_path_position - current_agent_position
	new_velocity = new_velocity.normalized()
	new_velocity = new_velocity * movement_speed
	velocity = new_velocity
	new_velocity.y = 0
	vis.look_at(vis.global_position - new_velocity)
	var moved = move_and_slide()


func _click(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.button_index == 1 and event.pressed:
		set_movement_target(position)
