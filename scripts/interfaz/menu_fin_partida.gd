class_name MenuFinPartida
extends Panel

## ============================================================================
## ARCHIVO: scripts/interfaz/menu_fin_partida.gd
## NODO ASIGNADO: "MenuFinPartida" (dentro de "InterfazJuego")
##
## ¿QUÉ HACE ESTE SCRIPT?
## Controla exclusivamente el panel de Fin de Partida cuando solo queda 1 vivo:
## 1. Muestra el nombre del sobreviviente y con cuántas manos salió con vida.
## 2. Conecta el botón "JUGAR OTRA PARTIDA" y el botón "CAMBIAR MODO DE JUEGO".
## ============================================================================

signal solicitar_jugar_otra_vez()
signal solicitar_volver_al_menu()

@onready var etiqueta_ganador: Label = $EtiquetaGanador
@onready var boton_jugar_otra_vez: Button = $BotonJugarOtraVez
@onready var boton_volver_al_menu: Button = $BotonVolverAlMenu


func _ready() -> void:
	if boton_jugar_otra_vez:
		boton_jugar_otra_vez.pressed.connect(func() -> void: solicitar_jugar_otra_vez.emit())
	if boton_volver_al_menu:
		boton_volver_al_menu.pressed.connect(func() -> void: solicitar_volver_al_menu.emit())


func mostrar_ganador(ganador: AsientoJugador) -> void:
	visible = true
	if not etiqueta_ganador:
		return
	if ganador:
		var rol_str := "Bot IA" if ganador.es_ia else "Jugador Humano"
		etiqueta_ganador.text = "¡%s (%s) es el único sobreviviente!\n\nSalió del cuarto con %d %s." % [
			ganador.nombre_jugador,
			rol_str,
			ganador.manos_restantes,
			"mano sana" if ganador.manos_restantes == 1 else "manos sanas"
		]
	else:
		etiqueta_ganador.text = "Nadie sobrevivió a la mesa del cocodrilo."
