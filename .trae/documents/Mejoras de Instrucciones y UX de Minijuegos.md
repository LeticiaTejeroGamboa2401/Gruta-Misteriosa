## Objetivos
- Hacer textos más grandes, claros y centrados, con autowrap.
- Destacar el botón “Comenzar” con tamaño y estilo visibles.
- Centrar la UX de los minijuegos en pantalla, independientemente del tipo de nodo.
- Mostrar tips de fallo llamativos tras terminar minijuegos sin éxito.

## Cambios en Tutorial Overlay
- Reemplazar layout de `Panel` por un `VBoxContainer` centrado dentro del panel, con:
  - Título 32–36pt, color alto contraste, centrado.
  - Descripción 22–24pt, `autowrap` por palabra y márgenes.
  - Botón “Comenzar” grande (`custom_minimum_size`, 260×64), estilo de fondo con `StyleBoxFlat` y color llamativo; fuente 24pt.
- Fondo semitransparente (`ColorRect`) detrás del panel para enfocar.
- Aplicar los mismos cambios a `TimedHitTutorial` y `SimonTutorial`.
- Ubicación y bloque de input: `mouse_filter=STOP` en overlay.

## Centrado del Minijuego
- Tras instanciar `active_minigame` (Scripts/pelea_final.gd:835–846):
  - Si es `Control`: anchors a cubrir pantalla y centrar el contenido.
  - Si es `Node2D`: posicionar en el centro del viewport (`get_viewport().get_visible_rect().size * 0.5`).

## Tips de Fallo
- Nuevo `fail_tip_panel` centrado con estilo rojo (StyleBoxFlat), texto 26pt y autowrap.
- Mostrar cuando `_success == false` en `_on_minigame_finished` (Scripts/pelea_final.gd:861–917), con duración 2.2s y fade in/out.
- Mensajes específicos:
  - TimedHit: “Presiona cuando el indicador esté en la zona marcada; apunta a 3 aciertos”.
  - Simon: “Observa la secuencia completa y repítela en el mismo orden”.

## Ajustes de Texto
- Incrementar tamaños de fuente y centrar en tutorial overlay existente (Scripts/pelea_final.gd:1494–1557): usar `add_theme_font_size_override` y `horizontal_alignment`.
- Activar `autowrap` en descripciones y definir anchos máximos para evitar desbordes.

## Validación
- Probar flujo desde selección de armas hasta combate:
  - Verificar overlays y botón visible, centrado y grande.
  - Confirmar minijuegos aparecen centrados.
  - Al fallar un minijuego, se muestran tips llamativos.

¿Apruebas que implemente estos cambios y estilos para mejorar la claridad y visibilidad de las instrucciones y UX de minijuegos?