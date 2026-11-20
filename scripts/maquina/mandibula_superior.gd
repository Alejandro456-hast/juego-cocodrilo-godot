class_name MandibulaSuperior
extends Node3D

## ============================================================================
## ARCHIVO: scripts/maquina/mandibula_superior.gd
## NODO ASIGNADO: "MandibulaSuperior" (dentro de escenas/maquina/maquina_cocodrilo.tscn)
##
## ¿QUÉ HACE ESTE SCRIPT?
## Controla exclusivamente la mandíbula superior del cocodrilo y sus ojos:
## 1. Hace temblar ligeramente las fauces según el nivel de peligro de la ronda.
## 2. Aumenta el brillo rojo de "OjoIzquierdo" y "OjoDerecho" cuando sube la tensión.
## 3. Ejecuta el golpe violento de cierre (mordida de guillotina).
## 4. Vuelve a abrir las fauces lentamente para el siguiente turno.
## ============================================================================

const ANGULO_BOCA_ABIERTA := -54.0
const ANGULO_BOCA_CERRADA := -3.5

@onready var ojo_izquierdo: MeshInstance3D = $OjoIzquierdo
@onready var ojo_derecho: MeshInstance3D = $OjoDerecho

var _mat_ojo_izq: StandardMaterial3D
var _mat_ojo_der: StandardMaterial3D
var _tiempo: float = 0.0
var _esta_mordiendo: bool = false
var _nivel_tension: float = 0.0


func _ready() -> void:
	_mat_ojo_izq = StandardMaterial3D.new()
	_mat_ojo_izq.albedo_color = Color(0.0, 0.63, 0.571, 1.0)
	_mat_ojo_izq.emission_enabled = true
	_mat_ojo_izq.emission = Color(0.0, 0.627, 0.549, 1.0)
	_mat_ojo_izq.emission_energy_multiplier = 2.4
	_mat_ojo_der = _mat_ojo_izq.duplicate()

	if ojo_izquierdo:
		ojo_izquierdo.material_override = _mat_ojo_izq
	if ojo_derecho:
		ojo_derecho.material_override = _mat_ojo_der


func _process(delta: float) -> void:
	_tiempo += delta
	if not _esta_mordiendo:
		var temblor := sin(_tiempo * (3.5 + _nivel_tension * 9.0)) * (0.35 + _nivel_tension * 1.1)
		rotation_degrees.x = ANGULO_BOCA_ABIERTA + temblor


## Ajusta el temblor de la mandíbula y la intensidad luminosa de los ojos rojos
func ajustar_tension(proporcion: float) -> void:
	_nivel_tension = clampf(proporcion, 0.0, 1.0)
	if _mat_ojo_izq and _mat_ojo_der:
		var energia := 1.8 + _nivel_tension * 3.5
		_mat_ojo_izq.emission_energy_multiplier = energia
		_mat_ojo_der.emission_energy_multiplier = energia


## Cierra de golpe la mandíbula superior y ejecuta el callback justo al impactar
func animar_cierre_mordida(al_impactar: Callable) -> void:
	_esta_mordiendo = true
	if _mat_ojo_izq and _mat_ojo_der:
		_mat_ojo_izq.emission_energy_multiplier = 7.0
		_mat_ojo_der.emission_energy_multiplier = 7.0

	var tw := create_tween()
	tw.tween_property(self, "rotation_degrees:x", ANGULO_BOCA_CERRADA, 0.065).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tw.tween_callback(al_impactar)
	await tw.finished


## Reabre lentamente la mandíbula superior hasta su ángulo inicial
func animar_reapertura() -> void:
	var tw := create_tween()
	tw.tween_property(self, "rotation_degrees:x", ANGULO_BOCA_ABIERTA, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	_esta_mordiendo = false
