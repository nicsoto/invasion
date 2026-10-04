extends Node3D

var asteroide_escena = preload("res://asteroide.tscn")
var tiempo_spawn = 0.0

func _process(delta):
	tiempo_spawn += delta
	
	
	if tiempo_spawn >= 1.5: 
		tiempo_spawn = 0.0
		
		var jugador = get_tree().get_first_node_in_group("jugador")
		if not jugador: return
		
		var nuevo_asteroide = asteroide_escena.instantiate()
		get_tree().current_scene.add_child(nuevo_asteroide)
		
		
		var desvio = Vector3(
			randf_range(-200, 200), 
			randf_range(-80, 80), 
			randf_range(-200, 200)
		)
		
		if desvio.length() < 100.0:
			desvio = desvio.normalized() * 100.0
			
		nuevo_asteroide.global_position = jugador.global_position + desvio
		
		
		var escala = 1.0
		var suerte = randf() 
		
		if suerte < 0.70:
			
			escala = randf_range(0.5, 3.0)
		else:
			
			escala = randf_range(4.0, 10.0)
			
		nuevo_asteroide.scale = Vector3(escala, escala, escala)
