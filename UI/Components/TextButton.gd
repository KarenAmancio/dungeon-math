# TextButton.gd
# Botão "só a palavra": sem caixa, e quando o mouse passa (ou o botão está focado) a palavra
# acende (cor do tema) e aparece um ">" pixelado antes dela. Os estilos vêm do tema (Button).

class_name TextButton
extends Button

const MARK := [
	"XX...",
	".XX..",
	"..XX.",
	"...XX",
	"..XX.",
	".XX..",
	"XX...",
]
const MARK_GAP := 4.0           # espaço entre o ">" e a palavra

var show_mark: bool = true      # false: só acende a cor (botões de ícone, como "?" e "II")


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)


func _draw() -> void:
	if not show_mark or disabled or not is_hovered() or text == "":
		return
	var font := get_theme_font("font")
	var font_size := get_theme_font_size("font_size")
	var text_w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var rows := MARK.size()
	var x := floorf((size.x - text_w) / 2.0) - MARK_GAP - 4.0
	var y := floorf((size.y - rows) / 2.0)
	var color := get_theme_color("font_hover_color")
	for r in rows:
		var line: String = MARK[r]
		for c in line.length():
			if line[c] == "X":
				draw_rect(Rect2(x + c, y + r, 1, 1), color)
