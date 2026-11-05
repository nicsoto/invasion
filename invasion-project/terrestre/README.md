# Combate terrestre

Parte de Nicolás: personaje reutilizable, disparos a pie, coberturas, enemigos
especiales y defensa de torres. El personaje y el centinela son escenas comunes
usadas tanto por las demos terrestres como por `integracion/juego.tscn`.

La entrega terrestre del **Hito 2** está en
[`defensa/demo_defensa.tscn`](defensa/demo_defensa.tscn): una plataforma con torre,
cúpula y una oleada que obliga a combatir a pie. Abrir esa escena y pulsar **F6**.
Consultar la [guía de defensa e integración](defensa/README.md) para sus reglas,
parámetros y señales. Incluye los modelos, sonidos y animación de desembarco del
equipo. La demo terrestre original descrita debajo sigue disponible.

## Probar la demo original en Godot

1. Importar `invasion-project/project.godot` con Godot 4.7.1, la versión usada para
   validar esta implementación (el proyecto declara Godot 4.7).
2. Abrir `res://terrestre/demo_terrestre.tscn`.
3. Presionar **F6 — Ejecutar escena actual**. F5 sigue abriendo el combate espacial.

También se puede ejecutar desde la raíz del repositorio:

```bash
godot --path invasion-project res://terrestre/demo_terrestre.tscn
```

Si Godot no está en el PATH, usar la ruta al ejecutable en lugar de `godot`.

| Control | Acción |
| --- | --- |
| WASD | Moverse |
| Mouse | Apuntar |
| Clic izquierdo mantenido | Disparar |
| Espacio | Saltar |
| Shift | Correr |
| Esc | Pausar / continuar la demo |
| R | Reiniciar la demo, también después de morir o ganar |
| E | Solicitar interacción; en la integración permite volver a la nave |

El objetivo es destruir los dos centinelas. Se acercan al personaje y avisan antes
de disparar: puedes buscar cobertura. Cada uno tiene 100 de salud y necesita
cuatro impactos de 25.
La mira cambia al acertar. La demo muestra la salud, el objetivo y los controles.
Caer al vacío o perder toda la salud termina el intento; R permite repetirlo.

## Estética de Hito 0

La escena usa la nebulosa verde, el alienígena, el arma de colores y las rocas
del juego de referencia `Hito0-space shooter.exe`. Se añadieron planetas verdes
decorativos, los modelos nuevos de centinela con núcleo luminoso y una interfaz
negra con detalles verde lima. El núcleo de cada centinela cambia a naranja al
avisar un ataque y a cian al bloquear un disparo espacial.

El personaje conserva el modelo original y utiliza la animación de desembarco
aportada por Antonia, además de retroceso, movimiento de cámara, pasos y una
secuencia de muerte. Las coberturas conservan colisiones de caja simplificadas.
Los controles, el daño y las señales de integración siguen siendo los del
prototipo terrestre. Los recursos y sus adaptaciones están documentados en
[arte/hito0/README.md](arte/hito0/README.md).

## Qué está implementado

- Movimiento en primera persona, aceleración, carrera y salto con una pequeña
  tolerancia al borde y a pulsaciones justo antes de aterrizar.
- Gravedad reducida constante hacia `-Y`, colisión con suelo, paredes y rampas.
- Asteroide de prueba con superficie plana, coberturas, escalones y una isla para
  saltar. Son formas provisionales editables en el editor.
- Disparo instantáneo mediante una consulta física desde la cámara, con alcance,
  cadencia y un trazo visual breve. Las rocas bloquean los disparos de ambos lados.
- Centinela con persecución, aviso de ataque, vida e inmunidad al arma espacial.
- Activación/desactivación y señales para conectar la transición.

La gravedad alrededor de planetas esféricos y el acabado completo quedan
pendientes. El blindaje es una regla de prototipo para
probar la necesidad del combate a pie; no simula todavía la evasión de naves
pequeñas descrita en la historia.

## Integración para Benjamín

Instanciar `personaje.tscn`. Su origen está en los pies; colocarlo un poco por
encima de una superficie con colisión. Para comenzar dentro de la nave, configurar
`activo = false` en el Inspector **antes** de añadir la escena al árbol.

