extends Control

const Partida = preload("res://integracion/partida.gd")

@onready var menu_principal = $"Menu principal"
@onready var invasion = $invasion
@onready var niveles_menu = $"niveles menú"

@onready var controles = $controles
@onready var label_1 = $Label
@onready var label_2 = $Label2
@onready var texture_rect_4 = $TextureRect4

@onready var boton_back = $back

#menupausa
@onready var pausamenu: MarginContainer = $pausamenu
@onready var pausa: TextureRect = $pausa

#resultados
@onready var victoria_menu = $"victoria menu"
@onready var derrota_menu = $"derrota menu"
@onready var titulo_cleared = $cleared
@onready var titulo_derrota = $DERROTA
@onready var titulo_victoria = $VICTORIA


func _ready():
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if Partida.resultado == "victoria":
		mostrar_victoria()
	elif Partida.resultado == "derrota":
		mostrar_derrota()
	else:
		volver_al_inicio()
	Partida.resultado = ""

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_P and not event.echo:
		alternar_pausa()

func alternar_pausa():
	var nuevo_estado = not get_tree().paused
	get_tree().paused = nuevo_estado
	
	if nuevo_estado == true:
		pausa.show()
		pausamenu.show()
		
		menu_principal.hide()
		invasion.hide()
		niveles_menu.hide()
		controles.hide()
		label_1.hide()
		label_2.hide()
		texture_rect_4.hide()
		boton_back.hide()
	else:
		pausa.hide()
		pausamenu.hide()


# botones Menú Principal
func _on_boton_salir_pressed():
	get_tree().quit() 

#controles
func _on_boton_controles_pressed():
	invasion.hide()
	menu_principal.hide()
	
	controles.show()
	label_1.show()
	label_2.show()
	texture_rect_4.show()
	boton_back.show() 

#niveles
func _on_boton_niveles_pressed():
	ocultar_resultados()
	menu_principal.hide()
	
	niveles_menu.show()
	boton_back.show()

#back
func _on_boton_back_pressed():
	if get_tree().paused == true:
		controles.hide()
		label_1.hide()
		label_2.hide()
		texture_rect_4.hide()
		niveles_menu.hide()
		boton_back.hide()
	
		pausa.show()
		pausamenu.show()
	else:
		volver_al_inicio()

func _on_boton_nivel1_pressed():
	jugar_nivel(1)

func _on_boton_nivel2_pressed():
	jugar_nivel(2)

func _on_boton_nivel3_pressed():
	jugar_nivel(3)

func _on_boton_reintentar_pressed():
	jugar_nivel(Partida.nivel_actual)

func jugar_nivel(numero: int):
	get_tree().paused = false
	Partida.nivel_actual = numero
	get_tree().change_scene_to_file(Partida.ruta_nivel(numero))

func _on_boton_menu_desde_pausa_pressed():
	get_tree().paused = false 
	volver_al_inicio()


func ocultar_resultados():
	victoria_menu.hide()
	derrota_menu.hide()
	titulo_cleared.hide()
	titulo_derrota.hide()
	titulo_victoria.hide()

func mostrar_victoria():
	volver_al_inicio()
	menu_principal.hide()
	invasion.hide()
	victoria_menu.show()
	if Partida.es_ultimo_nivel(Partida.nivel_actual):
		titulo_victoria.show()
	else:
		titulo_cleared.show()

func mostrar_derrota():
	volver_al_inicio()
	menu_principal.hide()
	invasion.hide()
	derrota_menu.show()
	titulo_derrota.show()

func volver_al_inicio():
	ocultar_resultados()
	niveles_menu.hide()
	controles.hide()
	label_1.hide()
	label_2.hide()
	texture_rect_4.hide()
	boton_back.hide()
	
	menu_principal.show()
	invasion.show()
