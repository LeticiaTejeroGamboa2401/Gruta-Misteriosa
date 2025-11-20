# Recomendaciones de Audio para Escenas Finales y Minijuegos

Aquí tienes una lista detallada de los efectos de sonido (SFX) y música necesarios para completar la experiencia auditiva de las escenas finales de tu juego, junto con recomendaciones de dónde conseguirlos.

## 🌐 Dónde conseguir sonidos (Gratis y Royalty-Free)

*   **[Freesound.org](https://freesound.org/)**: La mejor opción para efectos de sonido específicos (golpes, magia, pasos). Busca por términos como "magic chime", "heavy impact", "monster growl". Asegúrate de revisar la licencia (CC0 es lo mejor).
*   **[OpenGameArt.org](https://opengameart.org/)**: Excelente para música y paquetes de sonidos estilo retro o RPG.
*   **[Itch.io (Game Assets)](https://itch.io/game-assets/free/tag-sound-effects)**: Muchos creadores suben paquetes de alta calidad gratuitos o baratos.
*   **[Sonnis.com (GDC Bundles)](https://sonniss.com/gameaudiogdc)**: Archivos gigantescos de sonidos profesionales gratuitos que regalan cada año.
*   **[Kenney.nl Assets](https://kenney.nl/assets/category:audio)**: Paquetes de sonidos de UI y RPG muy limpios y consistentes.

---

## 🎵 Lista de Sonidos por Escena

### 1. Selección de Arma (`Scenes/weapon_selection.tscn`)
**Ambiente:** Místico, solemne, preparación.

*   **Música:** `bgm_weapon_selection.ogg`
    *   *Search Keywords:* `mysterious ambient loop`, `tribal flute ambient`, `ritual music`, `calm rpg menu music`.
*   **SFX UI:**
    *   `ui_hover.wav` (Suave/Piedra)
        *   *Search Keywords:* `stone slide`, `rock scrape small`, `ui hover organic`, `wind swoosh soft`.
    *   `ui_select_weapon.wav` (Fuerte/Resonante)
        *   *Search Keywords:* `sword sheathe heavy`, `cinematic impact hit`, `gong resonance`, `heavy weapon equip`, `rpg inventory select`.
*   **SFX Armas (al seleccionar):**
    *   *Macana:* `wood hit heavy`, `staff impact`, `blunt weapon equip`.
    *   *Jícara:* `water splash small`, `potion drink`, `liquid bubble magic`.
    *   *Lanza:* `sword schwing`, `metal blade sharp`, `knife slice air`.

### 2. Caminata a Batalla (`Scenes/WalkToBattle.tscn`)
**Ambiente:** Tensión creciente, transición.

*   **Música:** `bgm_pre_battle.ogg`
    *   *Search Keywords:* `war drums loop`, `tension cinematic build up`, `dark forest ambient music`.
*   **SFX Ambiente:**
    *   `env_forest_night.wav`
        *   *Search Keywords:* `forest night ambience`, `crickets wind loop`, `owl hoot distant`.
    *   `sfx_footsteps_grass.wav`
        *   *Search Keywords:* `footsteps grass`, `footsteps dirt running`, `leaves crunch walk`.

### 3. Pelea Final (`Scenes/Pelea_Final.tscn`)
**Ambiente:** Épico, peligroso, acción.

*   **Música:** `bgm_boss_phase1.ogg`
    *   *Search Keywords:* `boss battle music loop`, `action rpg battle`, `epic orchestral combat`, `fast paced tribal battle`.
*   **SFX Huaychivo:**
    *   `boss_growl.wav`
        *   *Search Keywords:* `monster growl`, `beast roar`, `demon voice guttural`.
    *   `boss_attack_magic.wav`
        *   *Search Keywords:* `fireball whoosh`, `dark magic cast`, `flame burst`.
    *   `boss_damage.wav`
        *   *Search Keywords:* `monster pain`, `beast grunt`, `flesh impact heavy`.
*   **SFX Jugador:**
    *   `player_attack_swing.wav`
        *   *Search Keywords:* `sword swoosh`, `weapon swing air`, `stick whoosh`.
    *   `player_hit_impact.wav`
        *   *Search Keywords:* `punch impact`, `sword hit flesh`, `kick heavy`.
    *   `player_hurt.wav`
        *   *Search Keywords:* `male grunt pain`, `kid hurt voice`, `character damage vocal`.

#### 🎮 Sonidos para Minijuegos (Dentro de Pelea Final)

**A. Minijuego Simon (Amuletos Elementales)**
*   **Tonos Elementales:**
    *   `simon_fire.wav`: *Search Keywords:* `fire burst short`, `torch ignite`, `flame whoosh`.
    *   `simon_earth.wav`: *Search Keywords:* `rock thud`, `stone impact deep`, `earthquake rumble short`.
    *   `simon_water.wav`: *Search Keywords:* `water drop heavy`, `splash small`, `liquid bloop`.
    *   `simon_air.wav`: *Search Keywords:* `wind gust short`, `flute staccato`, `chime wind`.
*   **Feedback:**
    *   `simon_success.wav`: *Search Keywords:* `magic chime success`, `harp glissando up`, `level up sound`.
    *   `simon_fail.wav`: *Search Keywords:* `error buzzer`, `wrong answer sound`, `magic fizzle`.

**B. Minijuego Timed Hit (Golpe Cronometrado)**
*   **Mecánica:**
    *   `timed_charge.wav`: *Search Keywords:* `energy charge up`, `pitch rising effect`, `power up sound`.
    *   `timed_perfect.wav`: *Search Keywords:* `critical hit sound`, `sword clash metal`, `bell ding bright`.
    *   `timed_good.wav`: *Search Keywords:* `punch hit`, `impact thud`.
    *   `timed_miss.wav`: *Search Keywords:* `whoosh air`, `missed swing`.

**C. Minijuego Mash (Presionar Rápido)**
*   **Mecánica:**
    *   `mash_struggle.wav`: *Search Keywords:* `rope tension`, `wood creaking stress`, `magic beam clash loop`.
    *   `mash_click.wav`: *Search Keywords:* `ui click mechanical`, `drum hit taiko`.
    *   `mash_win.wav`: *Search Keywords:* `explosion magic`, `thunder crack`, `final blow impact`.

### 4. Regreso a Casa (`Scenes/ReturnHome.tscn`)
**Ambiente:** Victoria, alivio, paz.

*   **Música:** `bgm_victory.ogg`
    *   *Search Keywords:* `victory fanfare rpg`, `mission accomplished orchestral`, `peaceful morning music`.
*   **SFX:**
    *   `sfx_birds_morning.wav`: *Search Keywords:* `morning birds chirping`, `forest dawn ambience`.

### 5. Reintentar (`Scenes/TryAgain.tscn`)
**Ambiente:** Derrota, esperanza.

*   **Música:** `bgm_gameover.ogg`
    *   *Search Keywords:* `game over sad piano`, `defeat orchestral`, `dark drone sad`.
*   **SFX:**
    *   `ui_retry_click.wav`: *Search Keywords:* `ui button click`, `menu select`.
