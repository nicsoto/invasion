# Recursos visuales de Hito 0

Adaptados del archivo `Hito0-space shooter.exe` proporcionado por Nicolás,
correspondiente al juego de un integrante del equipo que sirve como referencia
para Invasion.

| Archivo | Recurso del juego original | Adaptación |
| --- | --- | --- |
| `alien.res` | `Scenes/player.tscn` → `chata/Armature/Skeleton3D/Cube_001` | Geometría y materiales del alienígena en pose fija, sin esqueleto ni scripts. |
| `arma.res` | `moodelos/gun.tscn` → `Model` | Geometría y materiales del arma, sin el controlador original. |
| `roca.res` | `moodelos/rock_1.tscn` → `Icosphere` | Geometría simplificada a 3.496 triángulos y material original. |
| `nebulosa.png` | `panorama_image.png` | Panorama verde reducido de 7.680 × 4.320 a 2.560 × 1.440 píxeles. |

Los modelos usan materiales de color integrados en cada recurso; no dependen
del ejecutable ni de rutas del proyecto original. El arma terrestre conserva
el disparo y la cadencia del prototipo de Invasion.

La ambientación, el diseño del centinela y los colores de la interfaz se adaptaron
en este proyecto tomando estos recursos como referencia. Los planetas y las
rocas distantes de `../ambientacion.tscn` son decorativos y no tienen colisión.

El alienígena todavía no tiene animaciones de caminar o saltar. Su modelo se
oculta de la cámara en primera persona usando la capa visual 2.

SHA-256 del ejecutable de referencia:
`5e21d3aff367732d0cc0d6923f76dd8098e8d9095b44adc1005f126f30e4e123`.
