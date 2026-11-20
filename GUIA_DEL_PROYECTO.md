# Guía de Estructura del Proyecto en Español: "La Fauce del Cocodrilo" (Godot 4)

Todos los archivos, carpetas, escenas, objetos (nodos) y scripts del proyecto están en **español**.

---

## 1. Estructura de Carpetas y Archivos

```text
res://
├── escenas/                             # ESCENAS VISUALES (.tscn)
│   ├── principal.tscn                   # Escena Principal (une cuarto, mesa, cocodrilo y jugadores)
│   ├── maquina/
│   │   ├── maquina_cocodrilo.tscn       # Cabeza del cocodrilo 3D con dientes y mandíbula
│   │   └── boton_lengua.tscn            # Un botón individual de la lengua
│   ├── jugador/
│   │   └── asiento_jugador.tscn         # Un jugador con su silla y sus 2 manos
│   └── interfaz/
│       └── interfaz_juego.tscn          # Menús en pantalla, textos y teclado de 20 botones
│
└── scripts/                             # CÓDIGO EN ESPAÑOL SEPARADO POR FUNCIÓN (.gd)
	├── nucleo/
	│   └── gestor_juego.gd              # Árbitro: turnos, regla de trampa y reactivar +4 botones
	├── ambiente/
	│   ├── luz_habitacion.gd            # Balanceo y parpadeo de la única lámpara del cuarto
	│   └── controlador_camara.gd        # Cámara que gira a cada asiento y tiembla al morder
	├── maquina/
	│   ├── maquina_cocodrilo.gd         # Animación de mandíbula, ojos rojos y sangre del cocodrilo
	│   └── boton_lengua.gd              # Lógica de cada uno de los 20 botones de la lengua
	├── jugador/
	│   ├── asiento_jugador.gd           # Animación de las 2 manos, temblor de miedo y amputación
	│   └── controlador_ia.gd            # Inteligencia Artificial y personalidades de los bots
	├── sonido/
	│   └── efectos_sonido.gd            # Sonidos de clic, latido, mordida y resortes
	└── interfaz/
		└── gestor_interfaz.gd           # Control de menús, carteles y textos en pantalla
```

---

## 2. Objetos dentro de `escenas/principal.tscn` (Panel "Escena")

* **`Principal`** *(usa `scripts/nucleo/gestor_juego.gd`)*
  * **`EntornoOscuro`**: Oscuridad y niebla del cuarto.
  * **`Habitacion`** *(usa `scripts/ambiente/luz_habitacion.gd`)*
	* **`Suelo`**: Piso del cuarto.
	* **`PivoteLampara`**: Contiene el **`Cable`**, **`PantallaLampara`**, **`Bombilla`** y **`FocoLuz`**.
	* **`LuzRelleno`**: Luz tenue secundaria.
  * **`Mesa`**
	* **`TableroMesa`** y **`PataMesa`**.
	* **`PlatoGiratorio`**: Contiene el **`DiscoMetalico`** y la **`MaquinaCocodrilo`**.
  * **`Jugadores`**
	* **`Jugador_1`**, **`Jugador_2`**, **`Jugador_3`**, **`Jugador_4`**, **`Jugador_5`**.
  * **`CamaraPrincipal`** *(usa `scripts/ambiente/controlador_camara.gd`)*
  * **`EfectosSonido`** *(usa `scripts/sonido/efectos_sonido.gd`)*
  * **`ControladorIA`** *(usa `scripts/jugador/controlador_ia.gd`)*
  * **`InterfazJuego`** *(usa `scripts/interfaz/gestor_interfaz.gd`)*
