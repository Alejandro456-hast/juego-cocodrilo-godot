class_name ManoJugador
extends Node3D

## ============================================================================
## ARCHIVO: scripts/jugador/mano_jugador.gd
## NODO ASIGNADO: "ManoDerecha" y "ManoIzquierda" (en asiento_jugador.tscn)
##
## ¿QUÉ HACE ESTE SCRIPT?
## Controla de forma independiente cada mano del jugador:
## 1. Guarda su posición de descanso sobre la mesa.
## 2. Anima el movimiento de acercarse y presionar un botón en la boca del cocodrilo.
## 3. Anima el retiro de la mano sana de vuelta a la mesa.
## 4. Ejecuta la amputación (oculta "PalmaCompleta" y muestra "MunonSangriento").
## 5. Hace temblar la mano de miedo cuando al jugador solo le queda 1 vida.
## ============================================================================

@onready var palma_completa: Node3D = $PalmaCompleta
@onready var munon_sangriento: MeshInstance3D = $MunonSangriento

var esta_amputada: bool = false
var temblor_activo: bool = false
var amplitud_temblor: float = 0.004

var _posicion_reposo: Vector3 = Vector3.ZERO
var _esta_estirando: bool = false
var _detener_procesamiento: bool = false
var _tiempo: float = 0.0


func _ready() -> void:
	_posicion_reposo = position
	actualizar_mallas()


func _process(delta: float) -> void:
	if _detener_procesamiento:
		return
	_tiempo += delta

	if not _esta_estirando:
		if temblor_activo and not esta_amputada:
			position = _posicion_reposo + Vector3(
				sin(_tiempo * 34.0) * amplitud_temblor,
				cos(_tiempo * 29.0) * (amplitud_temblor * 0.6),
				sin(_tiempo * 23.0) * amplitud_temblor
			)
		else:
			position = _posicion_reposo


## Restaura la mano completa y sana en su posición sobre la mesa
func reiniciar_mano(desfase_tiempo: float = 0.0) -> void:
	_tiempo = desfase_tiempo
	esta_amputada = false
	temblor_activo = false
	_esta_estirando = false
	_detener_procesamiento = false
	visible = true
	position = _posicion_reposo
	actualizar_mallas()


## Activa o desactiva el temblor de pánico en esta mano
func configurar_temblor(activo: bool, es_turno_actual: bool) -> void:
	temblor_activo = activo
	amplitud_temblor = 0.009 if es_turno_actual else 0.004


## Desactiva el ajuste automático de posición (por ejemplo, al caer al abismo)
func preparar_para_caida() -> void:
	_detener_procesamiento = true


## Anima la mano entrando a las fauces del cocodrilo para presionar un botón
func estirar_hacia_boton(pos_global_destino: Vector3) -> void:
	_esta_estirando = true
	var pos_arriba := pos_global_destino + Vector3(0.0, 0.08, 0.0)
	var pos_presionar := pos_global_destino + Vector3(0.0, 0.015, 0.0)

	var tw := create_tween()
	tw.tween_property(self, "global_position", pos_arriba, 0.30).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position", pos_presionar, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished


## Retira la mano sana de vuelta a su lugar en la mesa
func retirar_sana() -> void:
	var tw := create_tween()
	tw.tween_property(self, "position", _posicion_reposo, 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tw.finished
	_esta_estirando = false


## Amputa la mano mostrando el muñón sangriento y retirando el brazo de golpe
func amputar() -> void:
	esta_amputada = true
	temblor_activo = false
	actualizar_mallas()

	var tw := create_tween()
	tw.tween_property(self, "position", _posicion_reposo, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
	_esta_estirando = false


## Muestra la palma sana o el muñón según el estado de la mano
func actualizar_mallas() -> void:
	if palma_completa:
		palma_completa.visible = not esta_amputada
	if munon_sangriento:
		munon_sangriento.visible = esta_amputada
