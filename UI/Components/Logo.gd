# Logo.gd
# Logo "Dungeon Math" em pixel art: fonte gótica (Jacquard 24) em vermelho-sangue escuro, com
# contorno, sombra deslocada e PINGOS de sangue que escorrem das letras (animados em passos,
# ~8 quadros por segundo, pra manter o ritmo "retrô"). A fonte vem do tema (tipo "LabelLogo").

class_name Logo
extends Control

const TEXT := "Dungeon Math"
const FONT_SIZE := 48
const TICK := 0.125            # segundos por passo da animação
const DRIP_COUNT := 8
const GROW_STEPS := 12         # quanto o pingo cresce antes de soltar
const FALL_STEPS := 9          # quanto a gota cai
const BLOOD := Color("#8a1616")
const BLOOD_DARK := Color("#4a0b0b")
const BLOOD_HI := Color("#c23a2e")

var _font: Font
var _acc: float = 0.0
var _drips: Array[Dictionary] = []
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


# Calcula onde o texto fica e de qual letra cada pingo sai.
func _layout() -> void:
	var total := _font.get_string_size(TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	_text_x = roundf((size.x - total) / 2.0)
	_baseline = roundf(size.y * 0.66)
	_drips.clear()
	var letters: Array[int] = []
	for i in TEXT.length():
		if TEXT[i] != " ":
			letters.append(i)
	letters.shuffle()
	for n in mini(DRIP_COUNT, letters.size()):
		var idx := letters[n]
		var before := _font.get_string_size(TEXT.substr(0, idx), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		var width := _font.get_string_size(TEXT[idx], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		_drips.append({
			"x": roundf(_text_x + before + width * randf_range(0.3, 0.7)),
			"age": randi() % (GROW_STEPS + FALL_STEPS + 10),
			"wait": GROW_STEPS + FALL_STEPS + randi_range(4, 18),
			"max_len": randi_range(7, 14),
		})
	queue_redraw()


func _process(delta: float) -> void:
	_acc += delta
	if _acc < TICK:
		return
	_acc = 0.0
	for d in _drips:
		d["age"] = (d["age"] + 1) % d["wait"]
	queue_redraw()


func _draw() -> void:
	if _font == null:
		return
	var pos := Vector2(_text_x, _baseline)
	# sombra deslocada, contorno grosso e duas camadas de vermelho (efeito de volume)
	draw_string(_font, pos + Vector2(4, 4), TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(0, 0, 0, 0.85))
	draw_string_outline(_font, pos, TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 4, Palette.BORDER_DARK)
	draw_string(_font, pos + Vector2(0, 2), TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, BLOOD_DARK)
	draw_string(_font, pos, TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, BLOOD)

	# pingos: crescem a partir da base da letra, soltam uma gota que cai e somem
	for d in _drips:
		var age: int = d["age"]
		var x: float = d["x"]
		var y0 := _baseline - 3.0
		var len_now := mini(age, int(d["max_len"]))
		if age <= GROW_STEPS:
			draw_rect(Rect2(x, y0, 2, len_now), BLOOD)
			draw_rect(Rect2(x, y0 + len_now - 1, 2, 2), BLOOD_HI)       # ponta brilhando
		elif age <= GROW_STEPS + FALL_STEPS:
			var fall := age - GROW_STEPS
			draw_rect(Rect2(x, y0, 2, int(d["max_len"])), BLOOD)       # fio que sobra na letra
			var drop_y := y0 + int(d["max_len"]) + fall * 2
			draw_rect(Rect2(x, drop_y, 2, 3), BLOOD)                   # gota caindo
			draw_rect(Rect2(x, drop_y, 1, 1), BLOOD_HI)
