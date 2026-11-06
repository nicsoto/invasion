extends "res://integracion/juego.gd"
## Nivel jugable: une la nave, el personaje, las plataformas de defensa y los enemigos espaciales.
## Las plataformas se defienden en orden; al defender la última se gana el nivel.

const Partida = preload("res://integracion/partida.gd")
const EnemigoGrande = preload("res://enemigo_grande.tscn")
const SonidoVictoria = preload("res://Sonido/you win_victory-midi-by-kleber-kgf.mp3")
const SonidoDerrota = preload("res://Sonido/you lose adamweeden.wav")

@export var numero := 1
@export var max_enemigos_espaciales := 1
@export var intervalo_enemigos := 20.0
@export var distancia_aparicion := 90.0
@export var espera_resultado := 3.0

var terminado := false
var indice_activa := 0
var enemigos: Array = []
var _tiempo_enemigo := 0.0
var _impacto := 0.0
var _aviso_escudo := 0.0
var _aviso_torre := 0.0
var _aviso_siguiente := 0.0
var _golpe_piloto := 0.0
var _salud_piloto_anterior := 100
var _salud_torre_anterior := 0

@onready var lista_plataformas: Array = $Plataformas.get_children()
@onready var titulo: Label = $HUD/Panel/Margen/Columna/Titulo
@onready var objetivo: Label = $HUD/Panel/Margen/Columna/Objetivo
@onready var estado: Label = $HUD/Panel/Margen/Columna/Estado
@onready var texto_torre: Label = $HUD/Panel/Margen/Columna/Torre
@onready var barra_torre: ProgressBar = $HUD/Panel/Margen/Columna/BarraTorre
@onready var texto_piloto: Label = $HUD/Piloto
@onready var velo: ColorRect = $HUD/Velo
@onready var resultado: Label = $HUD/Resultado
@onready var golpe: ColorRect = $HUD/Golpe
@onready var sonido_torre: AudioStreamPlayer = $SonidoTorre
@onready var sonido_resultado: AudioStreamPlayer = $SonidoResultado

func _ready():
	for plataforma in lista_plataformas:
		plataforma.add_to_group("plataforma_aterrizaje")
	super._ready()
	Partida.nivel_actual = numero
	Partida.resultado = ""
	process_mode = Node.PROCESS_MODE_ALWAYS
	for hijo in get_children():
		hijo.process_mode = Node.PROCESS_MODE_PAUSABLE
	sonido_resultado.process_mode = Node.PROCESS_MODE_ALWAYS
	nave.get_node("HUD").hide()
	_salud_piloto_anterior = personaje.salud
	personaje.disparo_realizado.connect(func(acerto):
		if acerto:
			_impacto = 0.14)
	for i in lista_plataformas.size():
		var plataforma = lista_plataformas[i]
		plataforma.defensa_completada.connect(_al_completar_plataforma.bind(i))
		plataforma.torre_destruida.connect(_al_perder_torre)
		plataforma.torre.salud_cambiada.connect(_al_cambiar_torre.bind(i))
		plataforma.cupula.disparo_bloqueado.connect(func(): _aviso_escudo = 1.5)
	titulo.text = "INVASION  /  NIVEL %d" % numero
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	activar_plataforma(0)

func plataforma_activa() -> Node3D:
	return lista_plataformas[indice_activa]

func activar_plataforma(indice: int):
	indice_activa = indice
	var plataforma = plataforma_activa()
	_salud_torre_anterior = plataforma.torre.salud
	_actualizar_barra_torre(plataforma.torre.salud, plataforma.torre.salud_maxima)
	plataforma.iniciar()

func _input(event: InputEvent) -> void:
	if terminado or event is not InputEventKey or not event.pressed or event.echo:
		return
	if event.physical_keycode == KEY_P or event.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		alternar_pausa()
	elif event.physical_keycode == KEY_R and get_tree().paused:
		get_viewport().set_input_as_handled()
		get_tree().paused = false
		get_tree().reload_current_scene()
	elif event.physical_keycode == KEY_M and get_tree().paused:
		get_viewport().set_input_as_handled()
		get_tree().paused = false
		Partida.resultado = ""
		get_tree().change_scene_to_file(Partida.MENU)

func alternar_pausa():
	get_tree().paused = not get_tree().paused
	velo.visible = get_tree().paused
	resultado.text = "PAUSA\n\nP: continuar  ·  R: reiniciar nivel  ·  M: volver al menú" if get_tree().paused else ""
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if get_tree().paused else Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if terminado or get_tree().paused:
		return
	super._unhandled_input(event)

func _process(delta):
	if terminado:
		return
	if nave.salud <= 0:
		_terminar(false, "NAVE DESTRUIDA", 2.0)
		return
	if get_tree().paused:
		return
	super._process(delta)
	_actualizar_enemigos(delta)
	_actualizar_balizas()
	_actualizar_hud(delta)

func _actualizar_enemigos(delta):
	enemigos = enemigos.filter(func(enemigo): return is_instance_valid(enemigo))
	var blanco = get_tree().get_first_node_in_group("jugador")
	if blanco == null:
		return
	for enemigo in enemigos:
		enemigo.jugador = blanco
	_tiempo_enemigo += delta
	if _tiempo_enemigo >= intervalo_enemigos and enemigos.size() < max_enemigos_espaciales:
		_tiempo_enemigo = 0.0
		crear_enemigo_espacial(blanco)

func crear_enemigo_espacial(blanco: Node3D):
	var angulo = randf_range(0, TAU)
	var desvio = Vector3(cos(angulo), 0, sin(angulo)) * distancia_aparicion
	desvio.y = randf_range(5.0, 20.0)
	var enemigo = EnemigoGrande.instantiate()
	add_child(enemigo)
	enemigo.global_position = blanco.global_position + desvio
	enemigo.jugador = blanco
	enemigos.append(enemigo)

