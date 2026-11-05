extends SceneTree
## Ejecutar con --headless --path invasion-project --script res://terrestre/tests/pruebas_defensa.gd

const Plataforma = preload("res://terrestre/defensa/plataforma_defensa.tscn")
const Personaje = preload("res://terrestre/personaje.tscn")
const Atacante = preload("res://terrestre/defensa/atacante_torre.tscn")
const Bala = preload("res://bala.tscn")
const Demo = preload("res://terrestre/defensa/demo_defensa.tscn")

var comprobaciones := 0
var fallos := 0
var destrucciones := 0

func _initialize() -> void:
	call_deferred("ejecutar")

func verificar(condicion: bool, descripcion: String) -> void:
	comprobaciones += 1
	if condicion:
		print("OK: ", descripcion)
	else:
		fallos += 1
		push_error("FALLO: " + descripcion)

func pasos(cantidad: int) -> void:
	for i in cantidad:
		await physics_frame

func tecla(codigo: Key) -> void:
	var evento := InputEventKey.new()
	evento.physical_keycode = codigo
	evento.pressed = true
	root.push_input(evento)
	await process_frame
	evento = evento.duplicate()
	evento.pressed = false
	root.push_input(evento)
	await process_frame

func limpiar() -> void:
	paused = false
	current_scene.queue_free()
	await process_frame

