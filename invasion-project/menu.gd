extends Control

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


func _ready():
	get_tree().paused = false
	volver_al_inicio()

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
	get_tree().paused = false
	# ruta nivel
	get_tree().change_scene_to_file("res://integracion/juego.tscn")

func _on_boton_menu_desde_pausa_pressed():
	get_tree().paused = false 
	volver_al_inicio()


func volver_al_inicio():
	niveles_menu.hide()
	controles.hide()
	label_1.hide()
	label_2.hide()
	texture_rect_4.hide()
	boton_back.hide()
	
	menu_principal.show()
	invasion.show()
