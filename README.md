# Invasion

Videojuego en desarrollo de **Trigger Games**, creado como proyecto del curso **CC5408 — Taller de Diseño de Videojuegos**.

## La idea

Esta propuesta está descrita en el [devlog inicial del equipo](https://yuu729.itch.io/ultimate-space-shooter-hito-0/devlog/1658441/project-invasion-release).

Un alienígena del planeta **0909** se enfrenta a los **exodials**, los invasores de su mundo. A bordo de su nave, busca llegar a la base enemiga para vengar a su planeta y evitar una nueva invasión.

Pero no todos los enfrentamientos se pueden resolver desde la cabina: algunas naves enemigas son pequeñas y veloces, y usan planetas y asteroides como cobertura. Para combatirlas, el protagonista deberá abandonar su nave y atacar a pie desde las superficies cercanas.

## Mecánica principal

El juego propone alternar entre dos formas de combate:

- **En la nave:** desplazarse por el espacio y enfrentarse a los enemigos con el armamento de la nave.
- **A pie:** combatir desde planetas y asteroides, aprovechando la movilidad y la cobertura del entorno.

Ambos modos serán necesarios para avanzar. El desafío estará en decidir cuándo pilotar la nave y cuándo salir de ella.

## Estado del proyecto

El proyecto se desarrolla en **Godot** y está en `invasion-project/`. Incluye combate espacial, combate a pie y el prototipo integrado presentado en el Hito 1.

La integración del Hito 1 está en `integracion/juego.tscn`, con cambio entre nave
y personaje. Esta rama también incorpora la primera defensa de plataforma del
siguiente devlog: torre con salud, cúpula que restringe los ataques y una oleada
finita. Para probarla, abrir `terrestre/defensa/demo_defensa.tscn` y pulsar **F6**.
Ver la [guía de defensa](invasion-project/terrestre/defensa/README.md).

Para probar el combate terrestre en Godot, abre `terrestre/demo_terrestre.tscn` y presiona **F6**. Incluye movimiento y disparos a pie, plataformas, cobertura y enemigos especiales. Consulta los [controles y la guía de integración](invasion-project/terrestre/README.md).

### Próximos pasos

- [x] Implementar una primera versión del movimiento y los disparos de la nave.
- [x] Agregar movimiento y disparos a pie en una escena de prueba.
- [x] Implementar la mecánica de entrar y salir de la nave.
- [x] Crear un enemigo especial vulnerable al arma terrestre.
- [x] Probar la defensa de una torre con cúpula, victoria y derrota.
- [ ] Integrar encuentros que requieran alternar entre ambos modos de combate.
- [ ] Diseñar los niveles e integrar arte y sonido.

## Equipo

**Trigger Games** está formado por:

- Antonia
- Benjamín
- Nicolás

Antonia se encarga del combate espacial, Nicolás del combate terrestre y Benjamín de la transición y el ensamblaje.

## Ramas de trabajo

| Rama | Responsabilidad |
| --- | --- |
| `main` | Versión compartida para presentar, después de integrar y probar los avances. |
| `combate-espacial` | Antonia: nave, vuelo, disparos, enemigos y daño espacial. |
| `combate-terrestre` | Nicolás: personaje, movimiento y disparos a pie, plataformas y enemigos terrestres. |
| `integracion` | Benjamín: transición entre modos, cámaras, HUD y ensamblaje de las escenas. |

`integracion` parte de la versión que ya reúne el combate espacial actualizado y el prototipo terrestre. Las ramas contienen el proyecto completo; sus nombres indican el trabajo que se desarrolla en cada una.

## Enlaces

- [Devlog: Project Invasion release](https://yuu729.itch.io/ultimate-space-shooter-hito-0/devlog/1658441/project-invasion-release)
- [Repositorio en GitHub](https://github.com/nicsoto/invasion)
