extends Node3D
## Encuentro local reutilizable. El nivel decide cuándo iniciarlo y qué viene después.

signal defensa_iniciada
signal defensa_completada
signal torre_destruida
signal progreso_cambiado(restantes: int)

enum Estado { ESPERA, PREPARACION, DEFENDIENDO, COMPLETADA, DESTRUIDA }

const Atacante = preload("res://terrestre/defensa/atacante_torre.tscn")

@export_range(1, 12) var cantidad_atacantes := 4
@export_range(0.0, 60.0) var preparacion := 12.0
@export_range(0.2, 30.0) var intervalo_llegadas := 5.0

var estado := Estado.ESPERA
var tiempo_restante := 0.0
var generados := 0
var _activos: Dictionary = {}

@onready var torre = $Torre
@onready var cupula = $Cupula
@onready var atacantes: Node3D = $Atacantes

func _ready() -> void:
	torre.destruida.connect(_al_destruir_torre)

func iniciar() -> void:
	if estado != Estado.ESPERA:
		return
	estado = Estado.PREPARACION
	tiempo_restante = preparacion
	defensa_iniciada.emit()
	progreso_cambiado.emit(restantes())

func _physics_process(delta: float) -> void:
	if estado != Estado.PREPARACION and estado != Estado.DEFENDIENDO:
		return
	tiempo_restante = maxf(0, tiempo_restante - delta)
	if tiempo_restante == 0 and generados < cantidad_atacantes:
		estado = Estado.DEFENDIENDO
		_crear_atacante()
		tiempo_restante = intervalo_llegadas

func restantes() -> int:
	return cantidad_atacantes - generados + _activos.size()

func _crear_atacante() -> void:
	var angulos := [PI - 0.6, PI + 0.6, -0.9, 0.9]
	var angulo: float = angulos[generados % angulos.size()] + floorf(generados / 4.0) * 0.3
	var direccion := Vector3(sin(angulo), 0, cos(angulo))
	var enemigo = Atacante.instantiate()
	enemigo.position = direccion * 25.0 + Vector3.UP * 4.0
	var destino := to_global(direccion * 10.0 + Vector3.UP * 3.8)
	enemigo.configurar(torre, cupula, destino)
	var id := enemigo.get_instance_id()
	_activos[id] = enemigo
	enemigo.derrotado.connect(_al_derrotar_atacante.bind(id))
	atacantes.add_child(enemigo)
	generados += 1
	progreso_cambiado.emit(restantes())

func _al_derrotar_atacante(id: int) -> void:
	_activos.erase(id)
	if estado != Estado.DEFENDIENDO:
		return
	progreso_cambiado.emit(restantes())
	# No completar cuando todavía faltan enemigos por aparecer.
	if generados == cantidad_atacantes and _activos.is_empty() and torre.salud > 0:
		estado = Estado.COMPLETADA
		defensa_completada.emit()

func _al_destruir_torre() -> void:
	if estado == Estado.DESTRUIDA or estado == Estado.COMPLETADA:
		return
	estado = Estado.DESTRUIDA
	cupula.habilitada = false
	for enemigo in _activos.values():
		if is_instance_valid(enemigo):
			enemigo.set_physics_process(false)
	torre_destruida.emit()
