## Objetivos
- Eliminar barras de vida individuales (perros y Huaychivo) y mantener solo: barra general superior y corazones del jugador.
- Evitar que la HUD bloquee el botón "Siguiente" en diálogos.
- Con arma C (Lanza): permitir seguir avanzando aunque el jugador llegue a 1 corazón (gracia a 1HP).
- Mejorar instrucciones de minijuegos con overlays claros y una ronda práctica.

## Cambios HUD
- Remover creación y uso de barras por enemigo:
  - `Scripts/pelea_final.gd:_spawn_enemy_healthbars()` (Scripts/pelea_final.gd:163–195): eliminar la creación de `dog_healthbars` y `huaychivo_healthbar` y mantener solo `general_enemy_healthbar` (`_spawn_general_enemy_healthbar`, Scripts/pelea_final.gd:139–161).
  - `update_health_ui` (Scripts/pelea_final.gd:1362–1396): quitar lógica que actualiza/posiciona barras individuales, conservar recálculo del total para la barra general.
  - `_process` de seguimiento (agregado): eliminar actualización de posiciones de barras individuales.
- Asegurar que la barra general no bloquee clicks:
  - Ajustar anchors `anchor_top=0.05` y `mouse_filter = Control.MOUSE_FILTER_IGNORE` (Scripts/pelea_final.gd:152–161) y `z_index` por debajo del botón de diálogo.

## Desbloqueo del botón "Siguiente"
- Con la eliminación de barras individuales, se evitan superposiciones. Además, forzar `mouse_filter=IGNORE` en cualquier Control HUD que permanezca (general_enemy_healthbar, healthbar de corazones) para no interceptar clics.

## Gracia a 1HP (arma C)
- En `_enemy_retaliation` (Scripts/pelea_final.gd:678–706): tras aplicar daño, si arma normalizada es `weapon_c` y `player_health <= 1`, clamplear `player_health = 1` mientras fases `dogs/huaychivo`. Evita derrotas por retaliación cuando llevas el arma correcta.

## Instrucciones Minijuegos
- Crear overlay tutorial:
  - `CanvasLayer/UI/TutorialOverlay` con dos paneles: `TimedHitTutorial` y `SimonTutorial`.
  - Contenido: título, paso a paso, iconografía de inputs (tecla/botón), breve animación de ejemplo.
  - Propiedades: `visible=false`, `mouse_filter=STOP` cuando se muestra.
- Hooks:
  - Perros: antes del primer `TimedHit`, mostrar `TimedHitTutorial` y requerir clic en "Comenzar" para iniciar (Scripts/pelea_final.gd:770–776 y antes de `start_minigame("timed_hit")`).
  - Huaychivo: reemplazar `_show_huaychivo_instructions` (Scripts/pelea_final.gd:549–562) para abrir `SimonTutorial` con un botón "Comenzar".
- Ronda práctica:
  - Añadir modo práctica: una ronda inicial por minijuego que no aplica daño ni retaliación; se cierra al terminar y luego se lanza la ronda real.
  - Implementación: bandera `is_practice_round` en minijuegos; en `pelea_final.gd` si `first_time_phase`, llamar `start_minigame` con `practice=true` y ignorar `finished(...)` para daño.

## QA y Validación
- Probar flujo desde `weapon_selection` → `WalkToBattle` → combate.
- Confirmar que el botón "Siguiente" nunca se bloquea.
- Verificar con arma C que la salud no baja de 1 y se puede continuar hasta vencer.
- Verificar que la barra superior refleja el progreso (sumatorio de perros vivos + vida del Huaychivo) y que los corazones del jugador actualizan correctamente.

¿Procedo a implementar estos cambios y añadir los overlays de tutorial con su ronda práctica? 