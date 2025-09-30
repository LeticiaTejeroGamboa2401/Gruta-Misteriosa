---
applyTo: '**'
---
# Instrucciones GitHub Copilot - Batalla Final contra el Huaychivo

## Contexto del Proyecto

### Información del Juego
- **Tipo**: Juego educativo 2D para niños de primaria (6-12 años)
- **Motor**: Godot 4.x
- **Lenguaje**: GDScript exclusivamente
- **Temática**: Mitología maya de Yucatán (Huaychivo)
- **Objetivo Educativo**: Comprensión lectora y matemática básica
- **Escena Actual**: `final_battle.tscn` - Batalla final contra el Huaychivo

### Variables Globales del Proyecto
```gdscript
# Global.gd contiene:
Global.selected_weapon = "weapon_a" | "weapon_b" | "weapon_c"
Global.selected_character_scene = preload("path/to/character.tscn")
Global.selected_character_name = "NombrePersonaje"
```

### Sistema de Armas (Crítico para la Lógica)
- **weapon_a**: Arma inútil - No causa daño → Derrota automática
- **weapon_b**: Arma parcial - Solo mata perros → Muere contra Huaychivo
- **weapon_c**: Arma correcta - Mata todo → Victoria completa

## Tareas Específicas que Copilot DEBE hacer:

### 1. Sistema de Combate por Turnos
```gdscript
# Copilot: Implementar sistema de combate que incluya:
# - player_health = 6 (corazones)
# - dogs_alive = [true, true, true] (3 perros)
# - huaychivo_health = 5
# - Turnos: jugador ataca → enemigos contraatacan
# - Cada perro vivo quita 1 vida por turno
# - Huaychivo quita 2 vidas por turno
```

### 2. Sistema de Spawning del Personaje
```gdscript
# Copilot: Crear función para instanciar al personaje desde Global:
# - Usar Global.selected_character_scene.instantiate()
# - Posicionar en $Characters/PlayerSpawnPoint
# - Asignar nombre desde Global.selected_character_name
# - Configurar como hijo de Characters node
```

### 3. Lógica de Armas Condicional
```gdscript
# Copilot: Sistema de daño basado en Global.selected_weapon:
# - weapon_a: 0 daño a todos los enemigos
# - weapon_b: daño normal a perros, 0 daño a huaychivo
# - weapon_c: daño normal a todos los enemigos
# - Incluir función can_damage_enemy(target_type: String) -> bool
```

### 4. Máquina de Estados de Batalla
```gdscript
# Copilot: Enum para fases de batalla:
# DIALOG_INITIAL, FIGHTING_DOGS, FIGHTING_HUAYCHIVO, VICTORY, DEFEAT
# - Función change_phase() que maneja transiciones
# - Solo permitir atacar Huaychivo cuando dogs_alive.count(true) == 0
# - UI buttons activos/inactivos según fase actual
```

### 5. Sistema de Diálogos Educativos
```gdscript
# Copilot: Array de diálogos con estructura:
# {speaker: "HUAYCHIVO", text: "¿Creías que podrías escapar?"}
# - Función show_dialog(dialog_index) 
# - Auto-avance después de 3 segundos
# - Diálogos diferentes según weapon seleccionada
```

### 6. Gestión de UI Dinámica
```gdscript
# Copilot: Actualizar UI en tiempo real:
# - update_health_display() - mostrar corazones
# - update_action_buttons() - habilitar/deshabilitar botones
# - show_enemy_status() - indicar perros vivos/muertos
# - Usar modulate o visible para efectos visuales
```

## Prompts Específicos para el Proyecto

### Para Lógica de Combate:
```gdscript
# Copilot: Crear función attack_dogs() que:
# - Verifique si Global.selected_weapon puede dañar perros
# - Reduzca dogs_alive de 3 a 0 progresivamente
# - Actualice sprites de perros (vivos/muertos)
# - Cambie a fase FIGHTING_HUAYCHIVO cuando todos mueran
# - Incluya animaciones de ataque y efectos de impacto
```

