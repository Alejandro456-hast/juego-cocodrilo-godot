class_name TrampillaAbismo
extends Node3D

## ============================================================================
## ARCHIVO: scripts/jugador/trampilla_abismo.gd
## NODO ASIGNADO: TrampillaAbismo (dentro de escenas/jugador/asiento_jugador.tscn)
##
## ¿QUÉ HACE ESTE SCRIPT?
## Controla de manera especializada e independiente la trampilla secreta del piso:
## 1. Abrir de golpe las 2 compuertas de hierro hacia abajo.
## 2. Encender la luz roja siniestra del fondo del abismo y mostrar el agujero.
## 3. Hacer caer al jugador y su silla a plomo hacia la oscuridad.
## 4. Volver a cerrar las compuertas de hierro con rebote metálico.
##
## BENEFICIO DE TENER ESTE SCRIPT SEPARADO:
## Si en el futuro quieres cambiar la velocidad de la trampilla, agregar humo,
## cambiar el ángulo de apertura o ponerle un sonido propio a las bisagras,
## lo haces AQUÍ DIRECTAMENTE sin riesgo de romper el código del jugador ni sus turnos.
## ============================================================================

@onready var agujero_abismo: MeshInstance3D = $AgujeroAbismo
@onready var luz_abismo: OmniLight3D = $LuzAbismo
@onready var puerta_izq: Node3D = $PuertaTrampillaIzq
@onready var puerta_der: Node3D = $PuertaTrampillaDer


func _ready() -> void:
	reiniciar_trampilla()


## Restablece la trampilla a su estado inicial cerrado y oculto
func reiniciar_trampilla() -> void:
	if puerta_izq:
		puerta_izq.rotation_degrees = Vector3.ZERO
	if puerta_der:
		puerta_der.rotation_degrees = Vector3.ZERO
	if agujero_abismo:
		agujero_abismo.visible = false
	if luz_abismo:
		luz_abismo.visible = false


## Ejecuta la cinemática física y visual de la trampilla tragándose los elementos al abismo
func tragar_al_abismo(elementos_a_tirar: Array[Node3D], distancia_caida: float = -3.8) -> void:
	# 1. Revelar el pozo profundo y la luz roja siniestra
	if agujero_abismo:
		agujero_abismo.visible = true
	if luz_abismo:
		luz_abismo.visible = true

	# 2. Abrir de golpe las dos compuertas de hierro hacia abajo (efecto resorte violento)
	var tw_abrir := create_tween().set_parallel(true)
	if puerta_izq:
		tw_abrir.tween_property(puerta_izq, "rotation_degrees:z", 84.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if puerta_der:
		tw_abrir.tween_property(puerta_der, "rotation_degrees:z", -84.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw_abrir.finished

	# 3. Animar la caída acelerada de los elementos (torso, silla, manos)
	var tw_caida := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	for nodo in elementos_a_tirar:
		if is_instance_valid(nodo) and nodo != null:
			tw_caida.tween_property(nodo, "position:y", nodo.position.y + distancia_caida, 0.82)
			# Si es el torso o la silla, darles una inclinación dramática hacia atrás mientras caen
			if nodo.name == "Torso":
				tw_caida.tween_property(nodo, "rotation_degrees:x", -48.0, 0.82)
			elif "Silla" in nodo.name:
				tw_caida.tween_property(nodo, "rotation_degrees:x", -35.0, 0.82)
	await tw_caida.finished

	# 4. Una vez en el fondo del abismo, ocultar los objetos caídos
	for nodo in elementos_a_tirar:
		if is_instance_valid(nodo) and nodo != null:
			nodo.visible = false

	# 5. Cerrar de golpe las compuertas de hierro con rebote metálico pesado
	var tw_cerrar := create_tween().set_parallel(true).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	if puerta_izq:
		tw_cerrar.tween_property(puerta_izq, "rotation_degrees:z", 0.0, 0.32)
	if puerta_der:
		tw_cerrar.tween_property(puerta_der, "rotation_degrees:z", 0.0, 0.32)
	await tw_cerrar.finished

	# 6. Apagar el resplandor y ocultar el agujero
	if luz_abismo:
		luz_abismo.visible = false
	if agujero_abismo:
		agujero_abismo.visible = false
