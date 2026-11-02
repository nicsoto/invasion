extends Area3D

var disparador = ""

func _physics_process(delta):
	position += transform.basis * Vector3(0, 0, -40.0) * delta

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
