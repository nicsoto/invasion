extends RefCounted
## Datos que se conservan al cambiar de escena entre el menú y los niveles.

const MENU := "res://menu.tscn"
const NIVELES := [
	"res://integracion/niveles/nivel_1.tscn",
	"res://integracion/niveles/nivel_2.tscn",
	"res://integracion/niveles/nivel_3.tscn",
]

static var nivel_actual := 1
static var resultado := ""

static func ruta_nivel(numero: int) -> String:
	return NIVELES[clampi(numero, 1, NIVELES.size()) - 1]

static func es_ultimo_nivel(numero: int) -> bool:
	return numero >= NIVELES.size()
