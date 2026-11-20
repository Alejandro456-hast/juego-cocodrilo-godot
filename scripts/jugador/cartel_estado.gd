class_name CartelEstadoJugador
extends Label3D

## ============================================================================
## ARCHIVO: scripts/jugador/cartel_estado.gd
## NODO ASIGNADO: "CartelEstado" (dentro de escenas/jugador/asiento_jugador.tscn)
##
## ¿QUÉ HACE ESTE SCRIPT?
## Actualiza el cartel 3D flotante sobre la cabeza de cada jugador:
## 1. Muestra su nombre y si es HUMANO o IA.
## 2. Muestra cuántas manos le quedan ([ 2 / 2 ], [ 1 / 2 ] HERIDO o [ CAYÓ AL ABISMO ]).
## 3. Cambia su color a dorado cuando es su turno, naranja si está herido y rojo al caer.
## ============================================================================


func actualizar_cartel(nombre_jugador: String, es_ia: bool, manos_restantes: int, es_turno_actual: bool) -> void:
	var etiqueta_rol := "IA" if es_ia else "HUMANO"
	if manos_restantes <= 0:
		text = "%s [%s]\n[ CAYÓ AL ABISMO ]" % [nombre_jugador, etiqueta_rol]
		modulate = Color(0.65, 0.14, 0.14)
	else:
		var texto_manos := "MANOS: [ 2 / 2 ]" if manos_restantes == 2 else "MANOS: [ 1 / 2 ] (HERIDO)"
		var prefijo := "▶ " if es_turno_actual else ""
		text = "%s%s [%s]\n%s" % [prefijo, nombre_jugador, etiqueta_rol, texto_manos]
		if es_turno_actual:
			modulate = Color(1.0, 0.85, 0.30)
		elif manos_restantes == 1:
			modulate = Color(0.95, 0.45, 0.35)
		else:
			modulate = Color(0.82, 0.80, 0.76)
