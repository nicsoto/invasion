extends Node3D

@export var distancia_para_bajar := 30.0
@export var distancia_para_subir := 6.0

var a_pie := false
var plataforma_actual: Node3D = null
var punto_nave: Marker3D
var punto_bajada: Marker3D
var baliza: Label3D

@onready var nave = $jugador
@onready var personaje = $PersonajeTerrestre
@onready var aviso: Label = $HUD/Aviso
@onready var salud_pie: ProgressBar = $HUD/SaludPie
@onready var mira: Label = $HUD/Mira

func _ready():
	elegir_plataforma(plataforma_mas_cercana())
	personaje.interaccion_solicitada.connect(_al_pedir_subir)
	personaje.salud_cambiada.connect(_al_cambiar_salud_pie)
	personaje.murio.connect(_al_morir_a_pie)
	salud_pie.max_value = personaje.salud_maxima
	salud_pie.value = personaje.salud
	salud_pie.visible = false
	mira.visible = false

func plataformas() -> Array:
	var lista = get_tree().get_nodes_in_group("plataforma_aterrizaje")
	if lista.is_empty() and has_node("BaseAsteroide"):
		lista = [get_node("BaseAsteroide")]
	return lista

func plataforma_mas_cercana() -> Node3D:
	var mejor: Node3D = null
	var mejor_distancia := INF
	for plataforma in plataformas():
		var distancia = nave.global_position.distance_to(plataforma.get_node("PuntoNave").global_position)
		if distancia < mejor_distancia:
			mejor = plataforma
			mejor_distancia = distancia
	return mejor

func elegir_plataforma(plataforma: Node3D):
	if plataforma == null or plataforma == plataforma_actual:
		return
	plataforma_actual = plataforma
	punto_nave = plataforma.get_node("PuntoNave")
	punto_bajada = plataforma.get_node("PuntoBajada")
	baliza = plataforma.get_node_or_null("Baliza")

func _process(_delta):
	if not a_pie:
		elegir_plataforma(plataforma_mas_cercana())
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
	
	
	if nave.has_node("chata/Armature/Skeleton3D/Cube_001"):
		nave.get_node("chata/Armature/Skeleton3D/Cube_001").hide()
	
	personaje.global_position = punto_bajada.global_position
	personaje.rotation = Vector3(0, punto_bajada.global_rotation.y, 0)
	personaje.establecer_altura_superficie(punto_bajada.global_position.y)
	personaje.set_activo(true)
	
	
	personaje.iniciar_animacion_bajada(nave)
	
	salud_pie.visible = true
	mira.visible = true
	if baliza:
		baliza.visible = false

func subir():
	a_pie = false
	personaje.set_activo(false)
	nave.set_activa(true)
	
	
	if nave.has_node("chata/Armature/Skeleton3D/Cube_001"):
		nave.get_node("chata/Armature/Skeleton3D/Cube_001").show()
	
	salud_pie.visible = false
	mira.visible = false
	if baliza:
		baliza.visible = true

func _al_pedir_subir(_personaje):
	if not personaje_cerca_de_la_nave() or personaje.en_transicion or personaje.esta_muerto:
		return
	get_viewport().set_input_as_handled()
	subir()

func _al_cambiar_salud_pie(actual, maxima):
	salud_pie.max_value = maxima
	salud_pie.value = actual

func _al_morir_a_pie():
	mira.visible = false
	nave.mostrar_menu_muerte()
