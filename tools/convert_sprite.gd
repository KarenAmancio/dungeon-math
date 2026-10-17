# convert_sprite.gd
# Transforma uma imagem gerada (carta, ícone...) em sprite "pixel antigo": corta o fundo
# transparente, reduz para L x A pixels e reduz as cores para uma paleta curta (k-means).
# Bordas sem suavização (cada pixel ou existe ou não). Pouca resolução + poucas cores = cara
# de jogo antigo quando a tela cresce (x3).
#
# Rodar:
#   godot --headless --path . --script res://tools/convert_sprite.gd -- <entrada.png> <saida.png> <largura> <altura> [cores] [recorte] [ajuste]
# largura e altura = 0: mantém a QUALIDADE ORIGINAL (só recorta/tira o fundo, sem reduzir nem
# limitar as cores); o jogo reduz na hora de desenhar.
# "recorte" (opcional) = "x,y,l,a" na imagem de entrada, aplicado ANTES de cortar o fundo.
# "ajuste" (opcional):
#   "roxo" = troca as cores pelo roxo do baralho da referência (ameixa escuro -> dourado
#            acinzentado), seguindo só a luminosidade; o desenho continua o mesmo.
#   "bege" = tira o tom rosado do papel (mais bege/amarelado); as pedrinhas azuis ficam como estão.
#   "fundo" = tira o fundo liso (a cor do canto do recorte) e a sombra, sem mexer nas cores da arte.
# Ex.:
#   godot --headless --path . --script res://tools/convert_sprite.gd -- frente.png Resources/Cards/card_face.png 38 58 20 "" bege

extends SceneTree

const ALPHA_CUT := 0.5
const ITERATIONS := 12

# Rampa "roxo": do escuro ao claro, como o baralho da foto de referência.
const RAMP_PURPLE: Array = [
	[0.00, Color("#0e0a12")], [0.18, Color("#1d1626")], [0.36, Color("#2d2235")],
	[0.50, Color("#46364f")], [0.64, Color("#6b5470")], [0.78, Color("#a08a62")],
	[0.90, Color("#c9ae7c")], [1.00, Color("#e6d2a0")],
]
# "bege": quanto o matiz anda pro amarelo e quanto a saturação cai
const BEIGE_HUE_SHIFT := 0.018
const BEIGE_SATURATION := 0.7


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 4:
		push_error("uso: -- <entrada> <saida> <largura> <altura> [cores] [recorte] [ajuste]")
		quit(1)
		return
	var out_w := int(args[2])
	var out_h := int(args[3])
	var colors := int(args[4]) if args.size() > 4 else 16
	var img := Image.load_from_file(args[0])
	if img == null:
		push_error("não consegui abrir " + args[0])
		quit(1)
		return
	img.convert(Image.FORMAT_RGBA8)
	if args.size() > 5 and args[5] != "":
		var v := args[5].split(",")
		img = img.get_region(Rect2i(int(v[0]), int(v[1]), int(v[2]), int(v[3])))

	var adjust := args[6] if args.size() > 6 else ""
	if adjust == "fundo":
		_key_background(img)

	# corta o fundo transparente
	var used := _opaque_bounds(img)
	img = img.get_region(used)
	if out_w == 0 or out_h == 0:
		var err0 := img.save_png(args[1])
		print("%s: %s (original, %dx%d)" % [args[1], "ok" if err0 == OK else "ERRO %d" % err0, img.get_width(), img.get_height()])
		quit()
		return
	img.resize(out_w, out_h, Image.INTERPOLATE_LANCZOS)

	if adjust == "roxo":
		_apply_ramp(img)
	elif adjust == "bege":
		_apply_beige(img)

	# pixels (opacos) pra paleta; alpha vira tudo-ou-nada
	var pixels: Array[Color] = []
	for y in out_h:
		for x in out_w:
			var c := img.get_pixel(x, y)
			if c.a >= ALPHA_CUT:
				pixels.append(c)
	var palette := _kmeans(pixels, colors)
	var out := Image.create(out_w, out_h, false, Image.FORMAT_RGBA8)
	for y in out_h:
		for x in out_w:
			var c := img.get_pixel(x, y)
			if c.a >= ALPHA_CUT:
				out.set_pixel(x, y, palette[_nearest(palette, c)])
			else:
				out.set_pixel(x, y, Color(0, 0, 0, 0))
	var err := out.save_png(args[1])
	print("%s: %s (%d cores, %dx%d)" % [args[1], "ok" if err == OK else "ERRO %d" % err, palette.size(), out_w, out_h])
	quit()


