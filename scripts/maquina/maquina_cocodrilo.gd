class_name MaquinaCocodrilo
extends Node3D

## ============================================================================
## ARCHIVO: scripts/maquina/maquina_cocodrilo.gd
## ESCENA ASIGNADA: escenas/maquina/maquina_cocodrilo.tscn (Nodo Raíz: MaquinaCocodrilo)
##
## ¿QUÉ HACE ESTE SCRIPT?
## Coordina la cabeza del cocodrilo y sus componentes hijos:
## - "MandibulaSuperior" (mandibula_superior.gd): Tiembla, brilla sus ojos y cierra de golpe.
## - "BotonesLengua" (boton_lengua.gd): Los 20 botones numerados en la lengua.
## - "ParticulasSangre" y "ManoCortada": Efectos visuales que saltan al morder.
## ============================================================================

signal boton_lengua_seleccionado(indice_boton: int)
signal boton_lengua_apuntado(indice_boton: int, esta_apuntado: bool)

const TOTAL_BOTONES := 20

var botones: Array[BotonLengua] = []

@onready var _mandibula_superior: MandibulaSuperior = $MandibulaSuperior
@onready var _raiz_botones: Node3D = $MandibulaInferior/BotonesLengua
@onready var _luz_boca: OmniLight3D = $LuzBoca
@onready var _particulas_sangre: CPUParticles3D = $ParticulasSangre
@onready var _mano_cortada: Node3D = $ManoCortada


func _ready() -> void:
	botones.clear()
	if _raiz_botones:
		var idx := 0
		for hijo in _raiz_botones.get_children():
			if hijo is BotonLengua:
				var btn := hijo as BotonLengua
				btn.configurar(idx)
				btn.boton_presionado.connect(_reenviar_boton_presionado)
				btn.boton_apuntado.connect(_reenviar_boton_apuntado)
				botones.append(btn)
				idx += 1


func activar_interaccion_botones(interactivo: bool) -> void:
	for btn in botones:
		btn.es_interactivo = interactivo
		btn._actualizar_color_visual(false)


func ajustar_tension(proporcion: float) -> void:
	var nivel := clampf(proporcion, 0.0, 1.0)
	if _mandibula_superior:
		_mandibula_superior.ajustar_tension(nivel)
	if _luz_boca:
		_luz_boca.light_energy = 0.8 + nivel * 1.4


func reiniciar_todos_los_botones() -> void:
	for btn in botones:
		btn.cambiar_estado_hundido(false, true, false)
	if _mano_cortada:
		_mano_cortada.visible = false
	ajustar_tension(0.0)


func obtener_posicion_global_boton(idx: int) -> Vector3:
	if idx >= 0 and idx < botones.size():
		return botones[idx].global_position + Vector3(0.0, 0.04, 0.0)
	return global_position + Vector3(0.0, 0.15, 0.1)


func animar_mordida() -> void:
	if _mandibula_superior:
		await _mandibula_superior.animar_cierre_mordida(_al_impactar_mordida)


func _al_impactar_mordida() -> void:
	if _particulas_sangre:
		_particulas_sangre.restart()
		_particulas_sangre.emitting = true
	if _mano_cortada:
		_mano_cortada.visible = true


func animar_reapertura() -> void:
	if _mandibula_superior:
		await _mandibula_superior.animar_reapertura()


func _reenviar_boton_presionado(b_idx: int) -> void:
	boton_lengua_seleccionado.emit(b_idx)


func _reenviar_boton_apuntado(b_idx: int, apuntado: bool) -> void:
	boton_lengua_apuntado.emit(b_idx, apuntado)
