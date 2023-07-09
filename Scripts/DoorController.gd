extends Area3D
class_name DoorController

@export var debounce = false
@export var offset: Vector2i
@export var grid_size: float = 20
@export var enabled = false
@onready var particle_gen = $GPUParticles3D

signal on_door_crossed(offset)

# Called when the node enters the scene tree for the first time.
func _ready():
	connect("area_entered", _area_entered)
	connect("area_exited", _area_exited)
	particle_gen.emitting = false

func set_enabled(_enabled):
	enabled = _enabled
	particle_gen.emitting = enabled

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _area_entered(area):
	print_debug("entered",area)
	if !enabled:
		return
	if debounce:
		return
	if area.get_parent() is CharacterBody3D:
		var player: CharacterBody3D = area.get_parent()
		player.position.x += offset.x * grid_size
		player.position.z += offset.y * grid_size
		player.position.x -= position.x * 2
		player.position.z -= position.z * 2
		emit_signal("on_door_crossed", offset)
	
func _area_exited(area):
	if area.get_parent() is CharacterBody3D:
		debounce = false
