extends Node3D

@export var distancia_para_bajar := 30.0
@export var distancia_para_subir := 6.0

var a_pie := false

@onready var nave = $jugador
@onready var personaje = $PersonajeTerrestre
@onready var punto_nave: Marker3D = $BaseAsteroide/PuntoNave
@onready var punto_bajada: Marker3D = $BaseAsteroide/PuntoBajada
@onready var baliza: Label3D = $BaseAsteroide/Baliza
@onready var aviso: Label = $HUD/Aviso
@onready var salud_pie: ProgressBar = $HUD/SaludPie
@onready var mira: Label = $HUD/Mira

func _ready():
	personaje.interaccion_solicitada.connect(_al_pedir_subir)
	personaje.salud_cambiada.connect(_al_cambiar_salud_pie)
	personaje.murio.connect(_al_morir_a_pie)
	salud_pie.max_value = personaje.salud_maxima
	salud_pie.value = personaje.salud
	salud_pie.visible = false
	mira.visible = false

func _process(_delta):
	if a_pie:
		if personaje_cerca_de_la_nave():
			aviso.text = "E: subir a la nave"
		else:
			aviso.text = ""
	else:
		if nave_cerca_del_asteroide():
			aviso.text = "E: aterrizar y bajar"
		else:
			var distancia = nave.global_position.distance_to(punto_nave.global_position)
			aviso.text = "Zona de aterrizaje: %d m" % distancia

func _unhandled_input(event):
	if a_pie:
		return
	if event.is_action_pressed("pie_interactuar") and nave_cerca_del_asteroide():
		get_viewport().set_input_as_handled()
		bajar()

func nave_cerca_del_asteroide() -> bool:
	return nave.global_position.distance_to(punto_nave.global_position) <= distancia_para_bajar

func personaje_cerca_de_la_nave() -> bool:
	return personaje.global_position.distance_to(nave.global_position) <= distancia_para_subir

func bajar():
	a_pie = true
	nave.set_activa(false)
	nave.global_transform = punto_nave.global_transform
	personaje.global_position = punto_bajada.global_position
	personaje.rotation = Vector3(0, punto_bajada.global_rotation.y, 0)
	personaje.set_activo(true)
	salud_pie.visible = true
	mira.visible = true
	baliza.visible = false

func subir():
	a_pie = false
	personaje.set_activo(false)
	nave.set_activa(true)
	salud_pie.visible = false
	mira.visible = false
	baliza.visible = true

func _al_pedir_subir(_personaje):
	if not personaje_cerca_de_la_nave():
		return
	get_viewport().set_input_as_handled()
	subir()

func _al_cambiar_salud_pie(actual, maxima):
	salud_pie.max_value = maxima
	salud_pie.value = actual

func _al_morir_a_pie():
	mira.visible = false
	nave.mostrar_menu_muerte()
