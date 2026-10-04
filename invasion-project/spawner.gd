extends Node3D

var enemigo_escena = preload("res://enemigo_grande.tscn")
var tiempo_spawn = 0.0 

func _process(delta):
	tiempo_spawn += delta
	if tiempo_spawn >= 5.0:
		tiempo_spawn = 0.0
		
		var nuevo_enemigo = enemigo_escena.instantiate()
		
		
		add_child(nuevo_enemigo)
		
		var posicion_x = randf_range(-15.0, 15.0)
		nuevo_enemigo.global_position = Vector3(posicion_x, 0, -40)
