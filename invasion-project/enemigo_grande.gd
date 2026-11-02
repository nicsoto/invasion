extends CharacterBody3D

var salud = 100
var velocidad = 8.0
var jugador = null
var bala_escena = preload("res://bala.tscn")
var explosion_escena = preload("res://explosion.tscn")
var tiempo_disparo = 0.0 
var can_shoot = true

@onready var canon = $CanonEnemigo
@onready var barra_vida_3d = $BarraVida3D

#sonido
@onready var sonido_disparo: AudioStreamPlayer3D = $SonidoDisparo
@onready var sonido_impacto: AudioStreamPlayer3D = $SonidoImpacto


func _ready():
	jugador = get_tree().get_first_node_in_group("jugador")

func _physics_process(delta):
	if not jugador:
		return
		
	look_at(jugador.global_position, Vector3.UP)
	
	if global_position.distance_to(jugador.global_position) > 15.0:
		var direccion = (jugador.global_position - global_position).normalized()
		velocity = direccion * velocidad
	else:
		velocity = Vector3.ZERO
		
	move_and_slide()
	
	tiempo_disparo += delta
	if tiempo_disparo >= 1.5:
		tiempo_disparo = 0.0
		disparar()

func disparar():
	
	if sonido_disparo:
		sonido_disparo.pitch_scale = randf_range(0.85, 1.15)
		sonido_disparo.play()
		
	
	can_shoot = false
	var nueva_bala = bala_escena.instantiate()
	nueva_bala.disparador = "enemigo_espacial" 
	
	get_parent().add_child(nueva_bala)
	nueva_bala.global_transform = canon.global_transform 
	
	
	await get_tree().create_timer(0.5).timeout
	can_shoot = true

func take_damage(cantidad):
	salud -= cantidad
	
	if sonido_impacto:
		sonido_impacto.pitch_scale = randf_range(0.8, 1.2) # Variación para sonar a chatarra golpeada
		sonido_impacto.play()
	
	barra_vida_3d.scale.x = salud / 100.0
	if salud <= 30:
		barra_vida_3d.get_active_material(0).albedo_color = Color.RED
		
	if salud <= 0:
		var nueva_explosion = explosion_escena.instantiate()
		
		nueva_explosion.global_position = self.global_position 
		
		get_tree().current_scene.add_child(nueva_explosion)
		
		$MeshInstance3D.hide()
		queue_free()