La interfaz del controlador es:

```gdscript
# Al bajar: desactivar primero el controlador de la nave y su grupo "jugador".
personaje.global_position = punto_de_bajada.global_position
personaje.establecer_altura_superficie(punto_de_bajada.global_position.y)
personaje.set_activo(true) # Activa colisión, control, visibilidad y cámara propia.
personaje.iniciar_animacion_bajada(nave)

# Al subir: después activar la nave y hacer actual su cámara.
personaje.set_activo(false)

# Si el ensamblaje usa una cámara externa:
personaje.set_activo(true, false)
# La cámara externa debe alinearse con Cabeza/Camera3D, usada para apuntar.

# Para menús sin pausar todo el árbol:
personaje.capturar_mouse(false)
personaje.capturar_mouse(true)
```

`usar_camara_propia = false` evita tomar la cámara automáticamente en `_ready()`.
`set_activo` debe llamarse después de que el personaje esté listo. Desactivarlo
pone su velocidad en cero, oculta el modelo, desactiva la colisión y lo retira
de los grupos `jugador` y `personaje_terrestre`. El controlador que lo sustituye
debe tomar la cámara y administrar el mouse. Un personaje muerto no se reactiva;
para un nuevo intento, recrearlo o recargar la escena.

Señales disponibles:

- `interaccion_solicitada(personaje)`: al pulsar E. El ensamblaje decide si hay
  una nave cerca y si se puede subir; este script no teletransporta al jugador.
- `salud_cambiada(actual, maxima)` y `murio`: para HUD y fin de partida.
- `disparo_realizado(acerto)`: para efectos, sonido o indicadores de impacto.
- `bajada_finalizada`: al recuperar el control después del desembarco.

Durante `en_transicion` no se permiten movimiento, disparos ni abordaje; el
personaje es invulnerable. Desactivarlo cancela la animación y restaura la nave.
`camara` y `camara_fps` apuntan a la misma cámara para mantener compatibilidad.
La salud llega a cero y el control se desactiva inmediatamente al morir;
`murio` se emite después de la secuencia de muerte. Las pruebas de lógica pueden
usar `reproducir_cinematicas = false`; `pruebas_hito2.gd` verifica el flujo real
con las cinemáticas habilitadas, incluida su interrupción por pausa o reinicio.

Al conectar un HUD después de `_ready`, leer también `salud` y `salud_maxima`
para establecer el valor inicial. Las acciones `pie_*` se registran al iniciar
el personaje si no existen; pueden configurarse en el Input Map con esos mismos
nombres. No se modifican las acciones de la nave.

## Integración con combate espacial

El centinela pertenece a `enemigo`. La bala espacial existente llama
`take_damage(cantidad)`: el centinela bloquea ese daño y muestra el blindaje.
El arma del personaje llama `recibir_disparo_terrestre(cantidad)` para dañarlo.
Si el objetivo solo ofrece `take_damage`, el arma terrestre usa ese método, por
lo que también puede atacar a los enemigos espaciales existentes.

Conservar esta distinción si se cambia el sistema de daño. Es una interfaz simple
para el prototipo, no un detector automático de si el atacante está dentro de una
nave. El centinela busca el grupo `personaje_terrestre`; no persigue ni ataca naves.

La escena de prueba usa la capa física 1, igual que las escenas actuales. La capa
visual 2 del cuerpo del personaje se excluye de su cámara para no mostrar el
modelo desde dentro. Los trazos se liberan tras 0.07 segundos.

## Pruebas

Desde la raíz del repositorio:

```bash
godot --headless --path invasion-project --script res://terrestre/tests/pruebas_terrestres.gd
```

Las comprobaciones ejecutan escenas y física reales: movimiento, salto, suelo,
cobertura, daño de ambos modos, cadencia, muerte, activación para la transición,
pausa, victoria y reinicio. El proceso devuelve código 1 si algo falla.

Para revisar manualmente: caminar, subir la rampa, saltar entre plataformas,
disparar contra una roca y contra un centinela, ponerse a cubierto, caer del
asteroide, pausar y reiniciar. Probar también en el computador de la presentación.
