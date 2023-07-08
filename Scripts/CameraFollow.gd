extends Node3D

@export var player: CharacterBody3D
@export var strength: float
var offset

# Called when the node enters the scene tree for the first time.
func _ready():
	offset = position - player.position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var target = offset + player.position
	
	position += (target - position) * strength