# Tira o fundo liso: a cor do canto vira transparente, a partir das bordas (só o que está ligado a
# elas, então o miolo da arte nunca é apagado). A sombra, que é só um fundo mais escuro, vai junto.
const KEY_TOLERANCE := 0.30        # soma das diferenças de R, G e B


func _key_background(img: Image) -> void:
	var bg := img.get_pixel(0, 0)
	var w := img.get_width()
	var h := img.get_height()
	var seen := {}
	var stack: Array[Vector2i] = []
	for x in w:
		stack.append(Vector2i(x, 0))
		stack.append(Vector2i(x, h - 1))
	for y in h:
		stack.append(Vector2i(0, y))
		stack.append(Vector2i(w - 1, y))
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h or seen.has(p):
			continue
		var c := img.get_pixel(p.x, p.y)
		if absf(c.r - bg.r) + absf(c.g - bg.g) + absf(c.b - bg.b) > KEY_TOLERANCE:
			continue
		seen[p] = true
		img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
		stack.append(p + Vector2i(1, 0))
		stack.append(p + Vector2i(-1, 0))
		stack.append(p + Vector2i(0, 1))
		stack.append(p + Vector2i(0, -1))


func _apply_ramp(img: Image) -> void:
	# estica a luminosidade (2% a 98% dos pixels opacos) pra usar a rampa inteira
	var lums: Array[float] = []
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a >= ALPHA_CUT:
				lums.append(c.get_luminance())
	lums.sort()
	var lo: float = lums[int(lums.size() * 0.02)]
	var hi: float = lums[int(lums.size() * 0.98)]
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a >= ALPHA_CUT:
				var t := clampf((c.get_luminance() - lo) / maxf(hi - lo, 0.0001), 0.0, 1.0)
				var mapped := _ramp_color(t)
				img.set_pixel(x, y, Color(mapped.r, mapped.g, mapped.b, c.a))


func _ramp_color(t: float) -> Color:
	for i in range(1, RAMP_PURPLE.size()):
		var a: Array = RAMP_PURPLE[i - 1]
		var b: Array = RAMP_PURPLE[i]
		if t <= float(b[0]):
			var k := (t - float(a[0])) / (float(b[0]) - float(a[0]))
			return (a[1] as Color).lerp(b[1] as Color, k)
	return RAMP_PURPLE[RAMP_PURPLE.size() - 1][1]


# Tira o tom rosado: matiz um pouco pro amarelo e menos saturação (só no que não é azul).
func _apply_beige(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < ALPHA_CUT or (c.b > c.r + 0.1 and c.b > c.g):
				continue                                  # as pedrinhas azuis ficam
			var h := c.h + BEIGE_HUE_SHIFT
			img.set_pixel(x, y, Color.from_hsv(h, c.s * BEIGE_SATURATION, c.v, c.a))


func _opaque_bounds(img: Image) -> Rect2i:
	var min_x := img.get_width()
	var min_y := img.get_height()
	var max_x := -1
	var max_y := -1
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a >= ALPHA_CUT:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


func _nearest(palette: Array[Color], c: Color) -> int:
	var best := 0
	var best_d := 1e9
	for i in palette.size():
		var p := palette[i]
		var d := (p.r - c.r) * (p.r - c.r) + (p.g - c.g) * (p.g - c.g) + (p.b - c.b) * (p.b - c.b)
		if d < best_d:
			best_d = d
			best = i
	return best


func _kmeans(samples: Array[Color], k: int) -> Array[Color]:
	var sorted := samples.duplicate()
	sorted.sort_custom(func(a: Color, b: Color) -> bool: return a.get_luminance() < b.get_luminance())
	var centers: Array[Color] = []
	for i in k:
		centers.append(sorted[int((i + 0.5) * sorted.size() / k)])
	for it in ITERATIONS:
		var sums: Array[Vector3] = []
		var counts: Array[int] = []
		for i in k:
			sums.append(Vector3.ZERO)
			counts.append(0)
		for s in samples:
			var n := _nearest(centers, s)
			sums[n] += Vector3(s.r, s.g, s.b)
			counts[n] += 1
		for i in k:
			if counts[i] > 0:
				var m := sums[i] / counts[i]
				centers[i] = Color(m.x, m.y, m.z)
	return centers
