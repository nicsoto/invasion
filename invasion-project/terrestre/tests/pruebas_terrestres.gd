extends SceneTree
## Ejecutar: godot --headless --path invasion-project --script res://terrestre/tests/pruebas_terrestres.gd

const Personaje = preload("res://terrestre/personaje.tscn")
const Enemigo = preload("res://terrestre/enemigo_especial.tscn")
const BalaEspacial = preload("res://bala.tscn")
const Demo = preload("res://terrestre/demo_terrestre.tscn")

var _fallos := 0
var _comprobaciones := 0
var _muertes := 0
var _derrotas := 0

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

func _bloque(mundo: Node3D, posicion: Vector3, dimensiones: Vector3) -> StaticBody3D:
	var cuerpo := StaticBody3D.new()
	var forma := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = dimensiones
	forma.shape = caja
	cuerpo.add_child(forma)
	mundo.add_child(cuerpo)
	cuerpo.position = posicion
	return cuerpo

func _ejecutar() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)
	current_scene = mundo
	_bloque(mundo, Vector3(0, -0.5, 0), Vector3(40, 1, 40))
	var jugador = Personaje.instantiate()
	jugador.position = Vector3(0, 0.1, 4)
	mundo.add_child(jugador)
	jugador.murio.connect(func(): _muertes += 1)
	await _pasos(20)
	_verificar(jugador.is_on_floor(), "El personaje aterriza sobre una superficie física")
	Input.action_press("pie_derecha")
	await _pasos(25)
	Input.action_release("pie_derecha")
	_verificar(jugador.position.x > 1, "WASD desplaza el personaje")
	Input.action_press("pie_saltar")
	await _pasos(3)
	Input.action_release("pie_saltar")
	await _pasos(12)
	_verificar(jugador.position.y > 0.5, "El salto despega del suelo")
	var velocidad_y: float = jugador.velocity.y
	Input.action_press("pie_saltar")
	await _pasos(2)
	Input.action_release("pie_saltar")
	_verificar(jugador.velocity.y < velocidad_y, "No hay doble salto en el aire")
	await _pasos(90)
	_verificar(jugador.is_on_floor(), "La gravedad devuelve al personaje al suelo")

	jugador.position = Vector3(0, 0.1, 4)
	jugador.velocity = Vector3.ZERO
	var enemigo = Enemigo.instantiate()
	enemigo.position = Vector3(0, 1.6, -8)
	enemigo.radio_patrulla = 0
	mundo.add_child(enemigo)
	enemigo.set_physics_process(false)
	enemigo.derrotado.connect(func(): _derrotas += 1)
	var cobertura := _bloque(mundo, Vector3(0, 1.5, -2), Vector3(4, 3, 1))
	await _pasos(5)
	jugador.camara.look_at(enemigo.global_position)
	_verificar(jugador.disparar(), "El arma permite el primer disparo")
	_verificar(not jugador.disparar(), "La cadencia impide disparos instantáneos repetidos")
	_verificar(enemigo.salud == 100, "La cobertura bloquea el daño del arma a pie")
	Input.action_press("pie_adelante")
	await _pasos(85)
	Input.action_release("pie_adelante")
	_verificar(jugador.position.z > -1.3, "El personaje no atraviesa las rocas")
	jugador.position = Vector3(0, 0.1, 4)
	jugador.velocity = Vector3.ZERO
	cobertura.queue_free()
	await _pasos(5)
	var bala = BalaEspacial.instantiate()
	bala.disparador = "jugador"
	mundo.add_child(bala)
	bala._on_body_entered(enemigo)
	_verificar(enemigo.salud == 100, "La bala espacial existente no daña al enemigo especial")
	jugador.camara.look_at(enemigo.global_position)
	jugador.disparar()
	_verificar(enemigo.salud == 75, "El disparo terrestre sí atraviesa el blindaje especial")
	for disparo in range(3):
		await _pasos(16)
		jugador.disparar()
	_verificar(_derrotas == 1, "Cuatro impactos derrotan al centinela una sola vez")
	await _pasos(5)

	var atacante = Enemigo.instantiate()
	atacante.position = Vector3(0, 1.6, -8)
	atacante.radio_patrulla = 0
	atacante.intervalo_ataque = 0.3
	atacante.tiempo_aviso = 0.1
	mundo.add_child(atacante)
	cobertura = _bloque(mundo, Vector3(0, 1.5, -2), Vector3(4, 3, 1))
	await _pasos(140)
	_verificar(jugador.salud == 100, "La cobertura también bloquea los ataques enemigos")
	cobertura.queue_free()
	await _pasos(35)
	_verificar(jugador.salud < 100, "El centinela ataca al personaje cuando hay línea de visión")
	jugador.set_activo(false)
	var salud_guardada: int = jugador.salud
	var posicion_guardada: Vector3 = jugador.position
	Input.action_press("pie_adelante")
	await _pasos(35)
	Input.action_release("pie_adelante")
	_verificar(jugador.salud == salud_guardada, "El personaje inactivo no recibe daño")
	_verificar(jugador.position == posicion_guardada, "El personaje inactivo no responde al movimiento")
	_verificar(not jugador.is_in_group("jugador"), "Desactivar retira al personaje de los blancos activos")
	_verificar(jugador.colision.disabled and not jugador.disparar(), "Desactivar elimina colisiones y disparos")
	jugador.set_activo(true)
	atacante.set_physics_process(false)
	await _pasos(2)
	_verificar(jugador.is_in_group("jugador") and jugador.camara.current,
		"Reactivar recupera el control y la cámara")
	jugador.take_damage(500)
	jugador.take_damage(500)
	_verificar(jugador.salud == 0 and _muertes == 1 and not jugador.activo,
		"La muerte ocurre una vez y desactiva al personaje")

	var caida = Personaje.instantiate()
	caida.position = Vector3(0, -30, 0)
	mundo.add_child(caida)
	await _pasos(3)
	_verificar(caida.salud == 0, "Caer fuera del asteroide termina el intento")
	mundo.queue_free()
	await process_frame

	var demo = Demo.instantiate()
	root.add_child(demo)
	current_scene = demo
	await _pasos(5)
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape)
	await process_frame
	_verificar(paused, "Escape pausa la demo")
	root.push_input(escape.duplicate())
	await process_frame
	_verificar(not paused, "Escape permite continuar")
	for centinela in get_nodes_in_group("enemigo_especial"):
		centinela.recibir_disparo_terrestre(100)
	_verificar(paused and demo.get_node("HUD/Mensaje").text.begins_with("ZONA DESPEJADA"),
		"La demo reconoce la victoria al derrotar a todos los enemigos")
	var reinicio := InputEventKey.new()
	var instancia_anterior: int = demo.get_instance_id()
	reinicio.physical_keycode = KEY_R
	reinicio.pressed = true
	root.push_input(reinicio)
	await process_frame
	await _pasos(5)
	_verificar(not paused and current_scene.get_instance_id() != instancia_anterior
		and get_nodes_in_group("enemigo_especial").size() == 2,
		"R reinicia la escena y restaura los enemigos")
	print("RESULTADO: %d comprobaciones, %d fallos" % [_comprobaciones, _fallos])
	quit(1 if _fallos else 0)
