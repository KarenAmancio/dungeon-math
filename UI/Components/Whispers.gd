# Whispers.gd
# Sussurros em texto fraquinho nas paredes: frases e contas soltas que aparecem e somem devagar
# (em níveis de transparência, sem suavização). Só ambiente, não atrapalha a leitura do menu.

class_name Whispers
extends Control

const PHRASES: Array[String] = [
	"2 + 2 = ?", "×(-1)", "-5", "não erre a conta", "soma", "+3 ×2 -1 = ?",
	"o Gribnok espera", "quanto é 7 × 8?", "...", "conte de novo", "−1", "×10",
	"defenda-se", "o total...", "12 - 15 = ?", "ele está contando",
]
const LEVELS: Array[float] = [0.0, 0.08, 0.16, 0.24, 0.3]
const STEP := 0.35
# onde os sussurros podem aparecer (as paredes, longe do logo e da janela)
const ZONES: Array[Rect2] = [Rect2(14, 70, 150, 230), Rect2(486, 70, 140, 230)]

var _items: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 7:
		var label := Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_color_override("font_color", Palette.TEXT_LIGHT)
		label.add_theme_constant_override("shadow_offset_x", 0)
		label.add_theme_constant_override("shadow_offset_y", 0)
		add_child(label)
		_items.append({"label": label, "t": randf() * 8.0, "life": randf_range(5.0, 9.0)})
		_respawn(_items[i], false)


func _process(delta: float) -> void:
	for it in _items:
		it["t"] += delta
		var life: float = it["life"]
		if it["t"] >= life:
			_respawn(it, true)
			continue
		# sobe e desce em degraus: 0 -> max -> 0 ao longo da vida
		var phase := float(it["t"]) / life
		var tri := 1.0 - absf(phase * 2.0 - 1.0)
		var step := int(floor(tri * (LEVELS.size() - 1) + 0.5))
		var label: Label = it["label"]
		label.modulate.a = LEVELS[step]


func _respawn(it: Dictionary, reset_time: bool) -> void:
	var zone: Rect2 = ZONES[randi() % ZONES.size()]
	var label: Label = it["label"]
	label.text = PHRASES[randi() % PHRASES.size()]
	label.position = Vector2(roundf(zone.position.x + randf() * zone.size.x * 0.7), roundf(zone.position.y + randf() * zone.size.y))
	label.modulate.a = 0.0
	if reset_time:
		it["t"] = 0.0
	it["life"] = randf_range(5.0, 9.0)
