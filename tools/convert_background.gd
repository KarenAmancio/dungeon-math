# convert_background.gd
# Transforma uma imagem gerada (qualquer tamanho) em fundo "pixel antigo": corta para 16:9,
# reduz para 640x360 e reduz as cores para uma paleta curta (k-means) com um dither leve.
# Menos cores + resolução baixa = a cara de jogo antigo quando a tela cresce (x3).
#
# Rodar:
#   godot --headless --path . --script res://tools/convert_background.gd -- <entrada.png> <saida.png> [cores] [apagar] [laranja]
# "apagar" (opcional) = retângulos "x,y,l,a;x,y,l,a" (em pixels de 640x360) de onde sai um texto/logo
# desenhado na imagem: só os pixels CLAROS do texto (e 3 px de folga em volta) viram a cor mais escura
# da paleta... na verdade, para não sobrar um "quadrado" chapado, cada pixel apagado vira um pixel
# sorteado da faixa de fundo logo ACIMA do retângulo (mesma textura/dither do vazio em volta).
# "laranja" (opcional) = retângulos de onde sai um texto LARANJA desenhado sobre o chão: os pixels
# laranja viram pixels sorteados do chão logo acima do texto.
# Ex.:
#   godot --headless --path . --script res://tools/convert_background.gd -- "reference/fundo da mesa.png" Backgrounds/battle_bg.png 32

extends SceneTree

const OUT_W := 640
const OUT_H := 360
const BAYER: Array[int] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
const DITHER := 5.0             # força do dither (em níveis de 0 a 255)
const ITERATIONS := 10


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("uso: -- <entrada> <saida> [cores]")
		quit(1)
		return
	var colors := int(args[2]) if args.size() > 2 else 32
	var img := Image.load_from_file(ProjectSettings.globalize_path(args[0]) if args[0].begins_with("res://") else args[0])
	if img == null:
		push_error("não consegui abrir " + args[0])
		quit(1)
		return
	img.convert(Image.FORMAT_RGBA8)

	# corta pro formato 16:9 (tira o excesso dos lados ou de cima/baixo, do centro)
	var target_ratio := float(OUT_W) / float(OUT_H)
	var w := img.get_width()
	var h := img.get_height()
	var crop_w := w
	var crop_h := h
	if float(w) / float(h) > target_ratio:
		crop_w = int(round(h * target_ratio))
	else:
		crop_h = int(round(w / target_ratio))
	var region := Rect2i((w - crop_w) / 2, (h - crop_h) / 2, crop_w, crop_h)
	img = img.get_region(region)
	img.resize(OUT_W, OUT_H, Image.INTERPOLATE_LANCZOS)

	var palette := _kmeans(img, colors)
	var out := Image.create(OUT_W, OUT_H, false, Image.FORMAT_RGBA8)
	for y in OUT_H:
		for x in OUT_W:
			var c := img.get_pixel(x, y)
			var bias := (BAYER[(y % 4) * 4 + (x % 4)] / 16.0 - 0.5) * DITHER / 255.0
			var biased := Color(c.r + bias, c.g + bias, c.b + bias)
			out.set_pixel(x, y, palette[_nearest(palette, biased)])
	if args.size() > 3 and args[3] != "":
		var darkest := palette[0]
		for c in palette:
			if c.get_luminance() < darkest.get_luminance():
				darkest = c
		for spec in args[3].split(";"):
			var v := spec.split(",")
			if v.size() == 4:
				_erase_text(out, Rect2i(int(v[0]), int(v[1]), int(v[2]), int(v[3])), darkest)
	if args.size() > 4 and args[4] != "":
		for spec in args[4].split(";"):
			var v := spec.split(",")
			if v.size() == 4:
				_erase_orange(out, Rect2i(int(v[0]), int(v[1]), int(v[2]), int(v[3])))
	var err := out.save_png(args[1])
	print("%s: %s (%d cores, %dx%d)" % [args[1], "ok" if err == OK else "ERRO %d" % err, palette.size(), OUT_W, OUT_H])
	quit()


const ERASE_LUMINANCE := 0.14     # acima disso conta como pixel do texto
const ERASE_MARGIN := 3


func _erase_text(img: Image, rect: Rect2i, fill: Color) -> void:
	# faixa de referência: 14 px de fundo logo acima do retângulo (sem texto)
	var ref_top := maxi(rect.position.y - 14, 0)
	var ref_h := maxi(rect.position.y - 2 - ref_top, 1)
	var src := img.duplicate() as Image
	var hits: Array[Vector2i] = []
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if img.get_pixel(x, y).get_luminance() > ERASE_LUMINANCE:
				hits.append(Vector2i(x, y))
	for p in hits:
		for dy in range(-ERASE_MARGIN, ERASE_MARGIN + 1):
			for dx in range(-ERASE_MARGIN, ERASE_MARGIN + 1):
				var q := p + Vector2i(dx, dy)
				if rect.has_point(q):
					var h := (q.x * 73856093) ^ (q.y * 19349663)
					var rx := rect.position.x + posmod(h >> 3, rect.size.x)
					var ry := ref_top + posmod(h >> 11, ref_h)
					img.set_pixel(q.x, q.y, src.get_pixel(rx, ry))


func _is_orange(c: Color) -> bool:
	return c.r > 0.45 and c.r - c.b > 0.28


func _erase_orange(img: Image, rect: Rect2i) -> void:
	var src := img.duplicate() as Image
	var mask := {}
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if _is_orange(src.get_pixel(x, y)):
				for dy in range(-2, 3):
					for dx in range(-2, 3):
						mask[Vector2i(x + dx, y + dy)] = true
	# cada pixel apagado vira um pixel sorteado de uma faixa de chão logo ACIMA do texto: o chão
	# fica com a mesma textura, sem sobrar linhas copiadas
	var ref_top := rect.position.y - 14
	var ref_h := 12
	for key in mask:
		var pt: Vector2i = key
		var h: int = (pt.x * 73856093) ^ (pt.y * 19349663)
		var rx: int = rect.position.x + posmod(h >> 3, rect.size.x)
		var ry: int = ref_top + posmod(h >> 11, ref_h)
		img.set_pixel(pt.x, pt.y, src.get_pixel(rx, ry))


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


# Paleta por k-means numa amostra de pixels (a cada 3 pixels em x e y).
func _kmeans(img: Image, k: int) -> Array[Color]:
	var samples: Array[Color] = []
	for y in range(0, img.get_height(), 3):
		for x in range(0, img.get_width(), 3):
			samples.append(img.get_pixel(x, y))
	# centros iniciais espalhados pela amostra, depois de ordenar por luminância
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
