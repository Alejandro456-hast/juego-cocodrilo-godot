class_name PlatoGiratorio
extends Node3D

## ============================================================================
## ARCHIVO: scripts/maquina/plato_giratorio.gd
## NODO ASIGNADO: "PlatoGiratorio" (dentro de "Mesa" en escenas/principal.tscn)
##
## ¿QUÉ HACE ESTE SCRIPT?
## Controla exclusivamente el disco metálico giratorio en el centro de la mesa:
## 1. Calcula el camino angular más corto (sin dar vueltas innecesarias).
## 2. Gira suavemente el cocodrilo para mirar de frente al jugador en turno.
## ============================================================================


## Gira el plato metálico hacia el ángulo del asiento indicado
func girar_hacia_angulo(angulo_destino: float, animar: bool = true) -> void:
	if not animar:
		rotation.y = angulo_destino
		return

	var actual_y := rotation.y
	var diferencia := wrapf(angulo_destino - actual_y, -PI, PI)
	var destino_final_y := actual_y + diferencia

	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "rotation:y", destino_final_y, 0.55)
	await tw.finished
