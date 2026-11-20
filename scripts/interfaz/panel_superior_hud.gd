class_name PanelSuperiorHUD
extends Panel

## ============================================================================
## ARCHIVO: scripts/interfaz/panel_superior_hud.gd
## NODO ASIGNADO: "PanelSuperiorHUD" (dentro de "InterfazJuego")
##
## ¿QUÉ HACE ESTE SCRIPT?
## Controla exclusivamente la barra superior informativa durante la partida:
## 1. Muestra de quién es el turno actual ("EtiquetaTurno").
## 2. Muestra cuántas manos le quedan al jugador en turno ("EtiquetaManos").
## 3. Muestra cuántos botones y jugadores siguen activos ("EtiquetaBotones").
## 4. Conecta los botones "Vista" y "Menú" de la esquina superior derecha.
## ============================================================================

signal solicitar_cambio_camara()
signal solicitar_abrir_menu()

@onready var etiqueta_turno: Label = $EtiquetaTurno
@onready var etiqueta_manos: Label = $EtiquetaManos
@onready var etiqueta_botones: Label = $EtiquetaBotones
@onready var boton_cambiar_vista: Button = $BotonCambiarVista
@onready var boton_abrir_menu: Button = $BotonAbrirMenu


func _ready() -> void:
	if boton_cambiar_vista:
		boton_cambiar_vista.pressed.connect(func() -> void: solicitar_cambio_camara.emit())
	if boton_abrir_menu:
		boton_abrir_menu.pressed.connect(func() -> void: solicitar_abrir_menu.emit())


func actualizar_datos(
	jugador_activo: AsientoJugador,
	botones_activos: int,
	total_botones: int,
	vivos: int,
	total_jugadores: int
) -> void:
	var rol_txt := "BOT IA" if jugador_activo.es_ia else "HUMANO"
	if etiqueta_turno:
		etiqueta_turno.text = "TURNO: %s (%s)" % [jugador_activo.nombre_jugador.to_upper(), rol_txt]

	if etiqueta_manos:
		if jugador_activo.manos_restantes == 2:
			etiqueta_manos.text = "MANOS SANAS: 2 / 2"
			etiqueta_manos.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
		else:
			etiqueta_manos.text = "¡PELIGRO! 1 MANO RESTANTE"
			etiqueta_manos.add_theme_color_override("font_color", Color(1.0, 0.38, 0.32))

	if etiqueta_botones:
		etiqueta_botones.text = "BOTONES: %d / %d  •  VIVOS: %d / %d" % [
			botones_activos,
			total_botones,
			vivos,
			total_jugadores
		]


func actualizar_texto_boton_camara(es_cerca: bool) -> void:
	if boton_cambiar_vista:
		boton_cambiar_vista.text = "Vista: Fauces" if es_cerca else "Vista: Mesa"
