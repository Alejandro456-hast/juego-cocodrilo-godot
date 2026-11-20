class_name GestorInterfaz
extends CanvasLayer

## ============================================================================
## ARCHIVO: scripts/interfaz/gestor_interfaz.gd
## OBJETO EN ESCENA: "InterfazJuego" (CanvasLayer)
##
## ¿QUÉ HACE ESTE SCRIPT?
## Es el Coordinador de la interfaz gráfica. Ya no maneja los botones internos
## de cada menú, sino que delega en los scripts de cada panel hijo:
## - "MenuInicio" (menu_inicio.gd): Selección de modo de juego.
## - "PanelSuperiorHUD" (panel_superior_hud.gd): Barra superior de turno y manos.
## - "MenuFinPartida" (menu_fin_partida.gd): Pantalla de sobreviviente ganador.
## - "PanelInferiorAviso": Mensajes de narración en la parte baja.
## - "DestelloSangre": Efecto rojo en pantalla al recibir una mordida.
## ============================================================================

signal solicitar_iniciar_partida(asientos_ia: Array[bool])
signal solicitar_cambio_camara()
signal boton_teclado_seleccionado(indice_boton: int)
signal boton_teclado_apuntado(indice_boton: int, esta_apuntado: bool)

@onready var _destello_sangre: ColorRect = $DestelloSangre
@onready var _panel_superior_hud: PanelSuperiorHUD = $PanelSuperiorHUD
@onready var _panel_inferior_aviso: Panel = $PanelInferiorAviso
@onready var _etiqueta_aviso: Label = $PanelInferiorAviso/EtiquetaAviso
@onready var _menu_inicio: MenuInicio = $MenuInicio
@onready var _menu_fin_partida: MenuFinPartida = $MenuFinPartida


func _ready() -> void:
	if _menu_inicio:
		_menu_inicio.solicitar_iniciar_partida.connect(_al_solicitar_iniciar_desde_menu)

	if _panel_superior_hud:
		_panel_superior_hud.solicitar_cambio_camara.connect(func() -> void: solicitar_cambio_camara.emit())
		_panel_superior_hud.solicitar_abrir_menu.connect(mostrar_menu_configuracion)

	if _menu_fin_partida:
		_menu_fin_partida.solicitar_jugar_otra_vez.connect(_al_repetir_partida)
		_menu_fin_partida.solicitar_volver_al_menu.connect(mostrar_menu_configuracion)


func mostrar_menu_configuracion() -> void:
	if _panel_superior_hud:
		_panel_superior_hud.visible = false
	if _panel_inferior_aviso:
		_panel_inferior_aviso.visible = false
	if _menu_fin_partida:
		_menu_fin_partida.visible = false
	if _menu_inicio:
		_menu_inicio.visible = true


func mostrar_hud_partida() -> void:
	if _menu_inicio:
		_menu_inicio.visible = false
	if _menu_fin_partida:
		_menu_fin_partida.visible = false
	if _panel_superior_hud:
		_panel_superior_hud.visible = true
	if _panel_inferior_aviso:
		_panel_inferior_aviso.visible = true


func actualizar_estado_hud(
	jugador_activo: AsientoJugador,
	botones_activos: int,
	total_botones: int,
	vivos: int,
	total_jugadores: int
) -> void:
	if _panel_superior_hud:
		_panel_superior_hud.actualizar_datos(
			jugador_activo,
			botones_activos,
			total_botones,
			vivos,
			total_jugadores
		)


func escribir_narracion(texto: String) -> void:
	if _etiqueta_aviso:
		_etiqueta_aviso.text = texto


func actualizar_texto_boton_camara(es_cerca: bool) -> void:
	if _panel_superior_hud:
		_panel_superior_hud.actualizar_texto_boton_camara(es_cerca)


func sincronizar_teclado(_botones_hundidos: Array[bool], _puede_hacer_clic: bool) -> void:
	pass


func activar_destello_sangre() -> void:
	if not _destello_sangre:
		return
	_destello_sangre.color = Color(0.68, 0.02, 0.02, 0.62)
	var tw := create_tween()
	tw.tween_property(_destello_sangre, "color:a", 0.0, 0.65)


func mostrar_fin_juego(ganador: AsientoJugador) -> void:
	if _menu_fin_partida:
		_menu_fin_partida.mostrar_ganador(ganador)


func _al_solicitar_iniciar_desde_menu(config_ia: Array[bool]) -> void:
	solicitar_iniciar_partida.emit(config_ia)


func _al_repetir_partida() -> void:
	if _menu_inicio:
		solicitar_iniciar_partida.emit(_menu_inicio.asientos_ia)
