extends Node3D

@onready var animador = $AnimationPlayer # Ajusta esto para que apunte a tu AnimationPlayer


func _ready():
	var animacion = animador.get_animation("Scene")
	
	animacion.loop_mode = Animation.LOOP_LINEAR
	
	animador.play("Scene")
