class_name CuerpoJugador
extends Node3D

## ============================================================================
## ARCHIVO: scripts/jugador/cuerpo_jugador.gd
## NODO ASIGNADO: "Torso" (dentro de escenas/jugador/asiento_jugador.tscn)
##
## ¿QUÉ HACE ESTE SCRIPT?
## Controla exclusivamente el torso y la cabeza del jugador sentado:
## 1. Aplica el color del traje según el número de asiento.
## 2. Anima la respiración del pecho (tranquila con 2 manos, agitada con 1 mano).
## 3. Restaura la postura del torso y la cabeza al iniciar una nueva partida.
## ============================================================================

const COLORES_TRAJE: Array[Color] = [
	Color(0.16, 0.12, 0.12),
	Color(0.11, 0.14, 0.16),
	Color(0.15, 0.14, 0.10),
	Color(0.13, 0.10, 0.15),
	Color(0.10, 0.15, 0.12),
]

@onready var malla_torso: MeshInstance3D = $MallaTorso
@onready var cabeza: Node3D = $Cabeza

var esta_herido: bool = false
var _respiracion_activa: bool = true
var _posicion_inicial: Vector3 = Vector3(0.0, 0.92, 0.06)
var _tiempo: float = 0.0


func _ready() -> void:
	_posicion_inicial = position


func _process(delta: float) -> void:
	if not _respiracion_activa:
		return
	_tiempo += delta
	var velocidad_respiracion := 5.5 if esta_herido else 2.2
	position.y = _posicion_inicial.y + sin(_tiempo * velocidad_respiracion) * 0.008


## Aplica un color de traje único para distinguir a cada uno de los 5 jugadores
func aplicar_color_traje(indice_asiento: int, desfase_tiempo: float = 0.0) -> void:
	_tiempo = desfase_tiempo
	var mat := StandardMaterial3D.new()
	mat.albedo_color = COLORES_TRAJE[indice_asiento % COLORES_TRAJE.size()]
	mat.roughness = 0.9
	if malla_torso:
		malla_torso.material_override = mat


## Restaura el torso y la cabeza a su postura original en la silla
func reiniciar_cuerpo() -> void:
	esta_herido = false
	_respiracion_activa = true
	visible = true
	position = _posicion_inicial
	rotation_degrees = Vector3.ZERO
	if cabeza:
		cabeza.rotation_degrees = Vector3.ZERO


## Detiene el movimiento de respiración (cuando el jugador muere o cae al abismo)
func detener_respiracion() -> void:
	_respiracion_activa = false
