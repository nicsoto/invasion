# Defensa de plataforma — Hito 2

Entrega de combate terrestre según el devlog posterior al Hito 1:
una torre debe sobrevivir a una oleada, y el jugador tiene que bajar para
eliminar a sus atacantes desde el interior de una cúpula.

## Probar

Abrir `res://terrestre/defensa/demo_defensa.tscn` y pulsar **F6**. Desde la raíz
del repositorio también se puede ejecutar:

```bash
godot --path invasion-project res://terrestre/defensa/demo_defensa.tscn
```

La escena comienza en la nave. Volar hacia el letrero de la plataforma y pulsar
**E** cuando aparezca la opción de aterrizar. Hay **12 segundos** de preparación;
el ataque comienza aunque el jugador siga en la nave. Al bajar, eliminar a los
asaltantes que se acercan a la torre. Cada uno requiere tres disparos terrestres.

| Control | Acción |
| --- | --- |
| WASD y mouse | Desplazarse y apuntar |
| Clic izquierdo | Disparar |
| E cerca del asteroide / de la nave | Bajar / subir |
| Espacio / Q en la nave | Ascender / descender |
| Espacio / Shift a pie | Saltar / correr |
| P | Pausar / continuar |
| R | Reiniciar, también después de ganar o perder |
| Escape | Salir del juego |

La defensa termina con **victoria** cuando han aparecido y sido derrotados todos
los atacantes y la torre sigue viva. Hay **derrota** si se destruye la torre o
muere el piloto. Volver a la nave no detiene el ataque ni recupera la salud.

La bajada reproduce la animación del equipo y entrega el control al finalizar.
Mientras dura, no se puede disparar ni subir otra vez. Al recibir daño, el
jugador ve un destello y la torre muestra una alerta; su barra cambia de color
cuando está en estado crítico. Victoria y derrota tienen mensaje y sonido.
La muerte del piloto muestra primero su secuencia y después permite reiniciar.

## Reglas de la cúpula

| Ataque | Resultado |
| --- | --- |
| Bala de la nave del jugador | Se consume al tocar la cúpula; tampoco puede disparar desde su interior. |
| Bala del enemigo espacial grande actual | Se bloquea de la misma forma. |
| Ataque del asaltante pequeño | Atraviesa la cúpula; las coberturas físicas siguen bloqueándolo. |
| Disparo terrestre iniciado dentro | Puede dañar a los asaltantes, incluso si todavía están fuera. |
| Disparo terrestre iniciado fuera | No puede dañar a los asaltantes de esa plataforma. |

La cúpula filtra **ataques**, no movimiento: se puede atravesar al volar o caminar.
Entrar con la nave no permite evitar la regla. Para causar daño al asaltante se
comprueba que el atacante sea el personaje terrestre activo y que el origen de
su disparo esté dentro de la cúpula asignada a ese enemigo.

La torre es aliada: no recibe daño del arma del jugador ni de balas espaciales
genéricas. Los asaltantes emiten un ataque identificado como `enemigo_pequeno`.

## Componentes reutilizables

| Archivo | Responsabilidad |
| --- | --- |
| `torre.tscn` / `torre.gd` | Salud, colisión, indicador 3D y destrucción. |
| `cupula.tscn` / `cupula.gd` | Zona, intersecciones de disparos y aviso de bloqueo. |
| `cupula.gdshader` | Semiesfera transparente, retícula y destello cian al bloquear. |
| `reglas_cupula.gd` | Consulta de la primera cúpula que bloquea un disparo. |
| `atacante_torre.tscn` / `atacante_torre.gd` | Variante del centinela existente que se acerca a una torre y la ataca. |
| `plataforma_defensa.tscn` / `plataforma_defensa.gd` | Asteroide, coberturas, torre, cúpula y oleada finita. |
| `demo_defensa.tscn` / `demo_defensa.gd` | Demostración jugable con la transición ya creada por el equipo, HUD y resultados. |

La geometría de la plataforma parte de `integracion/base_asteroide.tscn`, con los
centinelas fijos sustituidos por llegadas de asaltantes y rocas bajo el borde.
Conserva los marcadores `PuntoNave`, `PuntoBajada` y `Baliza` para reutilizar
el controlador de transición. La demo hereda el script de `integracion/juego.gd`.

## Parámetros iniciales

Estos valores son ajustables en el Inspector y sirven como primera prueba de
balance, no como la dificultad definitiva del juego.

| Parámetro | Valor |
| --- | --- |
| Salud de la torre | 180 |
| Preparación | 12 s |
| Atacantes totales | 4 |
| Intervalo entre llegadas | 5 s |
| Salud de cada asaltante | 75 |
| Daño de su ataque | 5 |
| Espera entre ataques / aviso previo | 3,2 s / 0,8 s |
| Radio de la cúpula | 19,5 unidades |

