extends CharacterBody3D
## Personaje reutilizable: el origen está en los pies y la cámara mira hacia -Z.

signal salud_cambiada(actual: int, maxima: int)
signal murio
signal disparo_realizado(acerto: bool)
signal interaccion_solicitada(personaje: Node3D)
signal bajada_finalizada

const Controles = preload("res://terrestre/controles.gd")
const Trazo = preload("res://terrestre/trazo.gd")
const ReglasCupula = preload("res://terrestre/defensa/reglas_cupula.gd")
const Explosion = preload("res://explosion.tscn")

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
@export var distancia_caida := 25.0
@export var reproducir_cinematicas := true

@export_group("Movimiento de cámara")
@export var frecuencia_bob := 2.2
@export var amplitud_caminar := 0.05
@export var amplitud_correr := 0.09
@export_group("Retroceso del arma")
@export var fuerza_retroceso := 0.15
@export var tiempo_retroceso := 0.05
@export var tiempo_recuperacion := 0.15

var salud: int
var esta_muerto := false
var en_transicion := false
var invulnerable := false
var _recarga := 0.0
var _margen_salto := 0.0
var _salto_pendiente := 0.0
var _control_habilitado := false
var _tiempo_bob := 0.0
var _posicion_original_camara: Vector3
var _posicion_original_arma: Vector3
var _retroceso: Tween
var _nave_bajada: Node3D
var _reloj_muerte: Timer
var _fase_muerte := 0

@onready var cabeza: Node3D = $Cabeza
@onready var camara: Camera3D = $Cabeza/Camera3D
# Ambas interfaces se usan en los sistemas existentes del equipo.
@onready var camara_fps: Camera3D = camara
@onready var canon: Marker3D = $Cabeza/Canon
@onready var colision: CollisionShape3D = $CollisionShape3D
@onready var modelo: MeshInstance3D = $Modelo
@onready var arma: MeshInstance3D = $Cabeza/Arma
@onready var camara_muerte: Camera3D = $CamaraMuerte
@onready var cinematica: Node3D = $Cinematica
@onready var animador: AnimationPlayer = $Cinematica/AnimationPlayer
@onready var camara_cinematica: Camera3D = $CamaraCinematica
@onready var sonido_disparo: AudioStreamPlayer = $Cabeza/SonidoDisparo
@onready var sonido_hit: AudioStreamPlayer = $SonidoHitEnemigo
@onready var sonido_dano: AudioStreamPlayer = $SonidoDanoRecibido
@onready var sonido_pasos: AudioStreamPlayer = $SonidoPasos

func _ready() -> void:
	Controles.registrar()
	salud = salud_maxima
	_posicion_original_camara = camara.position
	_posicion_original_arma = arma.position
	animador.animation_finished.connect(_al_terminar_animacion)
	cinematica.hide()
	_reloj_muerte = Timer.new()
	_reloj_muerte.one_shot = true
	_reloj_muerte.timeout.connect(_avanzar_muerte)
	add_child(_reloj_muerte)
	set_activo(activo, usar_camara_propia)
	salud_cambiada.emit(salud, salud_maxima)

func establecer_altura_superficie(altura: float) -> void:
	# El nivel puede ubicar cada plataforma a una altura diferente.
	altura_muerte = altura - distancia_caida

func iniciar_animacion_bajada(nave_real: Node3D) -> void:
	if not activo or en_transicion or esta_muerto or not reproducir_cinematicas:
		return
	if not animador.has_animation("Animation"):
		return
	en_transicion = true
	invulnerable = true
	_control_habilitado = false
	velocity = Vector3.ZERO
	set_physics_process(false)
	modelo.hide()
	arma.hide()
	_nave_bajada = nave_real
	_nave_bajada.hide()
	camara_cinematica.make_current()
	cinematica.show()
	animador.play("Animation")

func _cancelar_bajada() -> void:
	if not en_transicion:
		return
	animador.stop()
	cinematica.hide()
	if is_instance_valid(_nave_bajada):
		_nave_bajada.show()
	_nave_bajada = null
	en_transicion = false
	invulnerable = false
	camara_cinematica.current = false
	modelo.show()
	arma.show()
	set_physics_process(true)

func _al_terminar_animacion(nombre: StringName) -> void:
	if nombre != &"Animation" or not en_transicion:
		return
	_cancelar_bajada()
	if activo and not esta_muerto:
		camara.make_current()
		capturar_mouse(true)
		bajada_finalizada.emit()

