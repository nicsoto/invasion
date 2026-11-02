extends "res://integracion/juego.gd"
## Usa la transición existente y presenta una sola defensa completa.

var terminado := false
var _impacto := 0.0
var _aviso_escudo := 0.0

@onready var defensa = $BaseAsteroide
@onready var objetivo: Label = $HUD/Panel/Margen/Columna/Objetivo
@onready var contador: Label = $HUD/Panel/Margen/Columna/Estado
@onready var salud_torre: ProgressBar = $HUD/Panel/Margen/Columna/BarraTorre
@onready var texto_torre: Label = $HUD/Panel/Margen/Columna/Torre
@onready var texto_piloto: Label = $HUD/Piloto
@onready var velo: ColorRect = $HUD/Velo
@onready var resultado: Label = $HUD/Resultado

func _ready():
	super._ready()
	process_mode = Node.PROCESS_MODE_ALWAYS
	for hijo in get_children():
		hijo.process_mode = Node.PROCESS_MODE_PAUSABLE
	# Esta escena administra la pausa; la nave conserva su controlador de vuelo.
	nave.get_node("HUD").hide()
	defensa.torre.salud_cambiada.connect(_actualizar_torre)
	defensa.torre_destruida.connect(_al_perder_torre)
	defensa.defensa_completada.connect(_al_completar_defensa)
	defensa.cupula.disparo_bloqueado.connect(func(): _aviso_escudo = 1.5)
	personaje.disparo_realizado.connect(func(acerto):
		if acerto:
			_impacto = 0.14)
	_actualizar_torre(defensa.torre.salud, defensa.torre.salud_maxima)
	defensa.iniciar()

func _input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.pressed or event.echo:
		return
	if event.physical_keycode == KEY_R:
		get_viewport().set_input_as_handled()
		get_tree().paused = false
		get_tree().reload_current_scene()
	elif event.physical_keycode == KEY_P:
		get_viewport().set_input_as_handled()
		if terminado:
			return
		get_tree().paused = not get_tree().paused
		velo.visible = get_tree().paused
		resultado.text = "PAUSA\nP: continuar  ·  R: reiniciar" if get_tree().paused else ""
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if get_tree().paused else Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if terminado or get_tree().paused:
		return
	super._unhandled_input(event)

func _process(delta):
	if terminado:
		return
	if nave.salud <= 0:
		_terminar("NAVE DESTRUIDA", "R: volver a intentar la defensa")
		return
	if get_tree().paused:
		return
	super._process(delta)
	salud_pie.hide()
	_impacto = maxf(0, _impacto - delta)
	_aviso_escudo = maxf(0, _aviso_escudo - delta)
	mira.text = "×" if _impacto > 0 else "+"
	mira.modulate = Color(0.55, 1, 0.12) if _impacto > 0 else Color.WHITE
	texto_piloto.text = ("A PIE  ·  SALUD %d" % personaje.salud) if a_pie else ("NAVE  ·  SALUD %d" % nave.salud)
	if defensa.estado == defensa.Estado.PREPARACION:
		objetivo.text = "Prepárate junto a la torre; los asaltantes están en camino." if a_pie \
			else "Acércate a la plataforma y baja para defender la torre."
		contador.text = "PRIMER CONTACTO EN %d s  ·  %d atacantes" % [ceili(defensa.tiempo_restante), defensa.cantidad_atacantes]
	else:
		objetivo.text = "Elimina a los asaltantes antes de que destruyan la torre."
		contador.text = "AMENAZAS RESTANTES: %d" % defensa.restantes()
	if _aviso_escudo > 0:
		aviso.text = "Cúpula: dispara a pie desde dentro"
	elif a_pie and not defensa.cupula.contiene(personaje.camara.global_position):
		aviso.text = "Entra en la cúpula para dañar a los asaltantes"

func _actualizar_torre(actual: int, maxima: int) -> void:
	salud_torre.max_value = maxima
	salud_torre.value = actual
	texto_torre.text = "INTEGRIDAD DE LA TORRE  %d / %d" % [actual, maxima]
	texto_torre.modulate = Color(1, 0.45, 0.15) if actual <= maxima * 0.3 else Color.WHITE

func _al_morir_a_pie():
	_terminar("PILOTO DERROTADO", "R: volver a intentar la defensa")

func _al_perder_torre() -> void:
	_terminar("TORRE DESTRUIDA", "Baja a tiempo y elimina a quienes la atacan.\nR: reintentar")

func _al_completar_defensa() -> void:
	_terminar("PLATAFORMA DEFENDIDA", "Oleada eliminada · Torre conservada\nR: repetir la defensa")

func _terminar(titulo: String, detalle: String) -> void:
	if terminado:
		return
	terminado = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	mira.hide()
	aviso.text = ""
	velo.show()
	resultado.text = titulo + "\n\n" + detalle
