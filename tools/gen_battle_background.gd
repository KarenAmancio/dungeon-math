# gen_battle_background.gd
# Gera Backgrounds/battle_bg.png (640x360, pixel art) por código, inspirado em reference/:
# parede de blocos de pedra, mesa octogonal de pedras irregulares com moldura,
# moedas, caveiras, ossos, sangue, espada e vinheta com dithering.
# Determinístico (seed fixa): rodar de novo gera exatamente a mesma imagem.
#
# Rodar:  godot --headless --path . --script res://tools/gen_battle_background.gd
#
# Quando existir o background real, é só trocar o PNG usado em BattleUI.BACKGROUND_PATH.

extends SceneTree

const W := 640
const H := 360
const OUT := "res://Backgrounds/battle_bg.png"

# Mesa octogonal (chanfro nos cantos)
const T_X0 := 98
const T_Y0 := 56
const T_X1 := 542
const T_Y1 := 300
const T_CHAMFER := 34
const RIM := 5
const CENTER := Vector2(320, 178)

const SKULL: Array[String] = [
	"...XXXXXX...",
	"..XXXXXXXX..",
	".XXXXXXXXXX.",
	".XXXXXXXXXXs",
	".XOOXXXXOOXs",
	".XOOXXXXOOXs",
	".XXXXOOXXXXs",
	"..XXXXXXXXs.",
	"...XXXXXXs..",
	"...XsXsXs...",
	"...XXXXXs...",
]
const COIN: Array[String] = [
	".GGG.",
	"GHGGg",
	"GGGGg",
	"GGGgg",
	".ggg.",
]
const BONES: Array[String] = [
	"X.......X",
	"XX.....XX",
	".XXXXXXX.",
	"XX.....XX",
	"X.......X",
]

var img: Image
var rng := RandomNumberGenerator.new()


func _initialize() -> void:
	rng.seed = 20261006
	img = Image.create(W, H, false, Image.FORMAT_RGBA8)
	_wall()
	_table()
	_decor()
	_vignette()
	var err := img.save_png(OUT)
	print("%s: %s" % [OUT, "ok" if err == OK else "ERRO %d" % err])
	quit()


