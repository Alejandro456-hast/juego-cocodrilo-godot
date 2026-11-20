class_name LuzHabitacion
extends Node3D

## ============================================================================
## ARCHIVO: scripts/ambiente/luz_habitacion.gd
## NODO ASIGNADO: "PivoteLampara" (dentro de "Habitacion" en escenas/principal.tscn)
##
## ¿QUÉ HACE ESTE SCRIPT?
## Está asignado directamente al nodo de la lámpara colgante del techo:
## 1. Balancea suavemente el cable y la pantalla de la lámpara como un péndulo.
## 2. Hace parpadear ligeramente su bombilla ("FocoLuz") sobre la mesa.
## ============================================================================

@onready var _foco_luz: SpotLight3D = get_node_or_null("FocoLuz")

var _tiempo: float = 0.0


func _process(delta: float) -> void:
	_tiempo += delta

	# Balanceo suave del propio nodo PivoteLampara
	rotation_degrees.z = sin(_tiempo * 1.15) * 1.8
	rotation_degrees.x = cos(_tiempo * 0.85) * 1.2

	# Parpadeo eléctrico del foco de luz hijo
	if _foco_luz:
		var parpadeo := 1.0 + sin(_tiempo * 19.0) * 0.025 + cos(_tiempo * 43.0) * 0.015
		_foco_luz.light_energy = 6.2 * parpadeo