func set_activo(valor: bool, tomar_camara: bool = true) -> void:
	_cancelar_bajada()
	activo = valor and salud > 0 and not esta_muerto
	_control_habilitado = activo
	velocity = Vector3.ZERO
	_recarga = 0.0
	_margen_salto = 0.0
	_salto_pendiente = 0.0
	visible = activo
	colision.set_deferred("disabled", not activo)
	sonido_pasos.stop()
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
	_control_habilitado = capturar and activo and not en_transicion
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
	if not activo or esta_muerto:
		return
	if global_position.y < altura_muerte:
		take_damage(salud)
		return
	_recarga = maxf(0, _recarga - delta)
	var entrada := Vector2.ZERO
	if _control_habilitado:
		entrada = Input.get_vector("pie_izquierda", "pie_derecha", "pie_adelante", "pie_atras")
	var direccion := global_basis * Vector3(entrada.x, 0, entrada.y)
	var rapidez := velocidad_carrera if _control_habilitado and Input.is_action_pressed("pie_correr") else velocidad
	velocity.x = move_toward(velocity.x, direccion.x * rapidez, aceleracion * delta)
	velocity.z = move_toward(velocity.z, direccion.z * rapidez, aceleracion * delta)
	_margen_salto = 0.12 if is_on_floor() else maxf(0, _margen_salto - delta)
	_salto_pendiente = maxf(0, _salto_pendiente - delta)
	if _control_habilitado and Input.is_action_just_pressed("pie_saltar"):
		_salto_pendiente = 0.12
	if not is_on_floor():
		velocity.y -= gravedad * delta
	if _salto_pendiente > 0 and _margen_salto > 0:
		velocity.y = impulso_salto
		_margen_salto = 0
		_salto_pendiente = 0
	move_and_slide()
	_aplicar_headbob(delta)
	if _control_habilitado and Input.is_action_pressed("pie_disparar"):
		disparar()

func disparar() -> bool:
	if not activo or esta_muerto or en_transicion or not _control_habilitado or _recarga > 0:
		return false
	_recarga = intervalo_disparo
	sonido_disparo.play()
	var origen := camara.global_position
	var destino := origen - camara.global_basis.z * alcance
	var consulta := PhysicsRayQueryParameters3D.create(origen, destino, collision_mask, [get_rid()])
	var impacto := get_world_3d().direct_space_state.intersect_ray(consulta)
	var acerto := false
	if not impacto.is_empty():
		destino = impacto.position
	var escudo := ReglasCupula.interceptar(get_tree(), origen, destino, &"terrestre")
	if not escudo.is_empty():
		destino = escudo.position
	elif not impacto.is_empty():
		var cuerpo: Object = impacto.collider
		if cuerpo.has_method("recibir_disparo_desde"):
			acerto = cuerpo.recibir_disparo_desde(dano, self)
		elif cuerpo.has_method("recibir_disparo_terrestre"):
			acerto = cuerpo.recibir_disparo_terrestre(dano)
		elif cuerpo.has_method("take_damage") and not cuerpo.is_in_group("jugador") \
				and not cuerpo.is_in_group("torre_defensa"):
			cuerpo.take_damage(dano)
			acerto = true
	if acerto:
		sonido_hit.play()
	Trazo.mostrar(get_tree().current_scene, canon.global_position, destino, Color(0.3, 1, 0.8))
	_aplicar_retroceso_arma()
	disparo_realizado.emit(acerto)
	return true

func take_damage(cantidad: int) -> void:
	if not activo or esta_muerto or cantidad <= 0 or invulnerable:
		return
	sonido_dano.play()
	salud = maxi(0, salud - cantidad)
	salud_cambiada.emit(salud, salud_maxima)
	if salud == 0:
		iniciar_cinematica_muerte()

func iniciar_cinematica_muerte(_tipo: String = "terrestre") -> void:
	if esta_muerto:
		return
	esta_muerto = true
	set_activo(false)
	if not reproducir_cinematicas:
		murio.emit()
		return
	show()
	modelo.show()
	arma.hide()
	camara_muerte.top_level = true
	camara_muerte.global_position = global_position + Vector3(2, 3, 2)
	camara_muerte.look_at(global_position + Vector3.UP)
	camara_muerte.make_current()
	_reloj_muerte.start(1.0)

func _avanzar_muerte() -> void:
	if _fase_muerte == 0:
		var explosion := Explosion.instantiate()
		get_tree().current_scene.add_child(explosion)
		explosion.global_position = global_position + Vector3.UP
		modelo.hide()
		_fase_muerte = 1
		_reloj_muerte.start(1.5)
	else:
		murio.emit()

func _aplicar_headbob(delta: float) -> void:
	var vel_plana := Vector2(velocity.x, velocity.z).length()
	if _control_habilitado and is_on_floor() and vel_plana > 0.5:
		_tiempo_bob += delta * vel_plana * frecuencia_bob
		var amplitud := amplitud_correr if Input.is_action_pressed("pie_correr") else amplitud_caminar
		if sin(_tiempo_bob) < -0.95 and not sonido_pasos.playing:
			sonido_pasos.pitch_scale = randf_range(0.9, 1.1)
			sonido_pasos.play()
		var desplazamiento := Vector3(cos(_tiempo_bob / 2.0) * amplitud * 0.6, sin(_tiempo_bob) * amplitud, 0)
		camara.position = camara.position.lerp(_posicion_original_camara + desplazamiento, minf(1, delta * 15))
	else:
		camara.position = camara.position.lerp(_posicion_original_camara, minf(1, delta * 8))

func _aplicar_retroceso_arma() -> void:
	if _retroceso and _retroceso.is_valid():
		_retroceso.kill()
	_retroceso = create_tween()
	var atras := _posicion_original_arma + Vector3(0, 0, fuerza_retroceso)
	_retroceso.tween_property(arma, "position", atras, tiempo_retroceso).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_retroceso.tween_property(arma, "position", _posicion_original_arma, tiempo_recuperacion).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
