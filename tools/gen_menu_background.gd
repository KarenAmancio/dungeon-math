# gen_menu_background.gd
# Gera Backgrounds/menu_bg.png (640x360, pixel art): um corredor de masmorra decadente em
# PERSPECTIVA, visto do centro. Paredes de tijolo, piso de lajes rachadas com poças, teto com
# vigas de madeira, três suportes de tocha e um vazio escuro no fundo (onde ficam os olhos
# animados). A luz vem das tochas (laranja) e cai com a distância; tudo quantizado com
# dithering ordenado pra manter o look de pixel art. Determinístico (seed fixa).
#
# Rodar:  godot --headless --path . --script res://tools/gen_menu_background.gd
#
# As chamas das tochas NÃO são desenhadas aqui: elas tremem em tempo real (TorchFlame.gd).

extends SceneTree

const W := 640
const H := 360
const OUT := "res://Backgrounds/menu_bg.png"
const SCALE := 320.0                 # mesma escala nos 2 eixos (pixels quadrados)
const VP := Vector2(320, 150)        # ponto de fuga
const HALF_WIDTH := 0.85             # meia largura do corredor
const FLOOR_Y := 0.62                # altura da câmera até o chão
const CEIL_Y := 0.58                 # e até o teto
const Z_MAX := 15.0                  # além disso é o vazio escuro
const LEVELS := 8.0
# tons-base da pedra: claros de propósito, porque a luz do corredor multiplica e escurece tudo
const WALL_MID := Color("#554f49")
const WALL_DARK := Color("#39342f")
const WALL_LIGHT := Color("#6c655d")
const JOINT := Color("#100d0c")
const BAYER: Array[int] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

# suportes de tocha: x (lado), y (altura), z (profundidade)
const TORCHES: Array[Vector3] = [
	Vector3(-HALF_WIDTH, -0.12, 3.3),
	Vector3(HALF_WIDTH, -0.12, 5.6),
	Vector3(-HALF_WIDTH, -0.12, 9.0),
]

var img: Image


func _initialize() -> void:
	img = Image.create(W, H, false, Image.FORMAT_RGBA8)
	for y in H:
		for x in W:
			img.set_pixel(x, y, _shade(x, y))
	for t in TORCHES:
		_draw_bracket(t)
	var err := img.save_png(OUT)
	print("%s: %s" % [OUT, "ok" if err == OK else "ERRO %d" % err])
	quit()


static func _hash(a: int, b: int, c: int) -> float:
	var h := (a * 374761393 + b * 668265263 + c * 1274126177) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h & 0xffff) / 65536.0


func _shade(x: int, y: int) -> Color:
	var u := (x + 0.5 - VP.x) / SCALE
	var v := (y + 0.5 - VP.y) / SCALE

	# qual superfície o raio do pixel acerta primeiro?
	var z := 1e9
	var kind := "void"
	if v > 0.0001 and FLOOR_Y / v < z:
		z = FLOOR_Y / v
		kind = "floor"
	if v < -0.0001 and CEIL_Y / -v < z:
		z = CEIL_Y / -v
		kind = "ceil"
	if absf(u) > 0.0001 and HALF_WIDTH / absf(u) < z:
		z = HALF_WIDTH / absf(u)
		kind = "wall"
	if z > Z_MAX:
		var fade := clampf((z - Z_MAX) / 6.0, 0.0, 1.0)
		return Color(0.03, 0.022, 0.022).lerp(Color(0.012, 0.009, 0.009), fade)

	var world := Vector3(u * z, v * z, z)     # x, y (positivo = pra baixo), z
	var base: Color
	match kind:
		"wall":
			base = _wall_color(world, u < 0.0)
		"floor":
			base = _floor_color(world)
		_:
			base = _ceiling_color(world)

	# luz: UM valor de brilho (ambiente que cai com a distância + luz das tochas), quantizado com
	# dithering ordenado. O tom laranja das tochas é aplicado DEPOIS (não varia o matiz por canal).
	var ambient := pow(clampf(1.6 / (z + 0.9), 0.0, 1.0), 1.4) * 0.36
	var warm := 0.0
	for t in TORCHES:
		var d := (world - t).length()
		warm += exp(-d * d / (2.0 * 1.1 * 1.1))
	warm = minf(warm, 1.3)
	var bright := ambient + warm * 1.2
	var bayer: float = BAYER[(y % 4) * 4 + (x % 4)] / 16.0
	var q := clampf(floorf(bright * LEVELS + bayer) / LEVELS, 0.0, 1.0)
	var lit := base * q
	var warm_frac := warm * 1.25 / maxf(bright, 0.001)
	lit = lit.lerp(Color(lit.r * 1.45, lit.g * 0.88, lit.b * 0.45), clampf(warm_frac, 0.0, 1.0) * 0.85)
	return Color(clampf(lit.r, 0.0, 1.0), clampf(lit.g, 0.0, 1.0), clampf(lit.b, 0.0, 1.0), 1.0)


