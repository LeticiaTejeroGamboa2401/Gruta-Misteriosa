# Mapeo de Sonidos Kenney para el Juego

Este documento mapea los sonidos de Kenney disponibles en `assets/sounds/` a los diferentes usos en el juego.

## 📁 Paquetes Disponibles

1. **kenney_interface-sounds**: UI general (clicks, confirmaciones, errores, toggles)
2. **kenney_ui-audio-2**: UI alternativa (clicks, hovers, switches)
3. **kenney_digital-audio**: Efectos digitales/sci-fi (power-ups, lasers, tonos)
4. **kenney_impact-sounds**: Impactos físicos (golpes, pasos, materiales)

---

## 🎮 Mapeo por Sistema

### 1. UI General (Todos los Scripts)

**Botones estándar (Next, Attack, etc.):**
- Click: `kenney_interface-sounds/Audio/click_001.ogg`
- Hover: `kenney_ui-audio-2/Audio/rollover1.ogg`
- Confirmación: `kenney_interface-sounds/Audio/confirmation_001.ogg`

**Botones secundarios/cancelar:**
- Click: `kenney_interface-sounds/Audio/back_001.ogg`

**Errores/Restricciones:**
-Error genérico: `kenney_interface-sounds/Audio/error_001.ogg`

### 2. Weapon Selection (`weapon_selection.gd`)

**Hover sobre armas:**
- `kenney_ui-audio-2/Audio/rollover3.ogg`

**Selección final de arma:**
- `kenney_interface-sounds/Audio/confirmation_002.ogg`
- Alternativamente: `kenney_digital-audio/Audio/powerUp3.ogg` (más épico)

**Armas específicas:**
- Macana: `kenney_impact-sounds/Audio/impactWood_heavy_000.ogg`
- Jícara: `kenney_impact-sounds/Audio/impactGlass_light_001.ogg`
- Lanza: `kenney_impact-sounds/Audio/impactMetal_light_002.ogg`

### 3. Minijuego Simon (`Simon.gd`)

**Tonos Elementales (usar Digital Audio para variedad tonal):**
- Fuego: `kenney_digital-audio/Audio/tone1.ogg` (más grave/cálido)
- Tierra: `kenney_digital-audio/Audio/lowThreeTone.ogg`
- Agua: `kenney_digital-audio/Audio/phaserDown2.ogg`
- Aire: `kenney_digital-audio/Audio/phaserUp3.ogg`

**Feedback:**
- Éxito: `kenney_digital-audio/Audio/powerUp11.ogg`
- Fallo: `kenney_interface-sounds/Audio/error_003.ogg`

**Secuencia jugando:**
- Flash botón: Los tonos individuales arriba

### 4. Minijuego Timed Hit

**Mecánica:**
- Cargando (loop): `kenney_digital-audio/Audio/powerUp1.ogg`
- Perfect hit: `kenney_impact-sounds/Audio/impactBell_heavy_001.ogg`
- Good hit: `kenney_impact-sounds/Audio/impactMetal_medium_001.ogg`
- Miss: `kenney_interface-sounds/Audio/glass_002.ogg`

### 5. Minijuego Mash (Button Mashing)

**Mecánica:**
- Click individual: `kenney_interface-sounds/Audio/tick_001.ogg`
- Win/Explosión: `kenney_impact-sounds/Audio/impactPunch_heavy_001.ogg`

### 6. Pelea Final (`pelea_final.gd`)

**Ataques del jugador:**
- Swing arma: `kenney_impact-sounds/Audio/impactWood_medium_000.ogg` (varía según arma)
- Impacto: `kenney_impact-sounds/Audio/impactPunch_heavy_002.ogg`

**Daño al jugador:**
- Recibir daño: `kenney_impact-sounds/Audio/impactSoft_heavy_001.ogg`

**Diálogos/Transiciones:**
- Mostrar diálogo: `kenney_interface-sounds/Audio/open_001.ogg`
- Cerrar diálogo: `kenney_interface-sounds/Audio/close_001.ogg`
- Siguiente texto: `kenney_interface-sounds/Audio/tick_002.ogg`

### 7. Victory/Game Over

**Victoria:**
- Ya tienes `audio/triunfo.ogg` y `audio/win.ogg` - mantenerlos

**Derrota:**
- Ya tienes `audio/losing.ogg` - mantener

**Retry button:**
- `kenney_ui-audio-2/Audio/switch15.ogg`

---

## 🔧 Rutas Base para Scripts

```gdscript
const SFX_BASE = "res://assets/sounds/"
const SFX_INTERFACE = SFX_BASE + "kenney_interface-sounds/Audio/"
const SFX_UI = SFX_BASE + "kenney_ui-audio-2/Audio/"
const SFX_DIGITAL = SFX_BASE + "kenney_digital-audio/Audio/"
const SFX_IMPACT = SFX_BASE + "kenney_impact-sounds/Audio/"
```

---

## 📝 Notas de Implementación

1. **Variaciones**: Kenney incluye múltiples variaciones numeradas (ej. click_001 a click_005). Usa `randi() % 5` para variar.
2. **Volumen**: Los sonidos de UI deberían estar a -10dB ~ -15dB para no ser intrusivos.
3. **Impact sounds**: Perfectos para golpes y efectos físicos en miniguegos.
4. **Digital sounds**: Ideales para feedback de minijuegos y power-ups.
5. **Footsteps**: Disponibles en Impact si necesitas pasos para Walk to Battle.

---

## ✅ Prioridad de Implementación

1. **Alta**: Simon minigame (feedback inmediato crítico)
2. **Alta**: UI clicks/hovers (mejora la sensación general)
3. **Media**: Timed Hit y Mash minigames
4. **Media**: Pelea final impacts
5. **Baja**: Weapon selection hovers
6. **Opcional**: Footsteps en WalkToBattle
