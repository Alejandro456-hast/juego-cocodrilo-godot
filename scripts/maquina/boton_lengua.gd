class_name BotonLengua
extends Node3D

## ============================================================================
## ARCHIVO: scripts/maquina/boton_lengua.gd
## ESCENA ASIGNADA: escenas/maquina/boton_lengua.tscn
##
## ¿QUÉ HACE ESTE SCRIPT?
## Controla uno de los 20 botones incrustados en la lengua del cocodrilo:
## 1. Detecta cuando el jugador apunta con el ratón o hace clic sobre el botón.
## 2. Anima el objeto "EmboloMovil" bajando cuando se presiona.
## 3. Cambia el color del botón (rojo normal, amarillo al apuntar, gris hundido
##    y verde cuando se reactiva tras una mordida).
## ============================================================================

signal boton_presionado(indice_boton: int)
signal boton_apuntado(indice_boton: int, esta_apuntado: bool)

@export var indice_boton: int = 0

var esta_hundido: bool = false
var es_interactivo: bool = false
var _raton_encima: bool = false

@onready var _embolo_movil: Node3D = $EmboloMovil
@onready var _tapa_boton: MeshInstance3D = $EmboloMovil/TapaBoton
@onready var _numero_boton: Label3D = $EmboloMovil/NumeroBoton
@onready var _area_clic: Area3D = $AreaClic

var _material_tapa: StandardMaterial3D
const _ALTURA_BASE: float = 0.028

const COLOR_ACTIVO := Color(0.55, 0.14, 0.12)
const COLOR_APUNTADO := Color(0.95, 0.72, 0.18)
const COLOR_DUDA_IA := Color(0.95, 0.42, 0.10)
const COLOR_HUNDIDO := Color(0.14, 0.13, 0.13)
const COLOR_REACTIVADO := Color(0.25, 0.75, 0.35)


func _ready() -> void:
	_material_tapa = StandardMaterial3D.new()
	_material_tapa.albedo_color = COLOR_ACTIVO
	_material_tapa.roughness = 0.38
	_material_tapa.metallic = 0.35
	_material_tapa.emission_enabled = true
	_material_tapa.emission = Color(0.25, 0.03, 0.02)
	_material_tapa.emission_energy_multiplier = 0.7
	if _tapa_boton:
		_tapa_boton.material_override = _material_tapa

	if _numero_boton:
		_numero_boton.text = str(indice_boton + 1)

	if _area_clic:
		_area_clic.mouse_entered.connect(_al_entrar_raton)
		_area_clic.mouse_exited.connect(_al_salir_raton)
		_area_clic.input_event.connect(_al_evento_raton)

	cambiar_estado_hundido(false, false)


func configurar(idx: int) -> void:
	indice_boton = idx
	if _numero_boton:
		_numero_boton.text = str(indice_boton + 1)


func cambiar_estado_hundido(hundido: bool, animar: bool = true, destello_reactivado: bool = false) -> void:
	esta_hundido = hundido
	if hundido:
		_raton_encima = false

	var destino_y := 0.010 if hundido else _ALTURA_BASE
	if _embolo_movil:
		if animar and is_inside_tree():
			var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tw.tween_property(_embolo_movil, "position:y", destino_y, 0.16)
		else:
			_embolo_movil.position.y = destino_y

	_actualizar_color_visual(destello_reactivado)


func resaltar_duda_ia(activo: bool) -> void:
	if esta_hundido or not _material_tapa:
		return
	if activo:
		_material_tapa.albedo_color = COLOR_DUDA_IA
		_material_tapa.emission = COLOR_DUDA_IA
		_material_tapa.emission_energy_multiplier = 1.6
	else:
		_actualizar_color_visual(false)


func _actualizar_color_visual(destello_reactivado: bool = false) -> void:
	if not _material_tapa or not _numero_boton:
		return
	if esta_hundido:
		_material_tapa.albedo_color = COLOR_HUNDIDO
		_material_tapa.emission = Color(0.03, 0.01, 0.01)
		_material_tapa.emission_energy_multiplier = 0.15
		_numero_boton.modulate = Color(0.42, 0.38, 0.38)
	elif destello_reactivado:
		_material_tapa.albedo_color = COLOR_REACTIVADO
		_material_tapa.emission = COLOR_REACTIVADO
		_material_tapa.emission_energy_multiplier = 2.0
		_numero_boton.modulate = Color(1.0, 1.0, 0.9)
		if is_inside_tree():
			var tw := create_tween()
			tw.tween_interval(0.55)
			tw.tween_callback(_fin_destello_reactivado)
	elif _raton_encima and es_interactivo:
		_material_tapa.albedo_color = COLOR_APUNTADO
		_material_tapa.emission = COLOR_APUNTADO
		_material_tapa.emission_energy_multiplier = 1.8
		_numero_boton.modulate = Color(1.0, 1.0, 0.95)
	else:
		_material_tapa.albedo_color = COLOR_ACTIVO
		_material_tapa.emission = Color(0.32, 0.04, 0.02)
		_material_tapa.emission_energy_multiplier = 0.75
		_numero_boton.modulate = Color(0.95, 0.88, 0.78)


func _fin_destello_reactivado() -> void:
	_actualizar_color_visual(false)


func _al_entrar_raton() -> void:
	if esta_hundido or not es_interactivo:
		return
	_raton_encima = true
	_actualizar_color_visual(false)
	boton_apuntado.emit(indice_boton, true)


func _al_salir_raton() -> void:
	if not _raton_encima:
		return
	_raton_encima = false
	_actualizar_color_visual(false)
	boton_apuntado.emit(indice_boton, false)


func _al_evento_raton(_camara: Node, evento: InputEvent, _pos: Vector3, _normal: Vector3, _idx: int) -> void:
	if esta_hundido or not es_interactivo:
		return
	if evento is InputEventMouseButton and evento.button_index == MOUSE_BUTTON_LEFT and evento.pressed:
		boton_presionado.emit(indice_boton)
