extends StaticBody3D

var rotacion_random = Vector3()
var jugador = null

func _ready():
	jugador = get_tree().get_first_node_in_group("jugador")
	
	rotacion_random = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1))

func _physics_process(delta):
	
	$MeshInstance3D.rotate_x(rotacion_random.x * delta)
	$MeshInstance3D.rotate_y(rotacion_random.y * delta)
	$MeshInstance3D.rotate_z(rotacion_random.z * delta)
	
	
	if jugador and global_position.distance_to(jugador.global_position) > 300.0:
		queue_free()

func take_damage(cantidad):
	
	queue_free()
