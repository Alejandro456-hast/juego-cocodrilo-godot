class_name GestorJuego
extends Node3D

## ============================================================================
## ARCHIVO: scripts/nucleo/gestor_juego.gd
## OBJETO EN ESCENA: "Principal" (nodo raíz de escenas/principal.tscn)
##
## ¿QUÉ HACE ESTE SCRIPT?
## Es el Árbitro / Director de la partida:
## 1. Lleva el orden de los turnos entre los 5 jugadores sentados en la mesa.
## 2. Gira el objeto "PlatoGiratorio" hacia el jugador al que le toca jugar.
## 3. Verifica si el botón presionado en la lengua es seguro o es la trampa.
## 4. Si es la trampa: ordena al cocodrilo morder, le corta 1 mano al jugador
##    y REACTIVA +4 BOTONES ya hundidos para que los demás continúen hasta
##    que solo quede 1 sobreviviente.
## ============================================================================

enum EstadoPartida {
	MENU_CONFIGURACION,
	CAMBIO_DE_TURNO,
	ESPERANDO_HUMANO,
	PENSANDO_IA,
	RESOLVIENDO_BOTON,
	FIN_PARTIDA,
}

const NUM_JUGADORES := 5
const TOTAL_BOTONES := 20
const BOTONES_REACTIVADOS_AL_MORDER := 4

var estado: EstadoPartida = EstadoPartida.MENU_CONFIGURACION
var jugadores: Array[AsientoJugador] = []
var asientos_ia: Array[bool] = [false, true, true, true, true]

var asiento_turno_actual: int = 0
var botones_hundidos: Array[bool] = []
var _indice_boton_trampa: int = -1

@onready var _plato_giratorio: PlatoGiratorio = $Mesa/PlatoGiratorio
@onready var _cocodrilo: MaquinaCocodrilo = $Mesa/PlatoGiratorio/MaquinaCocodrilo
@onready var _raiz_jugadores: Node3D = $Jugadores
@onready var _camara: ControladorCamara = $CamaraPrincipal
@onready var _sonidos: EfectosSonido = $EfectosSonido
@onready var _ia: ControladorIA = $ControladorIA
@onready var _interfaz: GestorInterfaz = $InterfazJuego


func _ready() -> void:
	randomize()
	botones_hundidos.resize(TOTAL_BOTONES)
	for i in range(TOTAL_BOTONES):
		botones_hundidos[i] = false

	jugadores.clear()
	if _raiz_jugadores:
		var idx := 0
		for hijo in _raiz_jugadores.get_children():
			if hijo is AsientoJugador:
				var asiento := hijo as AsientoJugador
				asiento.configurar(idx, asiento.nombre_jugador, asiento.es_ia)
				if idx < asientos_ia.size():
					asientos_ia[idx] = asiento.es_ia
				jugadores.append(asiento)
				idx += 1

	if _cocodrilo:
		_cocodrilo.boton_lengua_seleccionado.connect(_al_seleccionar_boton_lengua)
		_cocodrilo.boton_lengua_apuntado.connect(_al_apuntar_boton_lengua)

	if _interfaz:
		_interfaz.solicitar_iniciar_partida.connect(_al_solicitar_iniciar_partida)
		_interfaz.solicitar_cambio_camara.connect(_al_solicitar_cambio_camara)
		_interfaz.boton_teclado_seleccionado.connect(_al_seleccionar_boton_lengua)
		_interfaz.boton_teclado_apuntado.connect(_al_apuntar_teclado_interfaz)
		_interfaz.mostrar_menu_configuracion()

	if _camara:
		_camara.mover_a_angulo_asiento(_obtener_angulo_asiento(0), false)


