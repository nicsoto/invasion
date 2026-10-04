extends RefCounted
## Controles propios: no sobrescriben las acciones del combate espacial.

static func registrar() -> void:
	var teclas := {
		"pie_adelante": KEY_W, "pie_atras": KEY_S,
		"pie_izquierda": KEY_A, "pie_derecha": KEY_D,
		"pie_saltar": KEY_SPACE, "pie_correr": KEY_SHIFT,
		"pie_interactuar": KEY_E,
	}
	for accion in teclas:
		if InputMap.has_action(accion):
			continue
		InputMap.add_action(accion)
		var evento := InputEventKey.new()
		evento.physical_keycode = teclas[accion]
		InputMap.action_add_event(accion, evento)
	if not InputMap.has_action("pie_disparar"):
		InputMap.add_action("pie_disparar")
		var evento := InputEventMouseButton.new()
		evento.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("pie_disparar", evento)
