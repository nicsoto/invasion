extends "res://terrestre/enemigo_especial.gd"
## Variante del centinela existente, asignada a una torre y una cúpula concretas.

const ReglasCupula = preload("res://terrestre/defensa/reglas_cupula.gd")

var torre: Node3D
var cupula: Node3D
var punto_ataque := Vector3.ZERO

func configurar(objetivo: Node3D, escudo: Node3D, destino: Vector3) -> void:
	torre = objetivo
	cupula = escudo
	punto_ataque = destino

func _physics_process(delta: float) -> void:
	if salud <= 0 or not is_instance_valid(torre) or torre.salud <= 0:
		return
	_flash = maxf(0, _flash - delta)
	_tiempo += delta
	var destino := punto_ataque + Vector3(sin(_tiempo) * 1.0, sin(_tiempo * 0.7) * 0.25, 0)
	velocity = (destino - global_position).limit_length(velocidad_patrulla)
	move_and_slide()
	var blanco: Vector3 = torre.punto_de_ataque()
	# Los modelos actuales tienen el cañón orientado hacia +Z.
	look_at(blanco, Vector3.UP, true)
	if _aviso > 0:
		_aviso -= delta
		if _aviso <= 0:
			_disparar()
			_espera = intervalo_ataque
	else:
		_espera = maxf(0, _espera - delta)
		if _espera == 0 and canon.global_position.distance_to(blanco) <= alcance:
			_objetivo = torre
			if _puede_ver(blanco):
				_destino_disparo = blanco
				_aviso = tiempo_aviso
	_actualizar_estado()

func _disparar() -> void:
	sonido_disparo.pitch_scale = randf_range(0.85, 1.15)
	sonido_disparo.play()
	var desde := canon.global_position
	var hasta := _destino_disparo
	var escudo := ReglasCupula.interceptar(get_tree(), desde, hasta, &"enemigo_pequeno")
	if not escudo.is_empty():
		hasta = escudo.position
	else:
		var direccion := (hasta - desde).normalized()
		var consulta := PhysicsRayQueryParameters3D.create(desde, hasta + direccion,
			collision_mask, [get_rid()])
		var impacto := get_world_3d().direct_space_state.intersect_ray(consulta)
		if not impacto.is_empty():
			hasta = impacto.position
			var cuerpo: Node = impacto.collider
			if cuerpo == torre:
				torre.recibir_ataque_pequeno(dano)
			elif cuerpo.is_in_group("personaje_terrestre"):
				cuerpo.take_damage(dano)
	Trazo.mostrar(get_tree().current_scene, desde, hasta, Color(1, 0.3, 0.08))

func recibir_disparo_desde(cantidad: int, atacante: Node3D) -> bool:
	if not is_instance_valid(atacante) or not is_instance_valid(cupula):
		return false
	if not atacante.is_in_group("personaje_terrestre") or not atacante.activo \
			or atacante.en_transicion:
		return false
	if not cupula.contiene(atacante.camara.global_position):
		cupula.notificar_bloqueo()
		take_damage(0)
		return false
	return super.recibir_disparo_terrestre(cantidad)

func recibir_disparo_terrestre(_cantidad: int) -> bool:
	# La variante protegida requiere contexto del atacante, no solo cantidad de daño.
	take_damage(0)
	return false

func _actualizar_estado() -> void:
	super._actualizar_estado()
	if _aviso > 0 and _flash <= 0:
		etiqueta.text = "¡ATACANDO TORRE!"
	elif _flash <= 0:
		etiqueta.text = "ASALTANTE  %d / %d" % [salud, salud_maxima]
