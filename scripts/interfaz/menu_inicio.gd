class_name MenuInicio
extends Panel

## ============================================================================
## ARCHIVO: scripts/interfaz/menu_inicio.gd
## NODO ASIGNADO: "MenuInicio" (dentro de "InterfazJuego")
##
## ¿QUÉ HACE ESTE SCRIPT?
## Controla exclusivamente el panel del Menú de Inicio:
## 1. Permite elegir entre los 3 modos de juego (1 Humano, 2 Humanos o 5 Humanos).
## 2. Actualiza la etiqueta con el modo actualmente elegido.
## 3. Avisa cuando el jugador presiona el botón "JUGAR AHORA".
## ============================================================================

signal solicitar_iniciar_partida(asientos_ia: Array[bool])

var asientos_ia: Array[bool] = [false, true, true, true, true]

@onready var boton_modo_1h: Button = $BotonModo1Humano
@onready var boton_modo_2h: Button = $BotonModo2Humanos
@onready var boton_modo_5h: Button = $BotonModo5Humanos
@onready var etiqueta_modo_seleccionado: Label = $EtiquetaModoSeleccionado
@onready var boton_empezar_partida: Button = $BotonEmpezarPartida


func _ready() -> void:
	if boton_modo_1h:
		boton_modo_1h.pressed.connect(_elegir_modo_1_humano)
	if boton_modo_2h:
		boton_modo_2h.pressed.connect(_elegir_modo_2_humanos)
	if boton_modo_5h:
		boton_modo_5h.pressed.connect(_elegir_modo_5_humanos)
	if boton_empezar_partida:
		boton_empezar_partida.pressed.connect(_al_presionar_empezar)


func _elegir_modo_1_humano() -> void:
	asientos_ia = [false, true, true, true, true]
	if etiqueta_modo_seleccionado:
		etiqueta_modo_seleccionado.text = "Seleccionado: 1 Jugador vs 4 Bots (IA)"


func _elegir_modo_2_humanos() -> void:
	asientos_ia = [false, false, true, true, true]
	if etiqueta_modo_seleccionado:
		etiqueta_modo_seleccionado.text = "Seleccionado: 2 Jugadores vs 3 Bots (IA)"


func _elegir_modo_5_humanos() -> void:
	asientos_ia = [false, false, false, false, false]
	if etiqueta_modo_seleccionado:
		etiqueta_modo_seleccionado.text = "Seleccionado: 5 Jugadores Humanos (Por Turnos)"


func _al_presionar_empezar() -> void:
	solicitar_iniciar_partida.emit(asientos_ia)
