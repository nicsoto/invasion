extends RefCounted
## Efecto breve, sin colisiones ni proyectiles que se acumulen en el mundo.

static func mostrar(mundo: Node, desde: Vector3, hasta: Vector3, color: Color) -> void:
	var distancia := desde.distance_to(hasta)
	if distancia < 0.01:
		return
	var trazo := MeshInstance3D.new()
	var malla := CylinderMesh.new()
	malla.top_radius = 0.018
	malla.bottom_radius = 0.018
	malla.height = distancia
	malla.radial_segments = 6
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	malla.material = material
	trazo.mesh = malla
	trazo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mundo.add_child(trazo)
	trazo.global_position = (desde + hasta) * 0.5
	trazo.quaternion = Quaternion(Vector3.UP, (hasta - desde).normalized())
	trazo.get_tree().create_timer(0.07, false).timeout.connect(trazo.queue_free)
