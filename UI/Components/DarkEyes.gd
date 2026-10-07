# DarkEyes.gd
# Pares de olhos brilhando na escuridão: aparecem num ponto escuro sorteado, piscam e somem,
# e voltam em outro lugar. Pixels internos; só desenha 2 retângulos por par (leve).

class_name DarkEyes
extends Node2D

# pontos escuros do corredor (vazio do fundo e cantos sem luz)
const SPOTS: Array[Vector2] = [
	Vector2(305, 150), Vector2(334, 152), Vector2(319, 146),
	Vector2(196, 46), Vector2(446, 52), Vector2(34, 214), Vector2(603, 232),
]
const EYE_GAP := 5
const COLORS: Array[Color] = [Color("#d6bd3a"), Color("#c93a26")]

var _eyes: Array[Dictionary] = []


func _ready() -> void:
	for i in 3:
		_eyes.append({"spot": Vector2.ZERO, "state": "hidden", "timer": randf_range(1.0, 5.0), "blink": 0.0, "color": COLORS[0]})
	set_process(true)


func _process(delta: float) -> void:
	var changed := false
	for e in _eyes:
		e["timer"] -= delta
		if e["blink"] > 0.0:
			e["blink"] -= delta
			changed = true
		if e["timer"] > 0.0:
			continue
		changed = true
		if e["state"] == "hidden":
			e["state"] = "open"
			e["spot"] = SPOTS[randi() % SPOTS.size()]
			e["color"] = COLORS[randi() % COLORS.size()]
			e["timer"] = randf_range(2.0, 4.5)
		elif e["state"] == "open":
			if randf() < 0.5:                       # pisca uma vez e continua olhando
				e["blink"] = 0.15
				e["timer"] = randf_range(0.6, 1.4)
				e["state"] = "open2"
			else:
				e["state"] = "hidden"
				e["timer"] = randf_range(2.0, 7.0)
		else:
			e["state"] = "hidden"
			e["timer"] = randf_range(2.0, 7.0)
	if changed:
		queue_redraw()


func _draw() -> void:
	for e in _eyes:
		if e["state"] == "hidden" or e["blink"] > 0.0:
			continue
		var p: Vector2 = e["spot"]
		var c: Color = e["color"]
		for side in [0, 1]:
			var x: float = p.x + side * EYE_GAP
			draw_rect(Rect2(x, p.y, 2, 2), c)
			draw_rect(Rect2(x, p.y, 1, 1), c.lightened(0.5))          # brilho
			draw_rect(Rect2(x - 1, p.y - 1, 4, 4), Color(c.r, c.g, c.b, 0.12))   # halo fraquinho
