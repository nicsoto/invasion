extends CharacterBody3D
## Centinela flotante: blindaje contra el daño espacial, vulnerable al arma a pie.

signal derrotado
signal impacto_bloqueado

const Trazo = preload("res://terrestre/trazo.gd")

@export var salud_maxima := 100
@export var dano := 12
@export var alcance := 28.0
@export var intervalo_ataque := 2.0
@export var tiempo_aviso := 0.7
@export var radio_patrulla := 2.0
@export var velocidad_patrulla := 1.5

var salud: int
var _origen: Vector3
var _tiempo := 0.0
var _espera := 1.5
var _aviso := 0.0
var _destino_disparo := Vector3.ZERO
var _objetivo: Node3D
var _flash := 0.0

@onready var canon: Marker3D = $Canon
@onready var etiqueta: Label3D = $Estado
@onready var nucleo: MeshInstance3D = $Nucleo

func _ready() -> void:
	salud = salud_maxima
	_origen = global_position
	_actualizar_estado()

func _physics_process(delta: float) -> void:
	if salud <= 0:
		return
	_tiempo += delta
	_flash = maxf(0, _flash - delta)
	var destino := _origen + Vector3(sin(_tiempo * 0.6) * radio_patrulla, 0, 0)
	velocity = (destino - global_position).limit_length(velocidad_patrulla)
	move_and_slide()
	if _aviso > 0:
		_aviso -= delta
		if _aviso <= 0:
			_disparar()
			_espera = intervalo_ataque
		_actualizar_estado()
		return
	_espera = maxf(0, _espera - delta)
	_objetivo = get_tree().get_first_node_in_group("personaje_terrestre") as Node3D
	if _espera == 0 and is_instance_valid(_objetivo):
		var punto := _objetivo.global_position + Vector3.UP * 1.3
		if canon.global_position.distance_to(punto) <= alcance and _puede_ver(punto):
			# Fija la posición al avisar: el jugador puede esquivar o buscar cobertura.
			_destino_disparo = punto
			_aviso = tiempo_aviso
	_actualizar_estado()

func _puede_ver(punto: Vector3) -> bool:
	var consulta := PhysicsRayQueryParameters3D.create(canon.global_position, punto,
		collision_mask, [get_rid()])
	var impacto := get_world_3d().direct_space_state.intersect_ray(consulta)
	return not impacto.is_empty() and impacto.collider == _objetivo

func _disparar() -> void:
	var direccion := (_destino_disparo - canon.global_position).normalized()
	var fin := canon.global_position + direccion * alcance
	var consulta := PhysicsRayQueryParameters3D.create(canon.global_position, fin,
		collision_mask, [get_rid()])
	var impacto := get_world_3d().direct_space_state.intersect_ray(consulta)
	if not impacto.is_empty():
		fin = impacto.position
		var cuerpo: Node = impacto.collider
		if cuerpo.is_in_group("personaje_terrestre") and cuerpo.has_method("take_damage"):
			cuerpo.take_damage(dano)
	Trazo.mostrar(get_tree().current_scene, canon.global_position, fin, Color(1, 0.25, 0.15))

func take_damage(_cantidad: int) -> void:
	# La bala espacial existente llama este método: el blindaje la bloquea.
	_flash = 0.4
	impacto_bloqueado.emit()
	_actualizar_estado()

func recibir_disparo_terrestre(cantidad: int) -> bool:
	if salud <= 0 or cantidad <= 0:
		return false
	salud = maxi(0, salud - cantidad)
	_actualizar_estado()
	if salud == 0:
		derrotado.emit()
		queue_free()
	return true

func _actualizar_estado() -> void:
	if _flash > 0:
		etiqueta.text = "BLINDAJE ESPACIAL"
		etiqueta.modulate = Color(0.4, 0.8, 1)
	elif _aviso > 0:
		etiqueta.text = "¡BUSCA COBERTURA!"
		etiqueta.modulate = Color(1, 0.5, 0.2)
	else:
		etiqueta.text = "CENTINELA  %d / %d" % [salud, salud_maxima]
		etiqueta.modulate = Color(0.8, 0.9, 1)
	nucleo.scale = Vector3.ONE * (1.25 if _aviso > 0 else 1.0)
