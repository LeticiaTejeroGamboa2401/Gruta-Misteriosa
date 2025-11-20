## Contexto del Flujo
- `res://Scenes/alux_encuentro_final.gd`: escena de cierre de trivias con selección de 3/5 aciertos y transición. Cambia a `res://Scenes/weapon_selection.tscn` tras completar el amuleto (Scenes/alux_encuentro_final.gd:281–283).
- `res://Scenes/weapon_selection.gd`: diálogo breve del amuleto, muestra 3 armas, guarda selección y textura en `Global` y transiciona a `WalkToBattle.tscn` (Scenes/weapon_selection.gd:139, 151–159, 215–217).
- `res://Scripts/pelea_final.gd`: combate por fases (`dialog` → `dogs` → `huaychivo` → `victory/defeat`) con minijuegos y reglas de daño por arma (Scripts/pelea_final.gd:8, 428–506, 818–860).

## Mecánicas Clave de la Pelea Final
- **Armas y normalización**: tokens canónicos `weapon_a` (Macana), `weapon_b` (Jícara), `weapon_c` (Lanza) (Scripts/pelea_final.gd:709–737).
- **Daño y retaliación**:
  - Daño al atacar según arma y fase; fallback si no hay minijuego (Scripts/pelea_final.gd:656–675).
  - Retaliación fija por arma: C=1, A=2, B=3 corazones (Scripts/pelea_final.gd:678–706).
- **Perros (fase `dogs`)**: 3 nahuales con vida individual 3; barritas dinámicas posicionadas sobre cada uno (Scripts/pelea_final.gd:4–6, 163–183).
  - Minijuego `TimedHit`: cada acierto con `weapon_c` quita 1; con `weapon_a` se acumulan tokens y muere un perro al juntar 2 tokens (Scripts/pelea_final.gd:967–1015, 861–897).
- **Huaychivo (fase `huaychivo`)**: vida 5; minijuego `Simon` con daño por score y reglas por arma (Scripts/pelea_final.gd:185–195, 899–917, 1248–1266, 1268–1281).
- **UI/HUD**: corazón del jugador (6), barra general de enemigos y barras por enemigo; creación y anclado en HUD (Scripts/pelea_final.gd:139–161, 162–195, 1362–1396).
- **Diálogos y gating**: secuencia de introducción y auto-avance; botón "Siguiente" con cooldown e instrucciones del Huaychivo antes del primer intento (Scripts/pelea_final.gd:1670–1813, 549–562, 1814–1833).

## Estado Compartido (Global)
- `Global.selected_weapon` y `Global.selected_weapon_texture` se leen para instanciar la textura del arma y su orientación en la mano del personaje (Scenes/weapon_selection.gd:139, 151–159; Scripts/pelea_final.gd:351–397).
- `Global.selected_character_scene` y `Global.selected_character_name` para instanciar y personalizar al jugador (Scenes/alux_encuentro_final.gd:85–91; Scripts/pelea_final.gd:322–349).

## Minijuegos y Fallbacks
- Carga desde `res://Minigames/TimedHit/TimedHit.tscn` y `res://Minigames/Simon/Simon.tscn`; si faltan, se usa flujo lineal `_execute_combat_turn` (Scripts/pelea_final.gd:818–860, 1292–1357).

## Observaciones y Puntos de Atención
- **Contador de aciertos duplicado** en perros: `dog_press_hits` se incrementa al registrar el acierto (Scripts/pelea_final.gd:981) y otra vez al aplicar daño (Scripts/pelea_final.gd:988), lo que duplica el conteo con `weapon_c`.
- **Inconsistencia de diseño para Jícara**: comentario sugiere "parcial: solo perros" (Scripts/pelea_final.gd:719–722), pero las reglas aplican 0 daño a todos los objetivos (Scripts/pelea_final.gd:1268–1281).
- **Dependencias de animaciones**: se usan "Derecha" y "Golpe" en `AnimatedSprite2D` del jugador y perros; confirmar que existen en assets (Scripts/pelea_final.gd:399–408, 1024–1033, 582–591).
- **Posicionamiento HUD**: barras creadas dinámicamente con anchors/offsets manuales; revisar en ejecución si quedan correctamente ancladas (Scripts/pelea_final.gd:139–161).
- **Capas de colisión**: se configuran a runtime para perros (2) y Huaychivo (4) con máscara al jugador (1); verificar tipos reales de nodos (Scripts/pelea_final.gd:1571–1591, 1595–1613).

## Plan de Trabajo Propuesto
### Fase 1: Correcciones funcionales
- Ajustar incremento de `dog_press_hits` para que cuente 1 por acierto (evitar el doble incremento en 981/988) y validar tokens de Macana.
- Unificar reglas de `weapon_b`: decidir si debe dañar perros (parcial) o ser 0 en todo; reflejarlo en `_apply_weapon_rules` y mensajes.
- Confirmar y robustecer botones `AttackDogs`/`AttackHuaychivo` y su visibilidad por fase.

### Fase 2: Integración de Minijuegos
- Verificar existencia de `TimedHit.tscn` y `Simon.tscn`; estandarizar señales (`finished`, `hit_pressed`) y sus contratos de `score/attempts/rounds`.
- Telemetría mínima: logs de desempeño y resultados por arma para depurar balance.

### Fase 3: Pulido de UX
- Revisar anclado/posición de barras en HUD; mantener consistencia al hacer fade/slide de enemigos.
- Afinar `hit_flash` y tiempos de feedback (`ENEMY_HIT_FLASH_*`, `POST_HIT_DELAY`).
- Confirmar orientación y escala del arma en mano por tipo (rotación −90°, `flip_h/v`).

### Fase 4: Verificación
- Pruebas manuales con cada arma: flujo completo perros→Huaychivo, victoria y derrota.
- Validar transición final: `WinScreen.tscn` o fallback y regreso a hogar (Scripts/pelea_final.gd:1450–1517).

¿Te parece bien que avancemos con estas correcciones y pulidos para la pelea final? 