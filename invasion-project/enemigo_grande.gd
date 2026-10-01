extends CharacterBody3D

var salud = 100
var velocidad = 8.0
var jugador = null
var bala_escena = preload("res://bala.tscn")

var tiempo_disparo = 0.0 
@onready var canon = $CanonEnemigo

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
	if global_position.distance_to(jugador.global_position) < 60.0:
		var nueva_bala = bala_escena.instantiate()
		nueva_bala.disparador = "enemigo"
		
		get_tree().current_scene.add_child(nueva_bala) 
		nueva_bala.global_position = canon.global_position
		nueva_bala.look_at(jugador.global_position, Vector3.UP)

func take_damage(cantidad):
	salud -= cantidad
	if salud <= 0:
		queue_free()
