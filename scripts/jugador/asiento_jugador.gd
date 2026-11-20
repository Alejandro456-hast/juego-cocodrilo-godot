class_name AsientoJugador
extends Node3D

## ============================================================================
## ARCHIVO: scripts/jugador/asiento_jugador.gd
## ESCENA ASIGNADA: escenas/jugador/asiento_jugador.tscn (Nodo Raíz: AsientoJugador)
##
## ¿QUÉ HACE ESTE SCRIPT?
## Es únicamente el Coordinador general de cada jugador sentado en la mesa.
## Ya no tiene el código mezclado de las manos, del torso ni de la trampilla,
## sino que le ordena a cada Nodo Hijo ejecutar su propia tarea:
## - "Torso" (cuerpo_jugador.gd): Respira y viste el color del traje.
## - "ManoDerecha" y "ManoIzquierda" (mano_jugador.gd): Se estiran, tiemblan y se amputan.
## - "TrampillaAbismo" (trampilla_abismo.gd): Abre las compuertas y traga al jugador.
## - "CartelEstado" (cartel_estado.gd): Actualiza el texto flotante sobre la cabeza.
## ============================================================================

@export var indice_asiento: int = 0
@export var nombre_jugador: String = "Jugador 1"
@export var es_ia: bool = false

var manos_restantes: int = 2
var es_turno_actual: bool = false

@onready var _trampilla_abismo: TrampillaAbismo = $TrampillaAbismo
@onready var _asiento_silla: MeshInstance3D = $AsientoSilla
@onready var _respaldo_silla: MeshInstance3D = $RespaldoSilla
@onready var _torso: CuerpoJugador = $Torso
@onready var _mano_derecha: ManoJugador = $ManoDerecha
@onready var _mano_izquierda: ManoJugador = $ManoIzquierda
@onready var _cartel_estado: CartelEstadoJugador = $CartelEstado

var _pos_inicial_asiento_silla := Vector3(0.0, 0.46, 0.08)
var _pos_inicial_respaldo_silla := Vector3(0.0, 0.82, 0.29)


func _ready() -> void:
	if _asiento_silla:
		_pos_inicial_asiento_silla = _asiento_silla.position
	if _respaldo_silla:
		_pos_inicial_respaldo_silla = _respaldo_silla.position

	var desfase := float(indice_asiento) * 1.37
	if _torso:
		_torso.aplicar_color_traje(indice_asiento, desfase)
	actualizar_estado_visual()


func configurar(idx: int, nombre: String, controlado_por_ia: bool) -> void:
	indice_asiento = idx
	nombre_jugador = nombre
	es_ia = controlado_por_ia
	manos_restantes = 2
	var desfase := float(idx) * 1.37
	if _torso:
		_torso.aplicar_color_traje(indice_asiento, desfase)
	actualizar_estado_visual()


func esta_vivo() -> bool:
	return manos_restantes > 0


func reiniciar_para_nueva_partida(controlado_por_ia: bool, nombre_personalizado: String = "") -> void:
	es_ia = controlado_por_ia
	if nombre_personalizado != "":
		nombre_jugador = nombre_personalizado
	manos_restantes = 2
	es_turno_actual = false

	if _asiento_silla:
		_asiento_silla.visible = true
		_asiento_silla.position = _pos_inicial_asiento_silla
		_asiento_silla.rotation_degrees = Vector3.ZERO
	if _respaldo_silla:
		_respaldo_silla.visible = true
		_respaldo_silla.position = _pos_inicial_respaldo_silla
		_respaldo_silla.rotation_degrees = Vector3.ZERO

	var desfase := float(indice_asiento) * 1.37
	if _torso:
		_torso.reiniciar_cuerpo()
	if _mano_derecha:
		_mano_derecha.reiniciar_mano(desfase)
	if _mano_izquierda:
		_mano_izquierda.reiniciar_mano(desfase)
	if _trampilla_abismo:
		_trampilla_abismo.reiniciar_trampilla()

	actualizar_estado_visual()


func marcar_turno_activo(activo: bool) -> void:
	es_turno_actual = activo
	actualizar_estado_visual()


func _obtener_mano_en_uso() -> ManoJugador:
	return _mano_derecha if manos_restantes == 2 else _mano_izquierda


func animar_mano_hacia_boton(pos_global_destino: Vector3) -> void:
	var mano := _obtener_mano_en_uso()
	if mano:
		await mano.estirar_hacia_boton(pos_global_destino)


func animar_retirar_mano_sana() -> void:
	var mano := _obtener_mano_en_uso()
	if mano:
		await mano.retirar_sana()


func amputar_mano_actual() -> void:
	var mano := _obtener_mano_en_uso()
	manos_restantes = maxi(0, manos_restantes - 1)
	if mano:
		await mano.amputar()
	actualizar_estado_visual()


## Delega en el nodo TrampillaAbismo la apertura y caída del jugador al vacío
func ejecutar_cinematica_caida_abismo() -> void:
	if _torso:
		_torso.detener_respiracion()
	if _mano_derecha:
		_mano_derecha.preparar_para_caida()
	if _mano_izquierda:
		_mano_izquierda.preparar_para_caida()

	var objetos_a_tirar: Array[Node3D] = [
		_torso,
		_asiento_silla,
		_respaldo_silla,
		_mano_derecha,
		_mano_izquierda
	]
	if _trampilla_abismo:
		await _trampilla_abismo.tragar_al_abismo(objetos_a_tirar)


func actualizar_estado_visual() -> void:
	if _torso:
		_torso.esta_herido = (manos_restantes == 1)
		if manos_restantes <= 0:
			_torso.detener_respiracion()

	if _mano_derecha:
		_mano_derecha.esta_amputada = (manos_restantes < 2)
		_mano_derecha.actualizar_mallas()

	if _mano_izquierda:
		_mano_izquierda.esta_amputada = (manos_restantes < 1)
		_mano_izquierda.configurar_temblor(manos_restantes == 1, es_turno_actual)
		_mano_izquierda.actualizar_mallas()

	if _cartel_estado:
		_cartel_estado.actualizar_cartel(nombre_jugador, es_ia, manos_restantes, es_turno_actual)