func ejecutar() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)
	current_scene = mundo
	var plataforma = Plataforma.instantiate()
	mundo.add_child(plataforma)
	var cupula = plataforma.cupula
	verificar(cupula.contiene(Vector3(0, 2, 0)) and not cupula.contiene(Vector3(0, -1, 0)),
		"La zona distingue interior, exterior y subsuelo")
	verificar(not cupula.interseccion_bloqueada(Vector3(0, 3, 30), Vector3(0, 3, -30), &"espacial").is_empty(),
		"Un disparo rápido no atraviesa toda la cúpula entre dos fotogramas")
	verificar(cupula.interseccion_bloqueada(Vector3(30, 3, 30), Vector3(30, 3, -30), &"espacial").is_empty(),
		"Los disparos que pasan lejos de la plataforma siguen su trayectoria")
	verificar(cupula.interseccion_bloqueada(Vector3(0, 3, 30), Vector3(0, 3, 0), &"enemigo_pequeno").is_empty(),
		"Los ataques pequeños atraviesan la cúpula")
	verificar(not cupula.interseccion_bloqueada(Vector3(0, 3, 0), Vector3(0, 3, 5), &"espacial").is_empty(),
		"Entrar con la nave no evita la restricción del armamento espacial")
	verificar(cupula.interseccion_bloqueada(Vector3(0, 3, 0), Vector3(0, 3, 30), &"terrestre").is_empty(),
		"El arma terrestre puede disparar hacia fuera desde el interior")
	verificar(not cupula.interseccion_bloqueada(Vector3(0, -8, 0), Vector3(0, 3, 0), &"espacial").is_empty(),
		"La base de la cúpula bloquea disparos desde debajo del asteroide")
	plataforma.position = Vector3(100, 12, -50)
	plataforma.rotation.y = 0.6
	verificar(cupula.contiene(plataforma.to_global(Vector3(0, 2, 0))),
		"Una plataforma trasladada y girada conserva su zona de defensa")
	plataforma.position = Vector3.ZERO
	plataforma.rotation = Vector3.ZERO
	var bala = Bala.instantiate()
	bala.disparador = "jugador"
	mundo.add_child(bala)
	bala.global_position = Vector3(0, 3, 30)
	bala._physics_process(2.0)
	verificar(bala.is_queued_for_deletion() and bala.global_position.z > 18,
		"La bala real de la nave se consume al golpear la cúpula")

	var jugador = Personaje.instantiate()
	jugador.position = Vector3(0, 0.2, 10)
	mundo.add_child(jugador)
	var enemigo = Atacante.instantiate()
	enemigo.position = Vector3(0, 2, 4)
	enemigo.configurar(plataforma.torre, cupula, enemigo.position)
	mundo.add_child(enemigo)
	enemigo.set_physics_process(false)
	await pasos(20)
	jugador.camara.look_at(enemigo.global_position)
	jugador.disparar()
	verificar(enemigo.salud == 50, "Un disparo terrestre real desde dentro daña al asaltante")
	enemigo.take_damage(25)
	verificar(enemigo.salud == 50, "El daño espacial genérico no daña al asaltante protegido")
	jugador.position = Vector3(23, 1.2, 0)
	await pasos(20)
	jugador.camara.look_at(enemigo.global_position)
	jugador.disparar()
	verificar(enemigo.salud == 50, "Disparar a pie desde la isla exterior queda bloqueado")
	jugador.set_activo(false)
	verificar(not enemigo.recibir_disparo_desde(25, jugador) and enemigo.salud == 50,
		"Un personaje inactivo no puede autorizar daño terrestre")
	enemigo.queue_free()
	jugador.set_activo(true)
	jugador.position = Vector3(0, 0.2, 10)
	await pasos(20)
	jugador.camara.look_at(plataforma.torre.punto_de_ataque())
	jugador.disparar()
	verificar(plataforma.torre.salud == 180, "El arma del jugador no daña su propia torre")
	plataforma.torre.destruida.connect(func(): destrucciones += 1)
	plataforma.torre.recibir_ataque_pequeno(500)
	plataforma.torre.recibir_ataque_pequeno(500)
	verificar(plataforma.torre.salud == 0 and destrucciones == 1,
		"La destrucción ocurre una vez, con la salud limitada a cero")
	await limpiar()

	var juego = Demo.instantiate()
	juego.get_node("PersonajeTerrestre").reproducir_cinematicas = false
	root.add_child(juego)
	current_scene = juego
	var defensa = juego.defensa
	defensa.cantidad_atacantes = 2
	defensa.intervalo_llegadas = 4.0
	defensa.tiempo_restante = 0.0
	await pasos(5)
	verificar(not juego.a_pie and defensa.generados == 1,
		"La oleada empieza aunque el jugador permanezca en la nave")
	juego.nave.global_position = juego.punto_nave.global_position + Vector3(0, 5, 8)
	await tecla(KEY_E)
	await pasos(10)
	verificar(juego.a_pie and juego.personaje.activo, "E permite bajar en la nueva plataforma")
	var primero = defensa.atacantes.get_child(0)
	primero.set_physics_process(false)
	primero.global_position = defensa.to_global(Vector3(-4, 2.5, 6))
	await pasos(2)
	for i in 3:
		juego.personaje.camara.look_at(primero.global_position)
		juego.personaje.disparar()
		await pasos(16)
	verificar(not juego.terminado and defensa.restantes() == 1,
		"Eliminar al primer enemigo no da victoria mientras falten llegadas")
	await tecla(KEY_P)
	var tiempo: float = defensa.tiempo_restante
	var posicion: Vector3 = juego.personaje.global_position
	Input.action_press("pie_adelante")
	await pasos(20)
	Input.action_release("pie_adelante")
	verificar(paused and defensa.tiempo_restante == tiempo and juego.personaje.global_position == posicion,
		"La pausa detiene la oleada y el movimiento del personaje")
	await tecla(KEY_P)
	verificar(not paused, "P permite continuar la defensa")
	# Dejar que llegue el segundo enemigo y comprobar ataques físicos reales.
	juego.personaje.global_position = juego.punto_bajada.global_position
	await pasos(2)
	await tecla(KEY_E)
	verificar(not juego.a_pie, "Se puede volver a la nave durante la defensa")
	await pasos(350)
	verificar(defensa.torre.salud < 180 and defensa.torre.salud > 0,
		"Los asaltantes dañan realmente la torre mientras el jugador está en la nave")
	await tecla(KEY_E)
	await pasos(10)
	var segundo = defensa.atacantes.get_child(0)
	segundo.set_physics_process(false)
	segundo.global_position = defensa.to_global(Vector3(-4, 2.5, 6))
	await pasos(2)
	for i in 3:
		juego.personaje.camara.look_at(segundo.global_position)
		juego.personaje.disparar()
		await pasos(16)
	verificar(juego.terminado and paused and juego.resultado.text.begins_with("PLATAFORMA DEFENDIDA")
		and juego.contador.text == "AMENAZAS RESTANTES: 0",
		"Eliminar la oleada completa con disparos reales muestra la victoria")
	await tecla(KEY_P)
	verificar(paused, "P no reanuda una partida terminada")
	var instancia := juego.get_instance_id()
	await tecla(KEY_R)
	await pasos(3)
	juego = current_scene
	juego.personaje.reproducir_cinematicas = false
	verificar(juego.get_instance_id() != instancia and not paused and juego.defensa.torre.salud == 180,
		"R reinicia la escena, la torre, el control y la oleada")
	juego.defensa.torre.recibir_ataque_pequeno(180)
	await process_frame
	verificar(paused and juego.resultado.text.begins_with("TORRE DESTRUIDA"),
		"Destruir la torre termina la partida con derrota")
	await tecla(KEY_R)
	await pasos(3)
	juego = current_scene
	juego.personaje.reproducir_cinematicas = false
	juego.nave.global_position = juego.punto_nave.global_position
	await tecla(KEY_E)
	juego.personaje.take_damage(100)
	await process_frame
	verificar(paused and juego.resultado.text.begins_with("PILOTO DERROTADO"),
		"La muerte del piloto también termina la defensa")
	await limpiar()
	paused = false
	if is_instance_valid(current_scene):
		current_scene.queue_free()
	await create_timer(0.25).timeout
	print("RESULTADO: %d comprobaciones, %d fallos" % [comprobaciones, fallos])
	quit(1 if fallos else 0)
