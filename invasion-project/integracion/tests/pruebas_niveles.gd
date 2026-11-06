extends SceneTree
## Ejecutar: godot --headless --path invasion-project --script res://integracion/tests/pruebas_niveles.gd

const Partida = preload("res://integracion/partida.gd")

var _fallos := 0
var _comprobaciones := 0

func _initialize() -> void:
	_ejecutar.call_deferred()

func verificar(condicion: bool, descripcion: String) -> void:
	_comprobaciones += 1
	if condicion:
		print("OK: " + descripcion)
	else:
		_fallos += 1
		push_error("FALLO: " + descripcion)

func pasos(cantidad: int) -> void:
	for i in range(cantidad):
		await physics_frame

func tecla(codigo: Key) -> void:
	var evento := InputEventKey.new()
	evento.physical_keycode = codigo
	evento.keycode = codigo
	evento.pressed = true
	root.push_input(evento)
	await process_frame

func esperar_escena(ruta: String, maximo := 600) -> void:
	for i in range(maximo):
		if current_scene and current_scene.scene_file_path == ruta:
			break
		await process_frame
	await process_frame
	await process_frame

func preparar(nivel) -> void:
	nivel.personaje.reproducir_cinematicas = false
	nivel.espera_resultado = 0.2
	nivel.intervalo_enemigos = 9999.0

func bajar_en(nivel, plataforma) -> void:
	nivel.nave.global_position = plataforma.get_node("PuntoNave").global_position + Vector3(0, 6, 8)
	await pasos(3)
	await process_frame
	await tecla(KEY_E)
	await pasos(30)

func eliminar_oleada(nivel, plataforma) -> void:
	plataforma.intervalo_llegadas = 0.1
	plataforma.tiempo_restante = 0.0
	for i in range(900):
		if nivel.terminado or plataforma.estado == plataforma.Estado.COMPLETADA:
			break
		for atacante in plataforma.atacantes.get_children():
			if atacante.salud > 0:
				atacante.recibir_disparo_desde(1000, nivel.personaje)
		await physics_frame

