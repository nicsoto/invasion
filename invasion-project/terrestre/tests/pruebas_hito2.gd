extends SceneTree
## Regresiones con los assets, sonidos y cinemáticas reales del equipo.

const Demo = preload("res://terrestre/defensa/demo_defensa.tscn")
const Plataforma = preload("res://terrestre/defensa/plataforma_defensa.tscn")
const Personaje = preload("res://terrestre/personaje.tscn")
const Atacante = preload("res://terrestre/defensa/atacante_torre.tscn")

var comprobaciones := 0
var fallos := 0
var muertes := 0
var disparos := 0

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

func esperar_bajada(personaje: Node) -> void:
	for i in 240:
		if not personaje.en_transicion:
			break
		await physics_frame
	verificar(not personaje.en_transicion, "La animación de bajada termina y devuelve el control")

func limpiar() -> void:
	paused = false
	current_scene.queue_free()
	await process_frame
	await process_frame

func ejecutar() -> void:
	var juego = Demo.instantiate()
	juego.get_node("BaseAsteroide").preparacion = 120
	root.add_child(juego)
	current_scene = juego
	await pasos(3)
	var personaje = juego.personaje
	verificar(personaje.camara == personaje.camara_fps,
		"La cámara funciona con ambas interfaces usadas por el equipo")
	juego.nave.global_position = juego.punto_nave.global_position
	await tecla(KEY_E)
	verificar(personaje.en_transicion and personaje.camara_cinematica.current,
		"E reproduce la animación real con su cámara")
	personaje.take_damage(25)
	verificar(personaje.salud == 100 and not personaje.disparar(),
		"La bajada protege al personaje y no permite disparar durante la animación")
	await tecla(KEY_E)
	verificar(juego.a_pie, "E no permite subir mientras se está desembarcando")
	await tecla(KEY_P)
	var tiempo: float = personaje.animador.current_animation_position
	await pasos(15)
	verificar(paused and is_equal_approx(tiempo, personaje.animador.current_animation_position),
		"P pausa también la animación de desembarco")
	await tecla(KEY_P)
	await esperar_bajada(personaje)
	await pasos(15)
	verificar(personaje.activo and personaje.camara.current and juego.nave.visible,
		"Después de la animación reaparecen la nave y la cámara a pie")
	var antes: Vector3 = personaje.global_position
	var adelante: Vector3 = -personaje.camara.global_basis.z
	Input.action_press("pie_adelante")
	await pasos(20)
	Input.action_release("pie_adelante")
	verificar((personaje.global_position - antes).dot(adelante) > 0.5,
		"W avanza en la dirección de la mirada con el personaje compartido")
	personaje.disparo_realizado.connect(func(_acerto): disparos += 1)
	var hijos_antes: int = juego.get_child_count()
	personaje.disparar()
	personaje.disparar()
	verificar(disparos == 1 and juego.get_child_count() == hijos_antes + 1,
		"Un disparo produce un solo trazo y respeta la cadencia")
	personaje.take_damage(5)
	await process_frame
	verificar(juego.golpe.color.a > 0 and personaje.salud == 95,
		"El daño a pie tiene respuesta visual y actualiza la salud")
	juego.defensa.torre.recibir_ataque_pequeno(5)
	await process_frame
	verificar(juego.aviso.text.contains("bajo ataque") and juego.salud_torre.value == 175,
		"El HUD avisa cuando la torre está recibiendo daño")

	personaje.global_position = juego.punto_bajada.global_position
	personaje.velocity = Vector3.ZERO
	await pasos(2)
	await tecla(KEY_E)
	verificar(not juego.a_pie and juego.nave.camara.current,
		"Se puede volver a la nave después de la bajada animada")
	juego.bajar()
	juego.subir()
	await pasos(100)
	verificar(not personaje.activo and not personaje.en_transicion and juego.nave.camara.current
		and juego.nave.visible,
		"Cancelar una transición no reactiva después al personaje ni roba la cámara")

	juego.defensa.position.y = -60
	juego.nave.global_position = juego.punto_nave.global_position
	juego.bajar()
	await esperar_bajada(personaje)
	await pasos(20)
	verificar(personaje.salud == 95 and personaje.is_on_floor() and personaje.global_position.y < -50,
		"Una plataforma baja no mata al personaje por una altura fija del mapa anterior")
	personaje.murio.connect(func(): muertes += 1)
	personaje.global_position.y = personaje.altura_muerte - 1
	await pasos(3)
	verificar(personaje.salud == 0 and personaje.esta_muerto and not personaje.activo,
		"Caer fuera de la plataforma inicia una única muerte y desactiva el control")
	await pasos(160)
	verificar(muertes == 1 and paused and juego.resultado.text.begins_with("PILOTO DERROTADO"),
		"La cinemática de muerte termina con un mensaje de derrota")
	await tecla(KEY_P)
	verificar(paused, "La pausa no permite continuar después de la derrota")
	await tecla(KEY_R)
	await pasos(3)
	juego = current_scene
	verificar(not paused and not juego.terminado and juego.personaje.salud == 100 and juego.nave.camara.current,
		"R restaura salud, cámara y control tras la muerte animada")

	juego.nave.global_position = juego.punto_nave.global_position
	await tecla(KEY_E)
	await esperar_bajada(juego.personaje)
	juego.personaje.take_damage(100)
	await tecla(KEY_R)
	await pasos(165)
	juego = current_scene
	verificar(not juego.terminado and not paused and juego.nave.camara.current,
		"Reiniciar durante la muerte cancela sus eventos pendientes")
	juego.nave.global_position = juego.punto_nave.global_position
	await tecla(KEY_E)
	juego.defensa.torre.recibir_ataque_pequeno(180)
	await process_frame
	verificar(juego.terminado and paused and juego.resultado.text.begins_with("TORRE DESTRUIDA"),
		"Perder la torre durante el desembarco también termina la partida")
	await tecla(KEY_R)
	await pasos(100)
	verificar(not current_scene.terminado and current_scene.nave.visible and current_scene.nave.camara.current,
		"Reiniciar durante el desembarco no deja oculta la nave ni una cámara antigua")
	await limpiar()

	var mundo := Node3D.new()
	root.add_child(mundo)
	current_scene = mundo
	var a = Plataforma.instantiate()
	var b = Plataforma.instantiate()
	b.position.x = 65
	mundo.add_child(a)
	mundo.add_child(b)
	a.torre.recibir_ataque_pequeno(150)
	a.cupula.notificar_bloqueo()
	await pasos(2)
	verificar(a.torre.salud == 30 and b.torre.salud == 180
		and b.torre.nucleo.material_override.albedo_color.g > 0.9,
		"El daño y el color crítico de una torre no afectan a otra plataforma")
	verificar(a.cupula.visual.material_override.get_shader_parameter("impacto") > 0
		and b.cupula.visual.material_override.get_shader_parameter("impacto") == 0,
		"El destello de una cúpula no se comparte con todas las demás")
	personaje = Personaje.instantiate()
	personaje.position = b.to_global(Vector3(0, 0.2, 10))
	mundo.add_child(personaje)
	var atacante = Atacante.instantiate()
	atacante.position = Vector3(0, 4, -10)
	atacante.configurar(a.torre, a.cupula, atacante.position)
	mundo.add_child(atacante)
	atacante.set_physics_process(false)
	verificar(not atacante.recibir_disparo_desde(25, personaje) and atacante.salud == 75,
		"Estar en otra cúpula no permite dañar a los atacantes de esta torre")
	personaje.global_position = a.to_global(Vector3(0, 0.2, 10))
	verificar(atacante.recibir_disparo_desde(25, personaje) and atacante.salud == 50,
		"Entrar en la cúpula correcta permite defender esa torre")
	verificar(atacante.get_node("Cuerpo").mesh is ArrayMesh
		and atacante.sonido_disparo.stream != null,
		"Los atacantes reutilizan el modelo y sonido incorporados por Antonia")
	await limpiar()
	paused = false
	if is_instance_valid(current_scene):
		current_scene.queue_free()
	await create_timer(0.25).timeout
	print("RESULTADO: %d comprobaciones, %d fallos" % [comprobaciones, fallos])
	quit(1 if fallos else 0)
