extends Node3D
## Escena de prueba independiente. La transición real corresponde al ensamblaje.

var _restantes := 0
var _terminado := false
var _marca_impacto := 0.0

@onready var personaje = $PersonajeTerrestre
@onready var objetivo: Label = $HUD/Margen/Columna/Objetivo
@onready var vida: ProgressBar = $HUD/Vida/Barra
@onready var vida_texto: Label = $HUD/Vida/Texto
@onready var mensaje: Label = $HUD/Mensaje
@onready var mira: Label = $HUD/Mira
@onready var velo: ColorRect = $HUD/Velo

func _ready() -> void:
	# Solo este nodo sigue recibiendo Escape/R mientras la escena está pausada.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for hijo in get_children():
		hijo.process_mode = Node.PROCESS_MODE_PAUSABLE
	personaje.salud_cambiada.connect(_actualizar_vida)
	personaje.murio.connect(_al_morir)
	personaje.disparo_realizado.connect(_al_disparar)
	_actualizar_vida(personaje.salud, personaje.salud_maxima)
	for enemigo in get_tree().get_nodes_in_group("enemigo_especial"):
		_restantes += 1
		enemigo.derrotado.connect(_al_derrotar_enemigo)
	_actualizar_objetivo()

func _process(delta: float) -> void:
	_marca_impacto = maxf(0, _marca_impacto - delta)
	mira.text = "×" if _marca_impacto > 0 else "+"
	mira.modulate = Color(0.4, 1, 0.75) if _marca_impacto > 0 else Color.WHITE

func _unhandled_input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.pressed or event.echo:
		return
	if event.physical_keycode == KEY_R:
		get_tree().paused = false
		get_tree().reload_current_scene()
	elif event.physical_keycode == KEY_ESCAPE and not _terminado:
		var pausar := not get_tree().paused
		get_tree().paused = pausar
		personaje.capturar_mouse(not pausar)
		velo.visible = pausar
		mensaje.text = "PAUSA\nEsc para continuar · R para reiniciar" if pausar else ""

func _actualizar_vida(actual: int, maxima: int) -> void:
	vida.max_value = maxima
	vida.value = actual
	vida_texto.text = "SALUD  %d / %d" % [actual, maxima]

func _actualizar_objetivo() -> void:
	objetivo.text = "Destruye los centinelas con el arma a pie. Restantes: %d" % _restantes

func _al_disparar(acerto: bool) -> void:
	if acerto:
		_marca_impacto = 0.12

func _al_derrotar_enemigo() -> void:
	_restantes -= 1
	_actualizar_objetivo()
	if _restantes == 0:
		_terminar("ZONA DESPEJADA\nCombate terrestre completado · R para repetir")

func _al_morir() -> void:
	_terminar("INTENTO TERMINADO\nUsa las rocas como cobertura · R para reintentar")

func _terminar(texto: String) -> void:
	_terminado = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	velo.show()
	mensaje.text = texto
