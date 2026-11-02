extends CharacterBody3D

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
var invulnerable := false 

#Headboppppppp
@export_group("Movimiento de Cámara (Headbob)")
@export var frecuencia_bob := 2.2
@export var amplitud_caminar := 0.05
@export var amplitud_correr := 0.09

var _tiempo_bob := 0.0
var _posicion_original_camara := Vector3.ZERO

@onready var cabeza: Node3D = $Cabeza
@onready var camara_fps: Camera3D = $Cabeza/Camera3D
@onready var canon: Marker3D = $Cabeza/Canon
@onready var colision: CollisionShape3D = $CollisionShape3D

@onready var cinematica: Node3D = $Cinematica
@onready var animador: AnimationPlayer = $Cinematica/AnimationPlayer
@onready var camara_cinematica: Camera3D = $CamaraCinematica
@onready var modelo: MeshInstance3D = $Modelo

#para el recoil del arma
@export_group("Retroceso del Arma")
@export var fuerza_retroceso := 0.15
@export var tiempo_retroceso := 0.05
@export var tiempo_recuperacion := 0.15

@onready var modelo_arma: Node3D = $Cabeza/Arma
var _posicion_original_arma := Vector3.ZERO


func _ready() -> void:
	Controles.registrar()
	salud = salud_maxima
	set_activo(activo, usar_camara_propia)
	salud_cambiada.emit(salud, salud_maxima)
	if cinematica:
		cinematica.hide()
	_posicion_original_camara = camara_fps.position
	if modelo_arma:
		_posicion_original_arma = modelo_arma.position


func iniciar_animacion_bajada(nave_real: Node3D) -> void:
	_control_habilitado = false
	invulnerable = true
	set_physics_process(false) 
	
	if modelo:
		modelo.hide()
	if has_node("Cabeza/Arma"):
		get_node("Cabeza/Arma").hide()
		
	nave_real.hide()
	
	camara_cinematica.make_current()
	cinematica.show()
	animador.play("Animation") 
	
	await animador.animation_finished
	
	cinematica.hide()
	nave_real.show()
	
	if modelo:
		modelo.show()
	if has_node("Cabeza/Arma"):
		get_node("Cabeza/Arma").show()
		
	camara_fps.make_current()
	set_physics_process(true)
	invulnerable = false
	_control_habilitado = true
	
func set_activo(valor: bool, tomar_camara: bool = true) -> void:
	activo = valor and salud > 0
	_control_habilitado = activo
	velocity = Vector3.ZERO
	_margen_salto = 0.0
	_salto_pendiente = 0.0
	visible = activo
	colision.set_deferred("disabled", not activo)
	
	for grupo in ["jugador", "personaje_terrestre"]:
		if activo:
			add_to_group(grupo)
		elif is_in_group(grupo):
			remove_from_group(grupo)
			
	if activo and tomar_camara:
		camara_fps.make_current()
		capturar_mouse(true)
	elif not activo:
		camara_fps.current = false

func capturar_mouse(capturar: bool) -> void:
	_control_habilitado = capturar and activo
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if _control_habilitado else Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	if not activo or not _control_habilitado:
		return
	if event is InputEventMouseMotion:
		
		rotate_y(-event.relative.x * sensibilidad)
		
		cabeza.rotation.x = clampf(cabeza.rotation.x - event.relative.y * sensibilidad,
			deg_to_rad(-65), deg_to_rad(65))
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
	
	if recibe_input:
		_aplicar_headbob(delta)
	
	if recibe_input and Input.is_action_pressed("pie_disparar"):
		disparar()
	
	if recibe_input and Input.is_action_pressed("pie_disparar"):
		disparar()

func disparar() -> bool:
	if not activo or _recarga > 0:
		return false
	_recarga = intervalo_disparo
	var origen := camara_fps.global_position
	var destino := origen - camara_fps.global_basis.z * alcance
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
	Trazo.mostrar(get_tree().current_scene, canon.global_position, destino, Color(0.3, 1, 0.8))
	
	
	_aplicar_retroceso_arma()
	
	disparo_realizado.emit(acerto)
	return true

func take_damage(cantidad: int) -> void:
	if not activo or cantidad <= 0 or invulnerable:
		return
	salud = maxi(0, salud - cantidad)
	salud_cambiada.emit(salud, salud_maxima)
	if salud == 0:
		set_activo(false)
		murio.emit()
		
	#Headbop
func _aplicar_headbob(delta: float) -> void:
	
	var vel_plana := Vector2(velocity.x, velocity.z).length()
	
	if is_on_floor() and vel_plana > 0.5:
		
		_tiempo_bob += delta * vel_plana * frecuencia_bob
		var amplitud := amplitud_correr if Input.is_action_pressed("pie_correr") else amplitud_caminar
		
		var offset_y := sin(_tiempo_bob) * amplitud
		var offset_x := cos(_tiempo_bob / 2.0) * (amplitud * 0.6)
		
		
		camara_fps.position.y = lerpf(camara_fps.position.y, _posicion_original_camara.y + offset_y, delta * 15.0)
		camara_fps.position.x = lerpf(camara_fps.position.x, _posicion_original_camara.x + offset_x, delta * 15.0)
	else:
		
		camara_fps.position.y = lerpf(camara_fps.position.y, _posicion_original_camara.y, delta * 8.0)
		camara_fps.position.x = lerpf(camara_fps.position.x, _posicion_original_camara.x, delta * 8.0)
		
#Recoil arma
func _aplicar_retroceso_arma() -> void:
	if not modelo_arma:
		return

	var tween = create_tween()
	
	var posicion_atras = _posicion_original_arma + Vector3(0, 0, -fuerza_retroceso)
	tween.tween_property(modelo_arma, "position", posicion_atras, tiempo_retroceso).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(modelo_arma, "position", _posicion_original_arma, tiempo_recuperacion).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
