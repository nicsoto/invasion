extends Node3D
## Semiesfera cerrada: permite ataques pequeños y disparos terrestres desde dentro.

signal disparo_bloqueado

@export_range(1.0, 100.0) var radio := 19.5
@export var habilitada := true

var _flash := 0.0
@onready var visual: MeshInstance3D = $Visual

func _ready() -> void:
	add_to_group("cupula_defensa")
	visual.material_override = visual.material_override.duplicate()
	visual.scale = Vector3.ONE * radio

func _process(delta: float) -> void:
	_flash = maxf(_flash - delta * 3.0, 0.0)
	visual.visible = habilitada
	visual.material_override.set_shader_parameter("impacto", _flash)

func contiene(punto: Vector3) -> bool:
	var local := to_local(punto)
	return local.y >= -0.05 and local.length_squared() <= radio * radio

func interseccion_bloqueada(desde: Vector3, hasta: Vector3,
		tipo: StringName) -> Dictionary:
	if not habilitada or tipo == &"enemigo_pequeno":
		return {}
	if tipo == &"terrestre" and contiene(desde):
		return {}
	if contiene(desde):
		return {"position": desde, "cupula": self}
	var inicio := to_local(desde)
	var direccion := to_local(hasta) - inicio
	var a := direccion.length_squared()
	if a < 0.000001:
		return {}
	var b := 2.0 * inicio.dot(direccion)
	var c := inicio.length_squared() - radio * radio
	var discriminante := b * b - 4.0 * a * c
	var fraccion := INF
	if discriminante >= 0:
		for t in [(-b - sqrt(discriminante)) / (2.0 * a),
				(-b + sqrt(discriminante)) / (2.0 * a)]:
			if t >= 0 and t <= 1 and (inicio + direccion * t).y >= 0:
				fraccion = minf(fraccion, t)
	# La base también se cierra: no permite atacar desde debajo del asteroide.
	if absf(direccion.y) > 0.00001:
		var t := -inicio.y / direccion.y
		if t >= 0 and t <= 1 and (inicio + direccion * t).length_squared() <= radio * radio:
			fraccion = minf(fraccion, t)
	if is_inf(fraccion):
		return {}
	return {"position": desde.lerp(hasta, fraccion), "cupula": self}

func notificar_bloqueo() -> void:
	_flash = 1.0
	disparo_bloqueado.emit()
