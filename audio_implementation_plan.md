# Plan de Implementación de Audio

## ✅ Completado

### 1. Minijuego Simon (`Simon.gd`)
- ✅ Tonos elementales únicos para cada botón (Fuego, Tierra, Agua, Aire)
- ✅ Sonido de éxito mejorado (`powerUp11.ogg`)
- ✅ Sonido de error mejorado (`error_003.ogg`)

---

## 📋 Pendiente de Implementación

### 2. Pelea Final - UI Básica (`pelea_final.gd`)

**Añadir AudioStreamPlayers para:**
- Botones de ataque (click)
- Diálogos (abrir/cerrar/siguiente)
- Feedback de victoria/derrota

**Archivos sugeridos:**
- Click botón: `kenney_interface-sounds/AudioClick_001.ogg`
- Hover botón: `kenney_ui-audio-2/Audio/rollover1.ogg`
- Diálogo abrir: `kenney_interface-sounds/Audio/open_001.ogg`
- Diálogo siguiente: `kenney_interface-sounds/Audio/tick_002.ogg`

### 3. Minijuegos dentro de Pelea Final

#### A. Timed Hit
**Ubicación:** `Minigames/TimedHit/TimedHit.gd` (si existe como archivo separado)

**Sonidos necesarios:**
- Carga/Build-up: `kenney_digital-audio/Audio/powerUp1.ogg` (pitch modulado)
- Perfect hit: `kenney_impact-sounds/Audio/impactBell_heavy_001.ogg`
- Good hit: `kenney_impact-sounds/Audio/impactMetal_medium_001.ogg`
- Miss: `kenney_interface-sounds/Audio/glass_002.ogg`

#### B. Mash (Button Mashing)
**Ubicación:** `Minigames/Mash/Mash.gd` (si existe como archivo separado)

**Sonidos necesarios:**
- Click individual: `kenney_interface-sounds/Audio/tick_001.ogg`
- Win: `kenney_impact-sounds/Audio/impactPunch_heavy_001.ogg`

### 4. Weapon Selection (`weapon_selection.gd`)

**Sonidos necesarios:**
- Hover sobre armas: `kenney_ui-audio-2/Audio/rollover3.ogg`
- Selección: `kenney_digital-audio/Audio/powerUp3.ogg`
- Sonidos específicos por arma al seleccionar

### 5. Walk to Battle (`walk_to_battle.gd`)

**Sonidos opcionales:**
- Pasos: `kenney_impact-sounds/Audio/footstep_grass_00X.ogg` (loop/variaciones)

---

## 🎯 Recomendación de Prioridad

1. **Alta Prioridad - UX Inmediato:**
   - Pelea Final: Clicks y diálogos (10 min)
   - Minijuegos Timed Hit y Mash (15 min cada uno)

2. **Media Prioridad - Polish:**
   - Weapon Selection hovers y selections (10 min)

3. **Baja Prioridad - Opcional:**
   - Walk to Battle footsteps (5 min)

**Tiempo total estimado: ~60 minutos**

---

## 📝 Notas de Implementación

### Patrón Recomendado para Todos los Scripts

```gdscript
# Variables de audio (al inicio del script)
@onready var ui_click_sfx: AudioStreamPlayer
@onready var ui_hover_sfx: AudioStreamPlayer
# ... otros según necesidad

# En _ready() o init()
func _setup_audio():
    ui_click_sfx = AudioStreamPlayer.new()
    ui_click_sfx.stream = load("res://assets/sounds/kenney_interface-sounds/Audio/click_001.ogg")
    ui_click_sfx.volume_db = -10
    add_child(ui_click_sfx)

    # ... configurar otros sonidos

# Al presionar botón
func _on_button_pressed():
    if ui_click_sfx:
        ui_click_sfx.play()
    # ... resto de lógica
```

### Volúmenes Sugeridos

- UI Clicks: `-10dB` a `-15dB`
- Feedback (success/error): `-5dB` a `-10dB`
- Impactos de juego: `-3dB` a `-8dB`
- Tonos/Chimes: `-8dB` a `-12dB`

---

## ¿Continuar con la implementación?

Marcar con `[x]` lo que quieres que implemente:

- [x] Pelea Final - UI básica
- [ ] Minijuego Timed Hit
- [ ] Minijuego Mash
- [ ] Weapon Selection
- [ ] Walk to Battle footsteps

O simplemente responde "implementa todo" si quieres que proceda con toda la lista.
