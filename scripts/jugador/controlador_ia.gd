class_name ControladorIA
extends Node

## ============================================================================
## ARCHIVO: scripts/jugador/controlador_ia.gd
## OBJETO EN ESCENA: "ControladorIA" (dentro de escenas/principal.tscn)
##
## ¿QUÉ HACE ESTE SCRIPT?
## Controla la Inteligencia Artificial de los jugadores controlados por PC (Bots):
## 1. Asigna una personalidad a cada bot (Metódico, Nervioso, Temerario, etc.).
## 2. Escribe lo que el bot está pensando según si tiene 2 manos o solo 1.
## 3. Hace que el bot dude iluminando varios botones de la lengua antes de
##    presionar el botón definitivo.
## ============================================================================

const PERSONALIDADES: Array[String] = [
	"Metódico",
	"Nervioso",
	"Temerario",
	"Paranoico",
	"Calculador",
]

const FRASES_DOS_MANOS: Array[String] = [
	"observa los colmillos oxidados en silencio...",
	"acerca los dedos dudando sobre la lengua...",
	"intenta escuchar algún resorte suelto dentro de la máquina...",
	"respira hondo bajo la única luz del cuarto...",
]

const FRASES_UNA_MANO: Array[String] = [
	"tiembla violentamente con su única mano sana...",
	"mira su muñón ensangrentado antes de elegir un botón...",
	"ruega en voz baja que este botón no active la guillotina...",
	"duda aterrorizado antes de meter su última mano en las fauces...",
]


func obtener_personalidad(indice_asiento: int) -> String:
	return PERSONALIDADES[indice_asiento % PERSONALIDADES.size()]


func crear_narracion_pensamiento(jugador: AsientoJugador, cantidad_botones_activos: int) -> String:
	var personalidad := obtener_personalidad(jugador.indice_asiento)
	var lista_frases := FRASES_UNA_MANO if jugador.manos_restantes == 1 else FRASES_DOS_MANOS
	var frase := lista_frases[randi() % lista_frases.size()]
	var porcentaje_riesgo := int(round((1.0 / float(maxi(1, cantidad_botones_activos))) * 100.0))
	return "%s (%s) %s [Riesgo: %d%%]" % [jugador.nombre_jugador, personalidad, frase, porcentaje_riesgo]


func elegir_boton_con_suspenso(
	jugador: AsientoJugador,
	indices_disponibles: Array[int],
	cocodrilo: MaquinaCocodrilo,
	sonidos: EfectosSonido
) -> int:
	if indices_disponibles.is_empty():
		return 0

	var personalidad := obtener_personalidad(jugador.indice_asiento)

	var dudas := 2
	if personalidad == "Nervioso" or jugador.manos_restantes == 1:
		dudas = 3
	elif personalidad == "Temerario":
		dudas = 1

	dudas = mini(dudas, indices_disponibles.size())

	var indice_elegido: int = indices_disponibles[randi() % indices_disponibles.size()]
	if personalidad == "Metódico":
		indice_elegido = indices_disponibles[0] if randf() < 0.6 else indices_disponibles[indices_disponibles.size() - 1]
	elif personalidad == "Calculador" and indices_disponibles.size() >= 3:
		var mitad := indices_disponibles.size() / 2
		indice_elegido = indices_disponibles[mitad]

	for d in range(dudas):
		var idx_previo: int = indices_disponibles[randi() % indices_disponibles.size()]
		if d == dudas - 1:
			idx_previo = indice_elegido
		cocodrilo.botones[idx_previo].resaltar_duda_ia(true)
		if sonidos:
			sonidos.reproducir_apuntar()
		var espera := 0.36 if jugador.manos_restantes == 2 else 0.48
		await get_tree().create_timer(espera).timeout
		cocodrilo.botones[idx_previo].resaltar_duda_ia(false)

	return indice_elegido