func iniciar_nueva_partida() -> void:
	if _interfaz:
		_interfaz.mostrar_hud_partida()

	for i in range(jugadores.size()):
		var nombre_defecto := ("Jugador %d" % (i + 1)) if not asientos_ia[i] else ("Sujeto IA %d" % (i + 1))
		jugadores[i].reiniciar_para_nueva_partida(asientos_ia[i], nombre_defecto)

	for b_i in range(TOTAL_BOTONES):
		botones_hundidos[b_i] = false
	_cocodrilo.reiniciar_todos_los_botones()
	_elegir_nuevo_boton_trampa()
	_actualizar_hud(jugadores[0])

	asiento_turno_actual = 0
	_iniciar_turno(asiento_turno_actual)


func _iniciar_turno(idx_asiento: int) -> void:
	var vivos := _obtener_jugadores_vivos()
	if vivos.size() <= 1:
		_terminar_partida(vivos[0] if vivos.size() == 1 else null)
		return

	estado = EstadoPartida.CAMBIO_DE_TURNO
	_cocodrilo.activar_interaccion_botones(false)

	for i in range(jugadores.size()):
		jugadores[i].marcar_turno_activo(i == idx_asiento)

	var jugador_actual := jugadores[idx_asiento]
	var activos_cnt := _obtener_indices_botones_activos().size()
	var tension := 1.0 - (float(activos_cnt) / float(TOTAL_BOTONES))
	_cocodrilo.ajustar_tension(tension)

	_actualizar_hud(jugador_actual)
	if _camara:
		_camara.mover_a_angulo_asiento(_obtener_angulo_asiento(idx_asiento), true)
	await _girar_cocodrilo_hacia_asiento(idx_asiento, true)

	if jugador_actual.es_ia:
		estado = EstadoPartida.PENSANDO_IA
		_interfaz.escribir_narracion(_ia.crear_narracion_pensamiento(jugador_actual, activos_cnt))
		await get_tree().create_timer(0.55).timeout
		var elegido := await _ia.elegir_boton_con_suspenso(
			jugador_actual,
			_obtener_indices_botones_activos(),
			_cocodrilo,
			_sonidos
		)
		await _ejecutar_presion_boton(jugador_actual, elegido)
	else:
		estado = EstadoPartida.ESPERANDO_HUMANO
		_cocodrilo.activar_interaccion_botones(true)
		_actualizar_hud(jugador_actual)
		var aviso_manos := "¡CUIDADO! Solo te queda 1 mano sana." if jugador_actual.manos_restantes == 1 else "Tienes tus 2 manos."
		_interfaz.escribir_narracion("Turno de %s: Haz clic en uno de los %d botones activos en la lengua del cocodrilo. (%s)" % [
			jugador_actual.nombre_jugador,
			activos_cnt,
			aviso_manos
		])