func _actualizar_balizas():
	for i in lista_plataformas.size():
		var marca: Label3D = lista_plataformas[i].get_node("Baliza")
		if i < indice_activa:
			marca.visible = true
			marca.modulate = Color(0.6, 0.7, 0.65, 0.8)
			marca.text = "✔\nPLATAFORMA %d DEFENDIDA" % (i + 1)
		elif i == indice_activa:
			marca.visible = not (a_pie and plataforma_actual == lista_plataformas[i])
			marca.modulate = Color(0.45, 1, 0.025, 1)
			marca.text = "▼\nPLATAFORMA %d · DEFENDER TORRE" % (i + 1)
		else:
			marca.visible = false

func _actualizar_hud(delta):
	var plataforma = plataforma_activa()
	_impacto = maxf(0, _impacto - delta)
	_aviso_escudo = maxf(0, _aviso_escudo - delta)
	_aviso_torre = maxf(0, _aviso_torre - delta)
	_aviso_siguiente = maxf(0, _aviso_siguiente - delta)
	_golpe_piloto = maxf(0, _golpe_piloto - delta * 2)
	golpe.color.a = _golpe_piloto * 0.25
	salud_pie.hide()
	mira.visible = a_pie and not personaje.en_transicion and not personaje.esta_muerto
	mira.text = "×" if _impacto > 0 else "+"
	mira.modulate = Color(0.55, 1, 0.12) if _impacto > 0 else Color.WHITE
	texto_piloto.text = ("A PIE  ·  SALUD %d" % personaje.salud) if a_pie else ("NAVE  ·  SALUD %d" % nave.salud)
	var en_esta_plataforma = plataforma_actual == plataforma
	if plataforma.estado == plataforma.Estado.PREPARACION:
		if a_pie and en_esta_plataforma:
			objetivo.text = "Prepárate junto a la torre; los asaltantes están en camino."
		else:
			objetivo.text = "Vuela a la plataforma %d y baja para defender la torre." % (indice_activa + 1)
		estado.text = "PLATAFORMA %d DE %d  ·  ATAQUE EN %d s" % [indice_activa + 1, lista_plataformas.size(), ceili(plataforma.tiempo_restante)]
	else:
		objetivo.text = "Elimina a los asaltantes antes de que destruyan la torre."
		estado.text = "PLATAFORMA %d DE %d  ·  AMENAZAS RESTANTES: %d" % [indice_activa + 1, lista_plataformas.size(), plataforma.restantes()]
	if personaje.esta_muerto:
		aviso.text = "Piloto derrotado"
	elif personaje.en_transicion:
		aviso.text = "Desembarcando…"
	elif _aviso_siguiente > 0:
		aviso.text = "¡Plataforma defendida! Vuela a la siguiente"
	elif _aviso_escudo > 0:
		aviso.text = "Cúpula: dispara a pie desde dentro"
	elif a_pie and en_esta_plataforma and not plataforma.cupula.contiene(personaje.camara.global_position):
		aviso.text = "Entra en la cúpula para dañar a los asaltantes"
	elif _aviso_torre > 0:
		aviso.text = "¡La torre está bajo ataque!"
	elif not a_pie and not nave_cerca_del_asteroide():
		var distancia = nave.global_position.distance_to(plataforma.get_node("PuntoNave").global_position)
		aviso.text = "Plataforma %d: %d m" % [indice_activa + 1, distancia]

func _al_cambiar_torre(actual: int, maxima: int, indice: int):
	if indice != indice_activa:
		return
	if actual < _salud_torre_anterior:
		_aviso_torre = 1.5
		sonido_torre.play()
	_salud_torre_anterior = actual
	_actualizar_barra_torre(actual, maxima)

func _actualizar_barra_torre(actual: int, maxima: int):
	barra_torre.max_value = maxima
	barra_torre.value = actual
	texto_torre.text = "TORRE DE LA PLATAFORMA %d  %d / %d" % [indice_activa + 1, actual, maxima]
	texto_torre.modulate = Color(1, 0.45, 0.15) if actual <= maxima * 0.3 else Color.WHITE
	barra_torre.modulate = texto_torre.modulate

func _al_cambiar_salud_pie(actual, maxima):
	super._al_cambiar_salud_pie(actual, maxima)
	if actual < _salud_piloto_anterior:
		_golpe_piloto = 1.0
	_salud_piloto_anterior = actual

func _al_completar_plataforma(indice: int):
	if terminado or indice != indice_activa:
		return
	if indice == lista_plataformas.size() - 1:
		_terminar(true, "NIVEL %d SUPERADO" % numero)
	else:
		_aviso_siguiente = 4.0
		activar_plataforma(indice + 1)

func _al_perder_torre():
	_terminar(false, "TORRE DESTRUIDA")

func _al_morir_a_pie():
	_terminar(false, "PILOTO DERROTADO")

func _terminar(gano: bool, mensaje: String, espera_previa := 0.0):
	if terminado:
		return
	terminado = true
	Partida.resultado = "victoria" if gano else "derrota"
	if espera_previa > 0:
		await get_tree().create_timer(espera_previa, true).timeout
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	mira.hide()
	aviso.text = ""
	golpe.color.a = 0.0
	velo.show()
	resultado.text = mensaje
	sonido_resultado.stream = SonidoVictoria if gano else SonidoDerrota
	sonido_resultado.play()
	await get_tree().create_timer(espera_resultado, true).timeout
	get_tree().paused = false
	get_tree().change_scene_to_file(Partida.MENU)
