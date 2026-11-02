extends RefCounted
## Consulta compartida por los disparos instantáneos y las balas de la nave.

static func interceptar(arbol: SceneTree, desde: Vector3, hasta: Vector3,
		tipo: StringName) -> Dictionary:
	var resultado := {}
	var distancia := INF
	for cupula in arbol.get_nodes_in_group("cupula_defensa"):
		var impacto: Dictionary = cupula.interseccion_bloqueada(desde, hasta, tipo)
		if not impacto.is_empty():
			var nueva_distancia := desde.distance_squared_to(impacto.position)
			if nueva_distancia < distancia:
				distancia = nueva_distancia
				resultado = impacto
	if not resultado.is_empty():
		resultado.cupula.notificar_bloqueo()
	return resultado
