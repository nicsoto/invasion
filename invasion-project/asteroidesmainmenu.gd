extends Node3D

var velocidad_giro = 0.3 

func _process(delta):
	
	rotate_y(velocidad_giro * delta)
	rotate_x((velocidad_giro / 2.0) * delta) 