func _ejecutar_presion_boton(jugador: AsientoJugador, indice_boton: int) -> void:
	estado = EstadoPartida.RESOLVIENDO_BOTON
	_cocodrilo.activar_interaccion_botones(false)
	_actualizar_hud(jugador)

	_interfaz.escribir_narracion("%s introduce la mano en las fauces y presiona el Botón #%02d..." % [
		jugador.nombre_jugador,
		indice_boton + 1
	])

	var pos_mundo_boton := _cocodrilo.obtener_posicion_global_boton(indice_boton)
	await jugador.animar_mano_hacia_boton(pos_mundo_boton)

	botones_hundidos[indice_boton] = true
	_cocodrilo.botones[indice_boton].cambiar_estado_hundido(true, true, false)

	var restantes := _obtener_indices_botones_activos().size()
	var peligro := 1.0 - (float(restantes) / float(TOTAL_BOTONES))
	_sonidos.reproducir_clic_boton(peligro)

	await get_tree().create_timer(0.28).timeout

	if indice_boton == _indice_boton_trampa:
		_sonidos.reproducir_latido()
		await get_tree().create_timer(0.18).timeout

		_sonidos.reproducir_mordida()
		_interfaz.activar_destello_sangre()
		if _camara:
			_camara.activar_sacudida_mordida(0.14)

		await _cocodrilo.animar_mordida()
		await jugador.amputar_mano_actual()

		if jugador.manos_restantes == 1:
			_interfaz.escribir_narracion("¡¡CRAAAACK!! ¡El cocodrilo le arrancó una mano a %s! Le queda 1 última mano..." % jugador.nombre_jugador)
			_actualizar_hud(jugador)
			await get_tree().create_timer(1.25).timeout
		else:
			_interfaz.escribir_narracion("¡¡ELIMINADO!! ¡%s perdió su segunda mano! ¡Se abre la trampilla hacia el abismo!" % jugador.nombre_jugador)
			_actualizar_hud(jugador)
			await get_tree().create_timer(0.55).timeout

			# Cinemática de eliminación: enfocar la silla del jugador y abrir la trampilla al abismo
			var angulo_elim := _obtener_angulo_asiento(jugador.indice_asiento)
			if _camara:
				await _camara.enfocar_cinematica_eliminacion(angulo_elim)
				_camara.activar_sacudida_mordida(0.07)

			_sonidos.reproducir_caida_abismo()
			await jugador.ejecutar_cinematica_caida_abismo()
			await get_tree().create_timer(0.55).timeout

		var vivos_tras_mordida := _obtener_jugadores_vivos()
		if vivos_tras_mordida.size() <= 1:
			await _cocodrilo.animar_reapertura()
			_terminar_partida(vivos_tras_mordida[0] if vivos_tras_mordida.size() == 1 else null)
			return

		await _cocodrilo.animar_reapertura()
		var reactivados := _reactivar_cuatro_botones_tras_mordida()
		_sonidos.reproducir_resortes_botones()

		var texto_numeros := ""
		for r_idx in reactivados:
			if texto_numeros != "":
				texto_numeros += ", "
			texto_numeros += "#%02d" % (r_idx + 1)

		_interfaz.escribir_narracion("¡Los resortes internos saltan! Se reactivaron %d botones en la lengua (%s) y la trampa cambió de lugar." % [
			reactivados.size(),
			texto_numeros
		])
		_actualizar_hud(jugador)
		await get_tree().create_timer(1.35).timeout
	else:
		await jugador.animar_retirar_mano_sana()
		_interfaz.escribir_narracion("¡CLIC! El Botón #%02d era seguro. %s retira su mano intacta." % [
			indice_boton + 1,
			jugador.nombre_jugador
		])
		_actualizar_hud(jugador)
		await get_tree().create_timer(0.55).timeout

	_avanzar_al_siguiente_jugador_vivo()


func _reactivar_cuatro_botones_tras_mordida() -> Array[int]:
	var candidatos := _obtener_indices_botones_hundidos()
	candidatos.shuffle()

	var cantidad_subir := mini(BOTONES_REACTIVADOS_AL_MORDER, candidatos.size())
	var activos_ahora := _obtener_indices_botones_activos().size()
	if activos_ahora + cantidad_subir < 5:
		cantidad_subir = mini(candidatos.size(), 5 - activos_ahora)

	var reactivados: Array[int] = []
	for i in range(cantidad_subir):
		var b_idx: int = candidatos[i]
		botones_hundidos[b_idx] = false
		_cocodrilo.botones[b_idx].cambiar_estado_hundido(false, true, true)
		reactivados.append(b_idx)

	reactivados.sort()
	_elegir_nuevo_boton_trampa()
	return reactivados


func _avanzar_al_siguiente_jugador_vivo() -> void:
	var vivos := _obtener_jugadores_vivos()
	if vivos.size() <= 1:
		_terminar_partida(vivos[0] if vivos.size() == 1 else null)
		return

	for paso in range(1, jugadores.size() + 1):
		var siguiente := (asiento_turno_actual + paso) % jugadores.size()
		if jugadores[siguiente].esta_vivo():
			asiento_turno_actual = siguiente
			_iniciar_turno(asiento_turno_actual)
			return


