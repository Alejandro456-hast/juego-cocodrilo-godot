class_name EfectosSonido
extends Node

## ============================================================================
## ARCHIVO: scripts/sonido/efectos_sonido.gd
## OBJETO EN ESCENA: "EfectosSonido" (dentro de escenas/principal.tscn)
##
## ¿QUÉ HACE ESTE SCRIPT?
## Genera y reproduce todos los sonidos del juego:
## - reproducir_apuntar(): Sonido suave al pasar el ratón sobre un botón.
## - reproducir_clic_boton(): Sonido mecánico al presionar un botón.
## - reproducir_latido(): Latido de corazón tenso antes de la mordida.
## - reproducir_mordida(): Golpe metálico cuando el cocodrilo corta la mano.
## - reproducir_caida_abismo(): Sonido de trampilla metálica abriéndose y caída
##   del jugador eliminado hacia el abismo profundo.
## - reproducir_resortes_botones(): Sonido de resortes al reactivarse +4 botones.
## ============================================================================

var _reproductores: Array[AudioStreamPlayer] = []
const FRECUENCIA_MUESTREO := 22050


func _ready() -> void:
	for i in range(6):
		var rep := AudioStreamPlayer.new()
		rep.volume_db = -4.0
		add_child(rep)
		_reproductores.append(rep)


func _obtener_reproductor_libre() -> AudioStreamPlayer:
	for rep in _reproductores:
		if not rep.playing:
			return rep
	return _reproductores[0]


func reproducir_apuntar() -> void:
	var muestras := int(0.035 * FRECUENCIA_MUESTREO)
	var datos := PackedByteArray()
	datos.resize(muestras * 2)
	for i in range(muestras):
		var t := float(i) / float(FRECUENCIA_MUESTREO)
		var env := exp(-t * 90.0)
		var val := clampf(sin(TAU * 920.0 * t) * env * 0.25, -1.0, 1.0)
		datos.encode_s16(i * 2, int(val * 32767.0))
	_reproducir_pcm(datos, -10.0)


func reproducir_clic_boton(nivel_peligro: float = 0.0) -> void:
	var frec_base := 260.0 + nivel_peligro * 220.0
	var muestras := int(0.14 * FRECUENCIA_MUESTREO)
	var datos := PackedByteArray()
	datos.resize(muestras * 2)
	for i in range(muestras):
		var t := float(i) / float(FRECUENCIA_MUESTREO)
		var env := exp(-t * 32.0)
		var chasquido := (randf() * 2.0 - 1.0) * exp(-t * 140.0) * 0.7
		var tono := sin(TAU * frec_base * t) * 0.5 + sin(TAU * (frec_base * 0.5) * t) * 0.4
		var val := clampf((chasquido + tono) * env, -1.0, 1.0)
		datos.encode_s16(i * 2, int(val * 32767.0))
	_reproducir_pcm(datos, -3.0)


func reproducir_mordida() -> void:
	var muestras := int(0.65 * FRECUENCIA_MUESTREO)
	var datos := PackedByteArray()
	datos.resize(muestras * 2)
	for i in range(muestras):
		var t := float(i) / float(FRECUENCIA_MUESTREO)
		var impacto := exp(-t * 14.0)
		var crujido := (randf() * 2.0 - 1.0) * exp(-t * 9.0) * 0.85
		var metal := sin(TAU * (110.0 - t * 60.0) * t) * impacto * 0.9
		var grave := sin(TAU * 48.0 * t) * exp(-t * 6.0) * 0.9
		var segundo_golpe := 0.0
		if t > 0.06 and t < 0.25:
			var t2 := t - 0.06
			segundo_golpe = (randf() * 2.0 - 1.0) * exp(-t2 * 22.0) * 0.7
		var val := clampf(crujido + metal + grave + segundo_golpe, -1.0, 1.0)
		datos.encode_s16(i * 2, int(val * 32767.0))
	_reproducir_pcm(datos, 2.0)


func reproducir_caida_abismo() -> void:
	# Sonido cinemático de 1.7 segundos: cerrojo de trampilla + caída al vacío + golpe final
	var duracion := 1.7
	var muestras := int(duracion * FRECUENCIA_MUESTREO)
	var datos := PackedByteArray()
	datos.resize(muestras * 2)
	for i in range(muestras):
		var t := float(i) / float(FRECUENCIA_MUESTREO)
		# 1. Cerrojo pesado de hierro al abrirse la trampilla (0.0 a 0.25s)
		var cerrojo := (randf() * 2.0 - 1.0) * exp(-t * 18.0) * 0.8 + sin(TAU * 95.0 * t) * exp(-t * 12.0) * 0.7
		# 2. Silbido/grito descendente cayendo al abismo (0.20 a 1.35s)
		var caida := 0.0
		if t > 0.18 and t < 1.38:
			var tc := t - 0.18
			var frec_caida := maxf(45.0, 420.0 - tc * 310.0)
			var env_caida := sin(clampf(tc / 1.2, 0.0, 1.0) * PI)
			var viento := (randf() * 2.0 - 1.0) * 0.35 * env_caida
			caida = (sin(TAU * frec_caida * tc) * 0.55 + viento) * env_caida
		# 3. Cierre pesado de las puertas de la trampilla (1.35 a 1.70s)
		var cierre := 0.0
		if t >= 1.35:
			var tf := t - 1.35
			cierre = (sin(TAU * 58.0 * tf) * 0.85 + (randf() * 2.0 - 1.0) * 0.6) * exp(-tf * 16.0)
		var val := clampf(cerrojo + caida + cierre, -1.0, 1.0)
		datos.encode_s16(i * 2, int(val * 32767.0))
	_reproducir_pcm(datos, 2.5)


func reproducir_resortes_botones() -> void:
	var muestras := int(0.38 * FRECUENCIA_MUESTREO)
	var datos := PackedByteArray()
	datos.resize(muestras * 2)
	for i in range(muestras):
		var t := float(i) / float(FRECUENCIA_MUESTREO)
		var paso := int(t * 14.0)
		var frec := 180.0 + float(paso % 5) * 65.0
		var t_local := fmod(t, 1.0 / 14.0)
		var env := exp(-t_local * 45.0)
		var resorte := sin(TAU * frec * t) * env * 0.6
		var ruido := (randf() * 2.0 - 1.0) * env * 0.35
		var val := clampf(resorte + ruido, -1.0, 1.0)
		datos.encode_s16(i * 2, int(val * 32767.0))
	_reproducir_pcm(datos, -2.0)


func reproducir_latido() -> void:
	var muestras := int(0.32 * FRECUENCIA_MUESTREO)
	var datos := PackedByteArray()
	datos.resize(muestras * 2)
	for i in range(muestras):
		var t := float(i) / float(FRECUENCIA_MUESTREO)
		var pulso1 := exp(-pow((t - 0.05) * 35.0, 2.0)) * sin(TAU * 52.0 * t)
		var pulso2 := exp(-pow((t - 0.19) * 38.0, 2.0)) * sin(TAU * 44.0 * t) * 0.75
		var val := clampf((pulso1 + pulso2) * 0.9, -1.0, 1.0)
		datos.encode_s16(i * 2, int(val * 32767.0))
	_reproducir_pcm(datos, -1.0)


func _reproducir_pcm(datos: PackedByteArray, volumen_db: float) -> void:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = FRECUENCIA_MUESTREO
	wav.stereo = false
	wav.data = datos

	var rep := _obtener_reproductor_libre()
	rep.volume_db = volumen_db
	rep.stream = wav
	rep.play()