func _ejecutar() -> void:
	# Menú inicial
	verificar(ProjectSettings.get_setting("application/run/main_scene") == "uid://daewek8nhinha",
		"La escena principal del proyecto es el menú")
	Partida.resultado = ""
	change_scene_to_file(Partida.MENU)
	await esperar_escena(Partida.MENU)
	var menu = current_scene
	verificar(menu.menu_principal.visible and not menu.victoria_menu.visible and not menu.derrota_menu.visible,
		"El menú parte en la pantalla principal, sin paneles de resultado encima")
	menu._on_boton_niveles_pressed()
	menu.get_node("niveles menú/VBoxContainer/boton nivel1").pressed.emit()
	await esperar_escena(Partida.ruta_nivel(1))
	verificar(current_scene.scene_file_path == Partida.ruta_nivel(1), "El botón Nivel 1 abre el nivel 1")

	# Nivel 1: una plataforma, victoria
	var nivel = current_scene
	preparar(nivel)
	var plataforma = nivel.plataforma_activa()
	verificar(nivel.lista_plataformas.size() == 1 and plataforma.estado == plataforma.Estado.PREPARACION,
		"El nivel 1 tiene una plataforma y su defensa comienza al entrar")
	await pasos(2)
	await process_frame
	verificar(nivel.aviso.text.begins_with("Plataforma 1:"), "El aviso indica la distancia a la plataforma activa")
	await tecla(KEY_P)
	verificar(paused and nivel.velo.visible, "P pausa el nivel")
	await tecla(KEY_P)
	verificar(not paused, "P quita la pausa")
	await bajar_en(nivel, plataforma)
	verificar(nivel.a_pie and nivel.plataforma_actual == plataforma, "E cerca de la plataforma baja al personaje en ella")
	await eliminar_oleada(nivel, plataforma)
	verificar(nivel.terminado and Partida.resultado == "victoria", "Defender la única plataforma gana el nivel 1")
	await esperar_escena(Partida.MENU)
	menu = current_scene
	verificar(menu.victoria_menu.visible and menu.titulo_cleared.visible and not menu.menu_principal.visible,
		"Al ganar, el menú muestra la pantalla de victoria (BASE CLEARED)")

	# Nivel 2: dos plataformas en secuencia, derrota y reintento
	menu.jugar_nivel(2)
	await esperar_escena(Partida.ruta_nivel(2))
	nivel = current_scene
	preparar(nivel)
	var primera = nivel.lista_plataformas[0]
	var segunda = nivel.lista_plataformas[1]
	verificar(nivel.lista_plataformas.size() == 2 and segunda.estado == segunda.Estado.ESPERA,
		"En el nivel 2 la segunda plataforma espera mientras se defiende la primera")
	await bajar_en(nivel, primera)
	await eliminar_oleada(nivel, primera)
	verificar(not nivel.terminado and nivel.indice_activa == 1 and segunda.estado == segunda.Estado.PREPARACION,
		"Al defender la primera, se activa la segunda plataforma")
	nivel.personaje.global_position = nivel.nave.global_position + Vector3(2, 0.5, 0)
	await pasos(5)
	await tecla(KEY_E)
	await pasos(5)
	verificar(not nivel.a_pie, "El jugador puede volver a la nave para ir a la siguiente plataforma")
	await bajar_en(nivel, segunda)
	verificar(nivel.a_pie and nivel.plataforma_actual == segunda
		and nivel.nave.global_position.distance_to(segunda.get_node("PuntoNave").global_position) < 0.1,
		"Se aterriza en la segunda plataforma y la nave queda estacionada ahí")
	segunda.torre.recibir_ataque_pequeno(segunda.torre.salud)
	verificar(nivel.terminado and Partida.resultado == "derrota", "Si destruyen la torre, se pierde el nivel")
	await esperar_escena(Partida.MENU)
	menu = current_scene
	verificar(menu.derrota_menu.visible and menu.titulo_derrota.visible, "Al perder, el menú muestra GAME OVER")
	menu.get_node("derrota menu/VBoxContainer/Button").pressed.emit()
	await esperar_escena(Partida.ruta_nivel(2))
	verificar(current_scene.scene_file_path == Partida.ruta_nivel(2), "Reintentar vuelve a abrir el mismo nivel")

	# Enemigos espaciales y pausa con menú
	nivel = current_scene
	preparar(nivel)
	nivel.intervalo_enemigos = 0.05
	await pasos(40)
	verificar(nivel.enemigos.size() == nivel.max_enemigos_espaciales,
		"Aparecen enemigos espaciales hasta el máximo del nivel")
	var lejos := true
	for enemigo in nivel.enemigos:
		lejos = lejos and enemigo.global_position.distance_to(nivel.nave.global_position) > 60
	verificar(lejos, "Los enemigos espaciales aparecen lejos del jugador")
	await tecla(KEY_ESCAPE)
	verificar(paused, "Esc también pausa el nivel en vez de cerrar el juego")
	await tecla(KEY_M)
	await esperar_escena(Partida.MENU)
	verificar(current_scene.scene_file_path == Partida.MENU and current_scene.menu_principal.visible,
		"M desde la pausa vuelve al menú principal")

	# Nivel 3: tres plataformas, la última da la victoria final
	current_scene.jugar_nivel(3)
	await esperar_escena(Partida.ruta_nivel(3))
	nivel = current_scene
	preparar(nivel)
	verificar(nivel.lista_plataformas.size() == 3, "El nivel 3 tiene tres plataformas repartidas")
	for i in range(3):
		nivel.lista_plataformas[i].defensa_completada.emit()
		await process_frame
	verificar(nivel.terminado and Partida.resultado == "victoria", "Defender las tres plataformas gana el nivel 3")
	await esperar_escena(Partida.MENU)
	verificar(current_scene.titulo_victoria.visible, "Ganar el último nivel muestra VICTORIA")

	# Derrota por la nave
	current_scene.jugar_nivel(1)
	await esperar_escena(Partida.ruta_nivel(1))
	nivel = current_scene
	preparar(nivel)
	nivel.nave.take_damage(1000)
	await pasos(5)
	verificar(nivel.terminado and Partida.resultado == "derrota", "Si destruyen la nave, se pierde el nivel")

	paused = false
	print("RESULTADO: %d comprobaciones, %d fallos" % [_comprobaciones, _fallos])
	quit(1 if _fallos else 0)