### Para Sistema de Derrota:
```gdscript
# Copilot: Implementar game_over() que:
# - Se active cuando player_health <= 0
# - Muestre mensaje educativo sobre la elección de armas
# - Ofrezca botón "Volver a intentar"
# - Reinicie con get_tree().change_scene_to_file("res://weapon_selection.tscn")
# - Incluya fade out/in para transición suave
```

### Para Sistema de Victoria:
```gdscript
# Copilot: Crear función victory() que:
# - Se active cuando huaychivo_health <= 0
# - Muestre diálogo de celebración culturalmente apropiado
# - Incluya mensaje educativo sobre cultura maya
# - Permita continuar a escena de regreso a casa
# - Guarde progreso en Global para persistencia
```

## Limitaciones y Consideraciones Especiales

### Lo que Copilot NO debe hacer:
1. **Cambiar la mitología maya** - Mantener precisión cultural
2. **Contenido inapropiado** - Solo violencia muy suave (enemigos desaparecen)
3. **Complejidad excesiva** - Código simple para niños de primaria
4. **Romper el flujo educativo** - Cada acción debe tener propósito pedagógico

### Estilo de Código Requerido:
```gdscript
# Copilot: Seguir estas convenciones SIEMPRE:
# - Funciones descriptivas: attack_dogs(), check_victory(), update_ui()
# - Variables claras: player_health, dogs_alive, current_phase
# - Comentarios educativos explicando la lógica maya
# - Señales para eventos importantes: health_changed, enemy_defeated
# - Evitar código complejo - priorizar legibilidad
```

## Comandos de Chat Específicos

### Análisis de Código:
**`@workspace Revisa si mi sistema de armas respeta la lógica educativa del Huaychivo`**

### Debugging Cultural:
**`@workspace Verifica que los diálogos y mecánicas mantengan precisión de la mitología maya yucateca`**

### Optimización Educativa:
**`@workspace Sugiere mejoras para que el combate enseñe mejor estrategia y consecuencias a niños de primaria`**

### Testing de Flujo:
**`@workspace Ayúdame a crear casos de prueba para los 3 tipos de armas y sus resultados esperados`**

## Plantillas de Implementación

### Script Principal de Batalla:
```gdscript
# Copilot: Crear clase main_battle.gd que extienda Node2D:
# - Variables de estado (health, enemies, phase, weapon)
# - Función _ready() para inicializar batalla
# - Funciones de ataque por separado para cada tipo de enemigo
# - Sistema de turnos con yield/await para timing
# - Integración completa con el sistema Global
```

### Sistema de Efectos Visuales:
```gdscript
# Copilot: Implementar feedback visual child-friendly:
# - flash_damage() - parpadeo rojo suave cuando recibe daño
# - enemy_death_effect() - desvanecimiento gradual
# - weapon_glow() - resaltar arma seleccionada
# - victory_particles() - celebración con partículas mayas
# - Todos los efectos deben ser no-violentos y coloridos
```

### Integración con Progreso del Juego:
```gdscript
# Copilot: Sistema de continuidad que:
# - Mantenga coherencia con escenas anteriores
# - Preserve las decisiones del jugador
# - Permita reinicio educativo sin frustración
# - Registre métricas de aprendizaje (intentos, tiempo, estrategias)
# - Prepare transición a escena de regreso a casa
```

## Objetivos de Aprendizaje a Mantener

### Matemáticas:
- Conteo regresivo (vida, enemigos)
- Suma y resta básica (daño, curación)
- Patrones lógicos (si-entonces de armas)

### Comprensión Lectora:
- Diálogos narrativos complejos
- Instrucciones de interfaz
- Mensajes de retroalimentación educativa

### Cultura Regional:
- Respeto por mitología maya auténtica
- Terminología correcta (huaychivo, alux, chechén)
- Valores tradicionales yucatecos

---

## Recordatorio Crítico para Copilot:
**Este es un juego EDUCATIVO para NIÑOS. Cada línea de código debe servir al aprendizaje y mantener la precisión cultural maya. La violencia es simbólica y educativa, nunca gráfica. El fallo debe enseñar, no frustrar.**