La salud de la torre se ajusta en `Torre.salud_maxima`. La cantidad, preparación
e intervalo se ajustan en el nodo raíz de la plataforma. El daño y movimiento
del asaltante se ajustan en su escena. La cúpula se puede trasladar y girar con
la plataforma; su radio determina tanto la representación como las reglas.

## Conectar con niveles y spawners

Una plataforma recién instanciada espera hasta que el nivel llame `iniciar()`.
La demo hace esa llamada al comenzar; así existe un plazo para llegar y bajar.
Se puede colocar otra instancia en una posición distinta para crear otro encuentro.

```gdscript
# Después de añadir la plataforma al árbol:
plataforma.defensa_completada.connect(_pasar_al_siguiente_encuentro)
plataforma.torre_destruida.connect(_perder_partida)
plataforma.progreso_cambiado.connect(_actualizar_enemigos_restantes)
plataforma.torre.salud_cambiada.connect(_actualizar_salud_torre)
plataforma.iniciar()
```

La plataforma emite el resultado; no pausa todo el juego por sí misma. La demo
es quien pausa y muestra la victoria o derrota. El nivel integrado podrá decidir
si desbloquea otra zona, inicia otro encuentro o termina la partida.

Para **Benjamín**, `personaje.tscn` y `enemigo_especial.tscn` incluyen los nodos
de audio, modelos y cámaras que necesitan sus scripts. El nivel de integración
ya instancia estas escenas comunes: evitar copiar sus nodos dentro de otro
nivel. Al bajar, llamar a `establecer_altura_superficie()` con la altura del
marcador antes de activar al personaje; así la caída funciona en plataformas
ubicadas a distintas alturas.

Para **Benja**, cada instancia de `plataforma_defensa.tscn` puede colocarse y
configurarse por separado. `cantidad_atacantes`, `preparacion` e
`intervalo_llegadas` permiten ajustar el encuentro. La torre, la cúpula y sus
efectos mantienen estados independientes; cada atacante pertenece a su propia
torre. La demo de esta carpeta prueba una defensa completa, mientras que el
mapa definitivo y su progresión quedan a cargo del nivel.

El generador incluido es local a esta defensa y tiene un final definido. No es
el generador global de niveles ni reemplaza los spawners espaciales del equipo.
Cada atacante recibe explícitamente su torre y su cúpula; no busca la primera
torre del mapa. Para crear otra variante de nave pequeña, se puede reutilizar
`configurar(torre, cupula, punto_de_ataque)` y mantener las reglas de daño.

`reglas_cupula.gd` recibe el segmento del disparo y su tipo. Los disparos pequeños
usan `enemigo_pequeno`; el arma a pie usa `terrestre`; las balas actuales usan
`espacial`. Los futuros proyectiles deben consultar esta regla antes de aplicar
daño. La torre recibe los ataques permitidos mediante `recibir_ataque_pequeno`.

El método `recibir_disparo_desde(cantidad, personaje)` permite validar el origen
del daño en el atacante protegido. El enemigo especial de la demo anterior
conserva su interfaz original. Los únicos puntos compartidos ajustados son la
consulta de cúpulas en `bala.gd` y el envío del contexto en `personaje.gd`.

## Apariencia y alcance

Se reutilizan el alienígena, el arma, la nebulosa, las rocas y la ambientación
existentes, junto con las naves, el modelo de centinela, la animación de bajada
y los sonidos incorporados por Antonia. La torre mantiene los verdes oscuros,
las formas de seis lados, el núcleo lima y la alerta naranja. La cúpula es translúcida, y su
destello de bloqueo usa el mismo cian del blindaje del enemigo.

Esta entrega contiene una plataforma y una oleada; la distribución por el mapa,
la progresión entre niveles, nuevas clases de enemigos y el acabado completo
quedan para las siguientes tareas del equipo. F5 conserva la escena principal
del proyecto; usar F6 sobre `demo_defensa.tscn` para probar esta parte.

## Verificación

```bash
godot --headless --path invasion-project --script res://terrestre/tests/pruebas_defensa.gd
godot --headless --path invasion-project --script res://terrestre/tests/pruebas_terrestres.gd
godot --headless --path invasion-project --script res://integracion/tests/pruebas_integracion.gd
godot --headless --path invasion-project --script res://terrestre/tests/pruebas_hito2.gd
```

Las pruebas cubren las intersecciones de la cúpula, disparos reales a ambos lados,
fuego amigo, daño a la torre mientras se pilota, llegadas pendientes, transición,
pausa, victoria, derrota y reinicio. Las dos suites anteriores comprueban que
el combate terrestre y la integración del Hito 1 siguen funcionando.
La suite del Hito 2 prueba además las animaciones reales, pausa y reinicios
durante las transiciones o la muerte, caída en plataformas bajas, feedback de
daño, estados visuales independientes y asignación de atacantes a su cúpula.