# ---------------------------------------------------------------- utilidades
func _px(x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < W and y < H:
		img.set_pixel(x, y, c)


func _rect(x: int, y: int, w: int, h: int, c: Color) -> void:
	for j in h:
		for i in w:
			_px(x + i, y + j, c)


func _blit(grid: Array[String], colors: Dictionary, ox: int, oy: int) -> void:
	for j in grid.size():
		var row: String = grid[j]
		for i in row.length():
			var ch := row[i]
			if ch != "." and colors.has(ch):
				_px(ox + i, oy + j, colors[ch])


func _in_oct(x: int, y: int, x0: int, y0: int, x1: int, y1: int, c: int) -> bool:
	if x < x0 or x > x1 or y < y0 or y > y1:
		return false
	return (x - x0) + (y - y0) >= c and (x1 - x) + (y - y0) >= c \
			and (x - x0) + (y1 - y) >= c and (x1 - x) + (y1 - y) >= c


# ---------------------------------------------------------------- parede
func _wall() -> void:
	img.fill(Palette.MORTAR)
	var y := 0
	while y < H:
		var h := rng.randi_range(10, 13)
		var x := -rng.randi_range(0, 20)
		while x < W:
			var w := rng.randi_range(20, 38)
			_stone_block(x, y, w, h)
			x += w
		y += h


func _stone_block(x: int, y: int, w: int, h: int) -> void:
	var r := rng.randf()
	var base: Color = Palette.STONE_DARK
	if r > 0.85:
		base = Palette.STONE_LIGHT
	elif r > 0.45:
		base = Palette.STONE_MID
	for j in range(1, h):
		for i in range(1, w):
			var c := base
			var n := rng.randf()
			if n < 0.06:
				c = c.darkened(0.25)
			elif n < 0.10:
				c = c.lightened(0.15)
			if j == 1:
				c = c.lightened(0.18)       # luz no topo
			elif i == 1:
				c = c.lightened(0.10)
			elif j == h - 1:
				c = c.darkened(0.30)        # sombra embaixo
			elif i == w - 1:
				c = c.darkened(0.22)
			_px(x + i, y + j, c)


# ---------------------------------------------------------------- mesa de pedras
func _table() -> void:
	var cell := 13
	var gx := ceili(W / float(cell)) + 3
	var gy := ceili(H / float(cell)) + 3
	var pts: Array[Vector2] = []
	for j in gy:
		for i in gx:
			pts.append(Vector2((i - 1) * cell + rng.randf_range(2.0, cell - 2.0), (j - 1) * cell + rng.randf_range(2.0, cell - 2.0)))

	for y in range(T_Y0, T_Y1 + 1):
		for x in range(T_X0, T_X1 + 1):
			if not _in_oct(x, y, T_X0, T_Y0, T_X1, T_Y1, T_CHAMFER):
				continue
			if not _in_oct(x, y, T_X0 + 1, T_Y0 + 1, T_X1 - 1, T_Y1 - 1, T_CHAMFER):
				_px(x, y, Palette.MORTAR)                       # contorno externo da moldura
			elif not _in_oct(x, y, T_X0 + 2, T_Y0 + 2, T_X1 - 2, T_Y1 - 2, T_CHAMFER):
				_px(x, y, Palette.STONE_HI if (x - CENTER.x) + (y - CENTER.y) < 0 else Palette.STONE_LIGHT)
			elif not _in_oct(x, y, T_X0 + RIM - 1, T_Y0 + RIM - 1, T_X1 - RIM + 1, T_Y1 - RIM + 1, T_CHAMFER):
				_px(x, y, Palette.STONE_LIGHT)
			elif not _in_oct(x, y, T_X0 + RIM, T_Y0 + RIM, T_X1 - RIM, T_Y1 - RIM, T_CHAMFER):
				_px(x, y, Palette.MORTAR)                       # sombra interna da moldura
			else:
				_px(x, y, _cobble(x, y, pts, cell, gx))
	_cracks()


# Pedra irregular (Voronoi): fresta escura entre pedras, luz no canto superior esquerdo.
func _cobble(x: int, y: int, pts: Array[Vector2], cell: int, gx: int) -> Color:
	var ci := x / cell + 1
	var cj := y / cell + 1
	var d1 := 1e9
	var d2 := 1e9
	var best := -1
	var p := Vector2(x, y)
	for dj in range(-1, 2):
		for di in range(-1, 2):
			var idx := (cj + dj) * gx + (ci + di)
			var d := p.distance_to(pts[idx])
			if d < d1:
				d2 = d1
				d1 = d
				best = idx
			elif d < d2:
				d2 = d
	var gap := d2 - d1
	if gap < 1.5:
		return Palette.MORTAR
	var h := (best * 2654435761) & 0xFFFF
	var k := h % 100
	var c: Color = Palette.STONE_MID
	if k >= 75:
		c = Palette.STONE_DARK.lightened(0.18)
	elif k >= 40:
		c = Palette.STONE_LIGHT
	if gap < 3.4:
		var side := (pts[best].x - x) + (pts[best].y - y)
		c = c.lightened(0.20) if side > 0.0 else c.darkened(0.28)
	elif rng.randf() < 0.07:
		c = c.darkened(0.18)
	var f := 1.0 - clampf(p.distance_to(CENTER) / 250.0, 0.0, 1.0)
	return c.lightened(0.10 * f)


func _cracks() -> void:
	for n in 7:
		var pos := Vector2(rng.randf_range(T_X0 + 50, T_X1 - 50), rng.randf_range(T_Y0 + 30, T_Y1 - 30))
		var dir := Vector2.from_angle(rng.randf() * TAU)
		for step in rng.randi_range(18, 40):
			if _in_oct(int(pos.x), int(pos.y), T_X0 + RIM + 1, T_Y0 + RIM + 1, T_X1 - RIM - 1, T_Y1 - RIM - 1, T_CHAMFER):
				_px(int(pos.x), int(pos.y), Palette.MORTAR)
			dir = dir.rotated(rng.randf_range(-0.7, 0.7))
			pos += dir


# ---------------------------------------------------------------- decoração
func _decor() -> void:
	# prateleira de pedra sob as velas (as velas são desenhadas por código, em cima dela)
	_rect(6, 68, 54, 3, Palette.STONE_HI)
	_rect(6, 71, 54, 2, Palette.MORTAR)

	var skull := {"X": Palette.BONE, "s": Palette.BONE.darkened(0.35), "O": Palette.BG_DEEP}
	_blit(SKULL, skull, 158, 14)
	_blit(SKULL, skull, 26, 134)
	_blit(SKULL, skull, 128, 322)
	var bones := {"X": Palette.BONE.darkened(0.1)}
	_blit(BONES, bones, 190, 34)
	_blit(BONES, bones, 474, 330)
	_blit(BONES, bones, 70, 214)

	var coin := {"G": Palette.COIN, "H": Palette.FLAME_HI, "g": Palette.COIN_DARK}
	for p in [Vector2(210, 28), Vector2(216, 32), Vector2(207, 33), Vector2(432, 24), Vector2(439, 30),
			Vector2(60, 160), Vector2(66, 165), Vector2(55, 167), Vector2(598, 150), Vector2(591, 156),
			Vector2(108, 332), Vector2(115, 338), Vector2(520, 322), Vector2(526, 328), Vector2(592, 124),
			Vector2(20, 300), Vector2(26, 306), Vector2(300, 338), Vector2(560, 20)]:
		_blit(COIN, coin, int(p.x), int(p.y))

	_sword(12, 232)

	for n in 26:       # pedrinhas soltas
		var x := rng.randi_range(0, W - 4)
		var y := rng.randi_range(0, H - 3)
		if _in_oct(x, y, T_X0 - 4, T_Y0 - 4, T_X1 + 4, T_Y1 + 4, T_CHAMFER):
			continue
		_rect(x, y, rng.randi_range(2, 4), rng.randi_range(2, 3), Palette.STONE_HI.darkened(0.15))
		_px(x, y, Palette.STONE_HI)

	_blood(470, 14, 5)
	_blood(516, 38, 4)
	_blood(444, 322, 6)
	_blood(504, 340, 4)
	_blood(612, 112, 3)


func _sword(x: int, y: int) -> void:
	var steel := Color("#9aa5b0")
	for i in 24:
		_px(x + 6 + i, y - i, steel)
		_px(x + 6 + i, y - i + 1, steel.darkened(0.35))
	for i in 7:                                         # guarda
		_px(x + 2 + i, y + 3 - i + 2 * 0, Palette.COIN)
	for i in 6:                                         # cabo
		_px(x + 2 - i, y + 5 + i, Color("#5a3a22"))
	_px(x - 4, y + 12, Palette.COIN_DARK)


func _blood(cx: int, cy: int, r: int) -> void:
	for j in range(-r, r + 1):
		for i in range(-r, r + 1):
			if i * i + j * j <= r * r and rng.randf() < 0.85:
				_px(cx + i, cy + j, Palette.BLOOD)
	for k in rng.randi_range(2, 4):
		var x := cx + rng.randi_range(-r, r)
		var len := rng.randi_range(3, 9)
		for j in len:
			_px(x, cy + r + j, Palette.BLOOD if j < len - 1 else Palette.BLOOD.darkened(0.3))


# ---------------------------------------------------------------- vinheta com dithering
func _vignette() -> void:
	const BAYER: Array[int] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
	const LEVELS := 8.0
	for y in H:
		for x in W:
			var d := Vector2((x - 320.0) / 340.0, (y - 180.0) / 200.0).length()
			var v := 1.0 - 0.62 * clampf((d - 0.42) / 0.75, 0.0, 1.0)
			var threshold: float = BAYER[(y % 4) * 4 + (x % 4)] / 16.0
			var q := floorf(v * LEVELS + threshold) / LEVELS
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, Color(c.r * q, c.g * q, c.b * q, 1.0))
