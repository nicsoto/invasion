extends SceneTree
## Ejecutar: godot --headless --path invasion-project --script res://integracion/tests/pruebas_integracion.gd

const Juego = preload("res://integracion/juego.tscn")

var _fallos := 0
var _comprobaciones := 0

func _initialize() -> void:
	_ejecutar.call_deferred()

func _verificar(condicion: bool, descripcion: String) -> void:
	_comprobaciones += 1
	if not condicion:
		_fallos += 1
		push_error("FALLO: " + descripcion)
	else:
		print("OK: " + descripcion)

func _pasos(cantidad: int) -> void:
	for paso in range(cantidad):
		await physics_frame

func _tecla(codigo: Key) -> void:
	var evento := InputEventKey.new()
	evento.physical_keycode = codigo
	evento.pressed = true
	root.push_input(evento)
	await process_frame

func _ejecutar() -> void:
	var juego = Juego.instantiate()
	root.add_child(juego)
	current_scene = juego
	var nave = juego.nave
	var personaje = juego.personaje
	# Sin enemigos ni asteroides aleatorios para que la prueba sea repetible.
	juego.get_node("Spawner").queue_free()
	juego.get_node("SpawnerAsteroides").queue_free()
	await _pasos(5)

	_verificar(nave.esta_activa and not personaje.activo, "El juego empieza en la nave")
	_verificar(nave.camara.current, "Al empezar se usa la cámara de la nave")
	_verificar(get_first_node_in_group("jugador") == nave, "Los enemigos apuntan a la nave al empezar")

	await _tecla(KEY_E)
	_verificar(not juego.a_pie, "Lejos del asteroide, E no hace bajar")

	nave.global_position = juego.punto_nave.global_position + Vector3(0, 8, 10)
	await _pasos(2)
	await _pasos(1)
	await process_frame
	_verificar(juego.aviso.text == "E: aterrizar y bajar", "Cerca del asteroide aparece el aviso para bajar")
	await _tecla(KEY_E)
	_verificar(juego.a_pie and personaje.activo and not nave.esta_activa, "E cerca del asteroide cambia a modo a pie")
	_verificar(personaje.camara.current and not nave.camara.current, "A pie se usa la cámara del personaje")
	_verificar(nave.global_position.distance_to(juego.punto_nave.global_position) < 0.01,
		"La nave queda estacionada en el asteroide")
	_verificar(get_nodes_in_group("jugador") == [personaje], "A pie, solo el personaje es blanco de los enemigos")
	_verificar(not nave.barra_salud.visible and juego.salud_pie.visible, "El HUD muestra la salud a pie")

	await _pasos(40)
	_verificar(personaje.is_on_floor(), "El personaje cae y queda parado sobre el asteroide")
	var antes: Vector3 = personaje.global_position
	Input.action_press("pie_adelante")
	await _pasos(30)
	Input.action_release("pie_adelante")
	_verificar(personaje.global_position.distance_to(antes) > 1.0, "A pie, WASD mueve al personaje")
	var posicion_nave: Vector3 = nave.global_position
	Input.action_press("arriba")
	await _pasos(20)
	Input.action_release("arriba")
	_verificar(nave.global_position.distance_to(posicion_nave) < 0.01, "A pie, la nave estacionada no se mueve")

	var salud_nave: int = nave.salud
	nave.take_damage(25)
	_verificar(nave.salud == salud_nave, "La nave estacionada no recibe daño")
	_verificar(personaje.disparar(), "A pie se puede disparar")

	personaje.global_position = nave.global_position + Vector3(12, 0.5, 0)
	await _pasos(10)
	await _tecla(KEY_E)
	_verificar(juego.a_pie, "Lejos de la nave, E no hace subir")

	personaje.global_position = juego.punto_bajada.global_position
	personaje.velocity = Vector3.ZERO
	await _pasos(10)
	await process_frame
	_verificar(juego.aviso.text == "E: subir a la nave", "Cerca de la nave aparece el aviso para subir")
	await _tecla(KEY_E)
	await _pasos(2)
	_verificar(not juego.a_pie and nave.esta_activa and not personaje.activo,
		"E cerca de la nave vuelve a la nave (y no se baja de nuevo en el mismo instante)")
	_verificar(nave.camara.current and not personaje.camara.current, "Al subir vuelve la cámara de la nave")
	_verificar(get_nodes_in_group("jugador") == [nave], "Al subir, la nave vuelve a ser el blanco")
	posicion_nave = nave.global_position
	Input.action_press("ascender")
	await _pasos(20)
	Input.action_release("ascender")
	_verificar(nave.global_position.y > posicion_nave.y + 1.0, "Después de subir, la nave vuelve a volar")

	await _tecla(KEY_E)
	_verificar(juego.a_pie, "Se puede bajar de nuevo")
	await _pasos(10)
	await _tecla(KEY_P)
	_verificar(paused and nave.menu_pausa.visible, "P pausa el juego también a pie")
	await _tecla(KEY_P)
	_verificar(not paused, "P quita la pausa")

	personaje.take_damage(personaje.salud)
	await process_frame
	_verificar(paused and nave.menu_muerte.visible, "Si el personaje muere aparece el menú de muerte")
	paused = false

	print("RESULTADO: %d comprobaciones, %d fallos" % [_comprobaciones, _fallos])
	quit(1 if _fallos else 0)
