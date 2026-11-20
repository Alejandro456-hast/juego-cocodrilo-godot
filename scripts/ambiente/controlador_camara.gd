class_name ControladorCamara
extends Camera3D

## ============================================================================
## ARCHIVO: scripts/ambiente/controlador_camara.gd
## OBJETO EN ESCENA: "CamaraPrincipal" (dentro de escenas/principal.tscn)
##
## ¿QUÉ HACE ESTE SCRIPT?
## Controla el movimiento de la cámara 3D durante la partida:
## 1. Mueve la cámara al asiento del jugador al que le toca el turno.
## 2. Permite cambiar entre la vista de cerca (Fauces) y la vista lejana (Mesa).
## 3. Enfocada cinemática (enfocar_cinematica_eliminacion) cuando un jugador
##    pierde sus 2 manos y se abre la trampilla para tirarlo al abismo.
## 4. Sacude la cámara con fuerza cuando el cocodrilo corta una mano.
## ============================================================================

var modo_vista_cerca: bool = true

var _posicion_base := Vector3(0.0, 1.48, 1.15)
var _mirada_base := Vector3(0.0, 0.90, 0.08)
var _intensidad_temblor: float = 0.0
var _angulo_actual: float = 0.0


func _process(delta: float) -> void:
	# Sacudida de cámara cuando el cocodrilo muerde o se abre el abismo
	if _intensidad_temblor > 0.001:
		_intensidad_temblor = move_toward(_intensidad_temblor, 0.0, delta * 2.2)
		var desvio := Vector3(
			(randf() * 2.0 - 1.0) * _intensidad_temblor,
			(randf() * 2.0 - 1.0) * _intensidad_temblor,
			(randf() * 2.0 - 1.0) * _intensidad_temblor
		)
		position = _posicion_base + desvio
		look_at(_mirada_base + desvio * 0.4, Vector3.UP)


## Mueve la cámara al ángulo del asiento del jugador en turno
func mover_a_angulo_asiento(angulo: float, animar: bool = true) -> void:
	_angulo_actual = angulo
	var direccion := Vector3(sin(angulo), 0.0, cos(angulo))

	var pos_destino: Vector3
	var mirada_destino: Vector3

	if modo_vista_cerca:
		pos_destino = direccion * 1.15 + Vector3(0.0, 1.48, 0.0)
		mirada_destino = Vector3(0.0, 0.90, 0.0) + direccion * 0.08
	else:
		pos_destino = direccion * 2.35 + Vector3(0.0, 2.05, 0.0)
		mirada_destino = Vector3(0.0, 0.88, 0.0)

	_posicion_base = pos_destino
	_mirada_base = mirada_destino

	if not animar:
		position = pos_destino
		look_at(mirada_destino, Vector3.UP)
		return

	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(_interpolar_vista, 0.0, 1.0, 0.52)


## Mueve la cámara a un plano cinemático enfocando la silla y el agujero del abismo del jugador eliminado
func enfocar_cinematica_eliminacion(angulo_asiento: float) -> void:
	var dir_asiento := Vector3(sin(angulo_asiento), 0.0, cos(angulo_asiento))
	var dir_lateral := Vector3(cos(angulo_asiento), 0.0, -sin(angulo_asiento))

	# Colocar la cámara en diagonal frente a la silla y la trampilla del jugador eliminado
	var pos_silla := dir_asiento * 1.82
	var pos_camara := dir_asiento * 0.55 + dir_lateral * 0.95 + Vector3(0.0, 1.38, 0.0)
	var punto_mirada := pos_silla + Vector3(0.0, 0.32, 0.0)

	_posicion_base = pos_camara
	_mirada_base = punto_mirada

	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(_interpolar_vista, 0.0, 1.0, 0.45)
	await tw.finished


## Alterna entre vista de cerca (Fauces) y vista de lejos (Mesa completa)
func alternar_distancia_vista() -> bool:
	modo_vista_cerca = not modo_vista_cerca
	mover_a_angulo_asiento(_angulo_actual, true)
	return modo_vista_cerca


## Activa la sacudida violenta de cámara al morder o abrirse la trampilla
func activar_sacudida_mordida(intensidad: float = 0.14) -> void:
	_intensidad_temblor = intensidad


func _interpolar_vista(peso: float) -> void:
	position = position.lerp(_posicion_base, peso)
	look_at(_mirada_base, Vector3.UP)
