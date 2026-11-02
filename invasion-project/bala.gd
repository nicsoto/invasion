extends Area3D

const ReglasCupula = preload("res://terrestre/defensa/reglas_cupula.gd")

var disparador = ""

func _physics_process(delta):
	var siguiente: Vector3 = global_position - global_basis.z * 40.0 * delta
	var escudo := ReglasCupula.interceptar(get_tree(), global_position, siguiente, &"espacial")
	if not escudo.is_empty():
		global_position = escudo.position
		queue_free()
		return
	global_position = siguiente

func _on_body_entered(body):
	
	
	if disparador == "enemigo" and body.is_in_group("enemigo"):
		return
		
	
	if disparador == "jugador" and body.is_in_group("jugador"):
		return
		
	
	if body.has_method("take_damage"):
		body.take_damage(25)
		queue_free()


func _on_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	pass # Replace with function body.
	
func hacer_enemiga():
	var material_clon = $MeshInstance3D.get_active_material(0).duplicate()
	material_clon.albedo_color = Color.RED
	if material_clon.emission_enabled:
		material_clon.emission = Color.RED
	$MeshInstance3D.material_override = material_clon
