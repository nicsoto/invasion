extends CharacterBody3D

var bala_escena = preload("res://bala.tscn")
var esta_activa = true
var can_shoot = true
var salud = 100


var vel_normal = 20.0
var vel_sprint = 45.0
var vel_actual = 20.0

# Sprint
var tiempo_ultimo_w = 0.0
var esta_sprinteando = false

var sensibilidad = 0.004

@onready var menu_muerte = $HUD/MenuMuerte

@onready var head = $Head
@onready var canon = $Head/Canon

@onready var barra_salud = $HUD/BarraSalud
@onready var menu_pausa = $HUD/MenuPausa
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if not esta_activa:
		return
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	if event.is_action_pressed("Pausa"):
		var esta_pausado = not get_tree().paused
		get_tree().paused = esta_pausado
		menu_pausa.visible = esta_pausado
		
		if esta_pausado:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else: 
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if get_tree().paused:
		return
	
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensibilidad)
		head.rotate_x(-event.relative.y * sensibilidad)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-60), deg_to_rad(60))

	# Sprint
	if event.is_action_pressed("arriba"):
		var tiempo_actual = Time.get_ticks_msec() / 1000.0
		if tiempo_actual - tiempo_ultimo_w < 0.3:
			esta_sprinteando = true
		tiempo_ultimo_w = tiempo_actual
		
	if event.is_action_released("arriba"):
		esta_sprinteando = false

func _physics_process(delta):
	if get_tree().paused: return
	if not esta_activa: return

	vel_actual = vel_sprint if esta_sprinteando else vel_normal

	
	var input_dir = Input.get_vector("izquierda", "derecha", "arriba", "abajo")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * vel_actual
		velocity.z = direction.z * vel_actual
	else:
		velocity.x = move_toward(velocity.x, 0, vel_actual)
		velocity.z = move_toward(velocity.z, 0, vel_actual)
		
	var vertical = 0.0
	if Input.is_action_pressed("ascender"): vertical += 1.0
	if Input.is_action_pressed("descender"): vertical -= 1.0
	velocity.y = vertical * vel_actual

	move_and_slide()

	# Disparo
	if Input.is_action_pressed("disparar") and can_shoot:
		disparar()

func disparar():
	can_shoot = false
	var nueva_bala = bala_escena.instantiate()
	nueva_bala.disparador = "jugador" 
	get_parent().add_child(nueva_bala)
	nueva_bala.global_transform = canon.global_transform 
	
	await get_tree().create_timer(0.2).timeout
	can_shoot = true
	
func take_damage(cantidad):
	if salud <=0:
		return
	salud -= cantidad
	barra_salud.value= salud
	
	if salud <= 0:
		get_tree().paused = true
		menu_muerte.visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	
	


func _on_boton_jugar_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_boton_salir_pressed() -> void:
	get_tree().quit()