func _wall_color(p: Vector3, left: bool) -> Color:
	var side := 0 if left else 1
	var row_f := (p.y + CEIL_Y) * 5.5
	var row := int(floor(row_f))
	var fy := row_f - row
	var cz := p.z * 3.2 + (row % 2) * 0.5
	var col := int(floor(cz))
	var fx := cz - col
	if fx < 0.09 or fy < 0.14:
		return JOINT
	var tone := WALL_MID
	var r := _hash(col, row, side)
	if r < 0.32:
		tone = WALL_DARK
	elif r > 0.82:
		tone = WALL_LIGHT
	if _hash(col, row, side + 10) < 0.035:
		tone = Color("#4f2420")                             # tijolo manchado de sangue
	if _hash(int(floor(cz * 3.0)), int(floor(row_f * 3.0)), side + 20) < 0.06:
		tone = tone.darkened(0.35)                          # rachadura / sujeira
	if _hash(col, row, side + 30) < 0.03:
		return Color("#0a0807")                              # tijolo que caiu: buraco escuro
	if fy < 0.28:
		tone = tone.lightened(0.10)                         # luz no topo do tijolo
	return tone


func _floor_color(p: Vector3) -> Color:
	var fx := p.x / 0.5
	var fz := p.z / 0.5
	var tx := int(floor(fx))
	var tz := int(floor(fz))
	var ux := fx - tx
	var uz := fz - tz
	if ux < 0.07 or uz < 0.07:
		return JOINT
	var tone := WALL_MID.darkened(0.08)
	var r := _hash(tx, tz, 50)
	if r < 0.30:
		tone = WALL_DARK
	elif r > 0.85:
		tone = WALL_LIGHT
	if r > 0.5 and r < 0.56:
		tone = Color("#202a31")                             # poça escura
	if _hash(tx, tz, 60) < 0.12 and (ux + uz) > 1.1:
		tone = tone.darkened(0.4)                           # laje rachada num canto
	return tone


func _ceiling_color(p: Vector3) -> Color:
	var beam := fposmod(p.z / 1.6, 1.0)
	if beam < 0.17:
		return Color("#3a2414").lightened(0.08 if beam < 0.04 else 0.0)   # viga de madeira
	var tone := WALL_DARK
	if _hash(int(floor(p.x * 3.0)), int(floor(p.z * 3.0)), 70) < 0.2:
		tone = WALL_MID
	return tone


# Suporte de metal da tocha na parede (a chama anima por código).
func _draw_bracket(t: Vector3) -> void:
	var sx := VP.x + (t.x / t.z) * SCALE
	var sy := VP.y + (t.y / t.z) * SCALE
	var k := 5.5 / t.z
	var iron := Color("#2a2420")
	var rim := Color("#4a4038")
	_rect(sx - 1.2 * k, sy, 2.4 * k, 6.0 * k, iron)                 # haste
	_rect(sx - 2.6 * k, sy - 0.5 * k, 5.2 * k, 2.0 * k, rim)         # copo
	_rect(sx - 2.6 * k, sy + 1.2 * k, 5.2 * k, 0.8 * k, iron)
	_rect(sx - 0.8 * k, sy - 2.2 * k, 1.6 * k, 2.0 * k, Color("#3a1e0c"))   # cabo de pano queimado


func _rect(x: float, y: float, w: float, h: float, c: Color) -> void:
	for j in range(int(roundf(y)), int(roundf(y + maxf(h, 1.0)))):
		for i in range(int(roundf(x)), int(roundf(x + maxf(w, 1.0)))):
			if i >= 0 and j >= 0 and i < W and j < H:
				img.set_pixel(i, j, c)
