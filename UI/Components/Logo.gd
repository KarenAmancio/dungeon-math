# Logo.gd
# Logo "Dungeon Math" em pixel art: letras em branco sujo com um toque rosa, contorno escuro fino e um
# BRILHO roxo/rosa em volta que pulsa devagar (em degraus, ~10 quadros por segundo, pra manter o
# ritmo "retrô"). A fonte (Sorcery Code) vem do tema, tipo "LabelLogo".

class_name Logo
extends Control

const TEXT := "Dungeon Math"
const FONT_SIZE := 40
const TICK := 0.1                # segundos por passo da pulsação
const PULSE_SPEED := 2.2         # velocidade da pulsação do brilho (rad/s)
const DIRTY_WHITE := Color("#dcd3c2")   # branco sujo (cor base das letras)
const PINK := Color("#e68fd2")          # rosa que tinge as primeiras letras
const GLOW_PINK := Color("#d95fc0")
const GLOW_PURPLE := Color("#8a35c9")
const OUTLINE := Color("#150a1c")       # contorno escuro (levemente roxo)

var _font: Font
var _time: float = 0.0
var _acc: float = 0.0
var _level: int = 2              # 0..3: força atual do brilho
var _text_x: float = 0.0
var _baseline: float = 0.0


func _init() -> void:
	custom_minimum_size = Vector2(420, 96)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	var theme := ThemeDB.get_project_theme()
	if theme != null and theme.has_font("font", "LabelLogo"):
		_font = theme.get_font("font", "LabelLogo")
	else:
		_font = ThemeDB.fallback_font
	_layout()
	resized.connect(_layout)


func _layout() -> void:
	var total := _font.get_string_size(TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	_text_x = roundf((size.x - total) / 2.0)
	_baseline = roundf(size.y * 0.66)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	_acc += delta
	if _acc < TICK:
		return
	_acc = 0.0
	var level := int(round((sin(_time * PULSE_SPEED) * 0.5 + 0.5) * 3.0))
	if level != _level:
		_level = level
		queue_redraw()


func _draw() -> void:
	if _font == null:
		return
	var pos := Vector2(_text_x, _baseline)
	var strength := 0.55 + 0.2 * _level        # 0.55 .. 1.15

	# brilho: contornos grossos e transparentes, do mais largo (roxo) ao mais perto (rosa)
	draw_string_outline(_font, pos, TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 14, Color(GLOW_PURPLE, 0.10 * strength))
	draw_string_outline(_font, pos, TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 10, Color(GLOW_PURPLE, 0.18 * strength))
	draw_string_outline(_font, pos, TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 7, Color(GLOW_PINK, 0.26 * strength))
	draw_string_outline(_font, pos, TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 4, Color(GLOW_PINK, 0.42 * strength))
	# contorno escuro FINO (1 px): um contorno grosso enche os buraquinhos das letras (o do "M")
	# de preto e parece um bloco escuro dentro do título
	draw_string_outline(_font, pos, TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 1, OUTLINE)

	# letras: branco sujo, mais rosadas no começo da palavra (letra a letra)
	var x := pos.x
	for i in TEXT.length():
		var ch := TEXT[i]
		var t := float(i) / float(TEXT.length() - 1)
		var color := PINK.lerp(DIRTY_WHITE, clampf(t * 1.6, 0.0, 1.0))
		draw_string(_font, Vector2(x, pos.y), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)
		x += _font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
