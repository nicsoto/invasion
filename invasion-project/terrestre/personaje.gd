extends CharacterBody3D
## Origen en los pies. Gravedad local hacia -Y, para superficies planas/inclinadas.

signal salud_cambiada(actual: int, maxima: int)
signal murio
signal disparo_realizado(acerto: bool)
signal interaccion_solicitada(personaje: Node3D)

const Controles = preload("res://terrestre/controles.gd")
const Trazo = preload("res://terrestre/trazo.gd")

@export var activo := true
@export var usar_camara_propia := true
@export var velocidad := 7.0
@export var velocidad_carrera := 11.0
@export var aceleracion := 28.0
@export var gravedad := 12.0
@export var impulso_salto := 7.0
@export var sensibilidad := 0.0025
@export var salud_maxima := 100
@export var dano := 25
@export var alcance := 70.0
@export var intervalo_disparo := 0.22
@export var altura_muerte := -25.0

var salud: int
var _recarga := 0.0
var _margen_salto := 0.0
var _salto_pendiente := 0.0
var _control_habilitado := false

@onready var cabeza: Node3D = $Cabeza
@onready var camara: Camera3D = $Cabeza/Camera3D
@onready var canon: Marker3D = $Cabeza/Canon
@onready var colision: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	Controles.registrar()
	salud = salud_maxima
	set_activo(activo, usar_camara_propia)
	salud_cambiada.emit(salud, salud_maxima)

func set_activo(valor: bool, tomar_camara: bool = true) -> void:
	activo = valor and salud > 0
	_control_habilitado = activo
	velocity = Vector3.ZERO
	_margen_salto = 0.0
	_salto_pendiente = 0.0
	visible = activo
	colision.set_deferred("disabled", not activo)
	# Solo el personaje controlado debe ser un blanco para los enemigos.
	for grupo in ["jugador", "personaje_terrestre"]:
		if activo:
			add_to_group(grupo)
		elif is_in_group(grupo):
			remove_from_group(grupo)
	if activo and tomar_camara:
		camara.make_current()
		capturar_mouse(true)
	elif not activo:
		camara.current = false

func capturar_mouse(capturar: bool) -> void:
	# Estado explícito para menús y pruebas sin ventana (headless no captura el mouse).
	_control_habilitado = capturar and activo
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if _control_habilitado else Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	if not activo or not _control_habilitado:
		return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensibilidad)
		cabeza.rotation.x = clampf(cabeza.rotation.x - event.relative.y * sensibilidad,
			deg_to_rad(-80), deg_to_rad(80))
	if event.is_action_pressed("pie_interactuar") and not event.is_echo():
		interaccion_solicitada.emit(self)

func _physics_process(delta: float) -> void:
	if not activo:
		return
	_recarga = maxf(0, _recarga - delta)
	if global_position.y < altura_muerte:
		take_damage(salud)
		return
	var recibe_input := _control_habilitado
	var entrada := Vector2.ZERO
	if recibe_input:
		entrada = Input.get_vector("pie_izquierda", "pie_derecha", "pie_adelante", "pie_atras")
	var direccion := global_basis * Vector3(entrada.x, 0, entrada.y)
	var rapidez := velocidad_carrera if recibe_input and Input.is_action_pressed("pie_correr") else velocidad
	velocity.x = move_toward(velocity.x, direccion.x * rapidez, aceleracion * delta)
	velocity.z = move_toward(velocity.z, direccion.z * rapidez, aceleracion * delta)
	_margen_salto = 0.12 if is_on_floor() else maxf(0, _margen_salto - delta)
	_salto_pendiente = maxf(0, _salto_pendiente - delta)
	if recibe_input and Input.is_action_just_pressed("pie_saltar"):
		_salto_pendiente = 0.12
	if not is_on_floor():
		velocity.y -= gravedad * delta
	if _salto_pendiente > 0 and _margen_salto > 0:
		velocity.y = impulso_salto
		_margen_salto = 0
		_salto_pendiente = 0
	move_and_slide()
	if recibe_input and Input.is_action_pressed("pie_disparar"):
		disparar()

func disparar() -> bool:
	if not activo or _recarga > 0:
		return false
	_recarga = intervalo_disparo
	var origen := camara.global_position
	var destino := origen - camara.global_basis.z * alcance
	var consulta := PhysicsRayQueryParameters3D.create(origen, destino, collision_mask, [get_rid()])
	var impacto := get_world_3d().direct_space_state.intersect_ray(consulta)
	var acerto := false
	if not impacto.is_empty():
		destino = impacto.position
		var cuerpo: Object = impacto.collider
		if cuerpo.has_method("recibir_disparo_terrestre"):
			acerto = cuerpo.recibir_disparo_terrestre(dano)
		elif cuerpo.has_method("take_damage") and not cuerpo.is_in_group("jugador"):
			cuerpo.take_damage(dano)
			acerto = true
	Trazo.mostrar(get_tree().current_scene, canon.global_position, destino, Color(0.3, 1, 0.8))
	disparo_realizado.emit(acerto)
	return true

func take_damage(cantidad: int) -> void:
	if not activo or cantidad <= 0:
		return
	salud = maxi(0, salud - cantidad)
	salud_cambiada.emit(salud, salud_maxima)
	if salud == 0:
		set_activo(false)
		murio.emit()
