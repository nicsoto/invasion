extends StaticBody3D

signal salud_cambiada(actual: int, maxima: int)
signal destruida

@export_range(1, 2000) var salud_maxima := 180
var salud: int
var _flash := 0.0

@onready var nucleo: MeshInstance3D = $Nucleo
@onready var etiqueta: Label3D = $Estado
@onready var blanco: Marker3D = $Blanco
@onready var _material: StandardMaterial3D = nucleo.get_active_material(0)

func _ready() -> void:
	salud = salud_maxima
	_actualizar_visual()

func punto_de_ataque() -> Vector3:
	return blanco.global_position

func recibir_ataque_pequeno(cantidad: int) -> void:
	if salud <= 0 or cantidad <= 0:
		return
	salud = maxi(0, salud - cantidad)
	_flash = 0.25
	salud_cambiada.emit(salud, salud_maxima)
	_actualizar_visual()
	if salud == 0:
		destruida.emit()

func take_damage(_cantidad: int) -> void:
	# Los disparos genéricos de nave y el fuego amigo no dañan el objetivo aliado.
	pass

func _process(delta: float) -> void:
	if _flash > 0:
		_flash = maxf(0, _flash - delta)
		_actualizar_visual()

func _actualizar_visual() -> void:
	var color := Color(0.45, 1.0, 0.025)
	if salud == 0:
		color = Color(0.12, 0.16, 0.14)
	elif _flash > 0 or salud <= salud_maxima * 0.3:
		color = Color(1.0, 0.3, 0.08)
	_material.albedo_color = color
	_material.emission = color
	_material.emission_energy_multiplier = 0.0 if salud == 0 else 0.5
	etiqueta.text = "TORRE DESTRUIDA" if salud == 0 else "TORRE  %d / %d" % [salud, salud_maxima]
	etiqueta.modulate = color if salud > 0 else Color(1.0, 0.3, 0.08)