func _terminar_partida(ganador: AsientoJugador) -> void:
	estado = EstadoPartida.FIN_PARTIDA
	_cocodrilo.activar_interaccion_botones(false)
	if _interfaz:
		_interfaz.sincronizar_teclado(botones_hundidos, false)
		_interfaz.mostrar_fin_juego(ganador)


func _obtener_angulo_asiento(idx_asiento: int) -> float:
	if idx_asiento >= 0 and idx_asiento < jugadores.size():
		var pos_j := jugadores[idx_asiento].position
		return atan2(pos_j.x, pos_j.z)
	return float(idx_asiento) * (TAU / float(NUM_JUGADORES))


func _girar_cocodrilo_hacia_asiento(idx_asiento: int, animar: bool = true) -> void:
	var angulo_destino := _obtener_angulo_asiento(idx_asiento)
	if _plato_giratorio:
		await _plato_giratorio.girar_hacia_angulo(angulo_destino, animar)


func _elegir_nuevo_boton_trampa() -> void:
	var activos := _obtener_indices_botones_activos()
	if activos.is_empty():
		_indice_boton_trampa = 0
	else:
		_indice_boton_trampa = activos[randi() % activos.size()]


func _obtener_indices_botones_activos() -> Array[int]:
	var lista: Array[int] = []
	for i in range(TOTAL_BOTONES):
		if not botones_hundidos[i]:
			lista.append(i)
	return lista


func _obtener_indices_botones_hundidos() -> Array[int]:
	var lista: Array[int] = []
	for i in range(TOTAL_BOTONES):
		if botones_hundidos[i]:
			lista.append(i)
	return lista


func _obtener_jugadores_vivos() -> Array[AsientoJugador]:
	var lista: Array[AsientoJugador] = []
	for j in jugadores:
		if j.esta_vivo():
			lista.append(j)
	return lista


func _actualizar_hud(jugador_activo: AsientoJugador) -> void:
	if not _interfaz:
		return
	_interfaz.actualizar_estado_hud(
		jugador_activo,
		_obtener_indices_botones_activos().size(),
		TOTAL_BOTONES,
		_obtener_jugadores_vivos().size(),
		jugadores.size()
	)
	_interfaz.sincronizar_teclado(botones_hundidos, estado == EstadoPartida.ESPERANDO_HUMANO)


func _al_apuntar_boton_lengua(indice_boton: int, esta_apuntado: bool) -> void:
	if estado != EstadoPartida.ESPERANDO_HUMANO:
		return
	if esta_apuntado:
		_sonidos.reproducir_apuntar()
		_interfaz.escribir_narracion("Apuntando al Botón #%02d en la lengua... Haz clic izquierdo para presionarlo." % (indice_boton + 1))


func _al_seleccionar_boton_lengua(indice_boton: int) -> void:
	if estado != EstadoPartida.ESPERANDO_HUMANO:
		return
	if indice_boton < 0 or indice_boton >= TOTAL_BOTONES or botones_hundidos[indice_boton]:
		return

	var jugador_actual := jugadores[asiento_turno_actual]
	await _ejecutar_presion_boton(jugador_actual, indice_boton)


func _al_solicitar_iniciar_partida(configuracion_ia: Array[bool]) -> void:
	asientos_ia = configuracion_ia.duplicate()
	iniciar_nueva_partida()


func _al_solicitar_cambio_camara() -> void:
	if _camara:
		var es_cerca := _camara.alternar_distancia_vista()
		if _interfaz:
			_interfaz.actualizar_texto_boton_camara(es_cerca)


func _al_apuntar_teclado_interfaz(btn_idx: int, apuntado: bool) -> void:
	if btn_idx < 0 or btn_idx >= _cocodrilo.botones.size():
		return
	if apuntado and estado == EstadoPartida.ESPERANDO_HUMANO and not botones_hundidos[btn_idx]:
		_cocodrilo.botones[btn_idx]._al_entrar_raton()
	else:
		_cocodrilo.botones[btn_idx]._al_salir_raton()
