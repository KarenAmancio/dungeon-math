# CardArt.gd
# Desenho de cartas por código (sem PNG), compartilhado entre as cartas, o deck e a mão do
# inimigo. Tudo em pixels internos (640x360); quem chama passa o CanvasItem onde desenhar e
# o retângulo da carta.
#
#   draw_face: frente da carta (+4, ×2, ×(-1)...): papel antigo texturizado (fibras, pontinhos,
#              manchas e borda envelhecida, tudo em pixels) com moldura escura e SÓ o número no meio.
#   draw_back: verso (deck e mão do inimigo).
#
# Legibilidade: o tamanho do número é escolhido entre os tamanhos em que a Tiny5 fica nítida
# (30, 20, 10 px): o maior que cabe inteiro dentro da carta, sem nunca quebrar linha.

class_name CardArt
extends RefCounted

const NUMBER_SIZES: Array[int] = [30, 20, 10]
const RING := 2                 # espessura da moldura colorida


# Fonte do projeto (vem do tema, então a troca de fonte continua num ponto só).
static func font() -> Font:
	var theme := ThemeDB.get_project_theme()
	if theme != null and theme.default_font != null:
		return theme.default_font
	return ThemeDB.fallback_font


# Fonte dos números e das palavras das cartas (definida no tema, tipo "CardNumber").
static func number_font() -> Font:
	var theme := ThemeDB.get_project_theme()
	if theme != null and theme.has_font("font", "CardNumber"):
		return theme.get_font("font", "CardNumber")
	return font()


# Maior tamanho de número que cabe em max_width (nunca menor que o último da lista).
static func fit_number_size(text: String, max_width: float) -> int:
	var f := number_font()
	for size in NUMBER_SIZES:
		if f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= max_width:
			return size
	return NUMBER_SIZES[NUMBER_SIZES.size() - 1]


static func draw_face(ci: CanvasItem, rect: Rect2, label: String, variant: int = 0) -> void:
	# Só no desenho: "×(-1)" vira "×-1" (mesma leitura, cabe em tamanho grande). O texto da carta,
	# o relatório e a conta continuam com "×(-1)".
	var text := label.replace("(", "").replace(")", "")
	ci.draw_texture(paper_texture(Vector2i(rect.size), variant), rect.position)

	# número: tinta escura no meio, maior tamanho que cabe, com um "relevo" de papel mais escuro
	var f := number_font()
	var size := fit_number_size(text, rect.size.x - 10.0)
	var base := Vector2(rect.position.x, roundf(rect.get_center().y + (f.get_ascent(size) - f.get_descent(size)) / 2.0))
	ci.draw_string(f, base + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, size, Palette.PAPER.darkened(0.32))
	ci.draw_string(f, base, text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, size, Palette.PAPER_INK)


# ---------------------------------------------------------------- papel antigo (textura em cache)
static var _paper_cache: Dictionary = {}
const BAYER: Array[int] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]


# Ruído determinístico em [0,1): a textura é sempre a mesma pra cada variante (não "pisca").
static func _noise(x: int, y: int, seed: int) -> float:
	var h := (x * 374761393 + y * 668265263 + seed * 1274126177) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h & 0xffff) / 65536.0


static func paper_texture(size: Vector2i, variant: int) -> ImageTexture:
	var key := Vector3i(size.x, size.y, variant)
	if _paper_cache.has(key):
		return _paper_cache[key]
	var w := size.x
	var h := size.y
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var base := Palette.PAPER
	var seed := variant + 1

	# 1) grão do papel: vários níveis de pontinhos claros e escuros (nada de chapado)
	for y in h:
		for x in w:
			var n := _noise(x, y, seed)
			var c := base
			if n < 0.16:
				c = base.darkened(0.08)
			elif n < 0.26:
				c = base.lightened(0.06)
			elif n < 0.285:
				c = base.lightened(0.13)            # brilho de fibra
			elif n > 0.975:
				c = base.darkened(0.30)             # pontinho de sujeira/tinta
			elif n > 0.94:
				c = base.darkened(0.15)
			img.set_pixel(x, y, c)

	# 2) fibras do papel: traços curtos, claros e escuros, em várias direções
	for y in h:
		if _noise(0, y, seed + 50) < 0.5:
			var x0 := int(_noise(1, y, seed + 60) * w)
			var length := 2 + int(_noise(2, y, seed + 70) * 6)
			var dark := _noise(3, y, seed + 75) < 0.6
			var slope := int(_noise(4, y, seed + 76) * 3) - 1          # -1, 0 ou 1: leve inclinação
			for i in length:
				var px := x0 + i
				var py := y + (slope * i) / 3
				if px < w and py >= 0 and py < h:
					var cur := img.get_pixel(px, py)
					img.set_pixel(px, py, cur.darkened(0.09) if dark else cur.lightened(0.07))

	# 3) manchas de umidade irregulares (contorno ondulado, sem círculos perfeitos)
	for k in 4:
		var cx := 6.0 + _noise(k, 3, seed + 80) * (w - 12.0)
		var cy := 8.0 + _noise(k, 4, seed + 90) * (h - 16.0)
		var r := 4.0 + _noise(k, 5, seed + 100) * 4.0
		for y in range(int(cy - r - 2), int(cy + r + 3)):
			for x in range(int(cx - r - 2), int(cx + r + 3)):
				if x < 0 or y < 0 or x >= w or y >= h:
					continue
				var wobble := 0.65 + 0.7 * _noise(x / 2, y / 2, seed + 120 + k)
				var d := Vector2(x - cx, y - cy).length()
				if d <= r * wobble:
					if _noise(x, y, seed + 110) < 0.6:
						img.set_pixel(x, y, img.get_pixel(x, y).darkened(0.07))
					if d > r * wobble - 1.3 and _noise(x, y, seed + 130) < 0.7:
						img.set_pixel(x, y, img.get_pixel(x, y).darkened(0.12))

	# 4) arranhões e rachaduras pequenas
	for k in 3:
		var pos := Vector2(3.0 + _noise(k, 7, seed + 140) * (w - 6.0), 5.0 + _noise(k, 8, seed + 150) * (h - 10.0))
		var dir := Vector2.from_angle(_noise(k, 9, seed + 160) * TAU)
		for step in 4 + int(_noise(k, 10, seed + 170) * 6):
			var ix := int(pos.x)
			var iy := int(pos.y)
			if ix > 4 and iy > 4 and ix < w - 5 and iy < h - 5:
				img.set_pixel(ix, iy, img.get_pixel(ix, iy).darkened(0.22))
			dir = dir.rotated((_noise(step, k, seed + 180) - 0.5) * 1.2)
			pos += dir

	# 5) bordas envelhecidas: escurece perto da moldura com dithering ordenado
	for y in h:
		for x in w:
			var d := mini(mini(x, y), mini(w - 1 - x, h - 1 - y))
			if d < 12:
				var t := (12.0 - d) / 12.0
				if t * 1.2 > BAYER[(y % 4) * 4 + (x % 4)] / 16.0:
					img.set_pixel(x, y, img.get_pixel(x, y).darkened(0.10 + 0.16 * t))

	# 6) moldura escura grossa (3 px), filete interno claro e cantoneiras "entalhadas" em degrau
	for y in h:
		for x in w:
			var d := mini(mini(x, y), mini(w - 1 - x, h - 1 - y))
			if d == 0:
				img.set_pixel(x, y, Palette.BORDER_DARK)
			elif d <= 2:
				img.set_pixel(x, y, Palette.PAPER_FRAME)
			elif d == 3:
				img.set_pixel(x, y, Palette.PAPER_LINE)             # filete interno
	for corner in [Vector2i(0, 0), Vector2i(w - 1, 0), Vector2i(0, h - 1), Vector2i(w - 1, h - 1)]:
		img.set_pixel(corner.x, corner.y, Color(0, 0, 0, 0))       # cantos vazados
	var dirs := [1, -1]
	for ix in 2:
		for iy in 2:
			var ox := 4 if ix == 0 else w - 5                       # degraus pretos nos 4 cantos de dentro
			var oy := 4 if iy == 0 else h - 5
			for j in 5:
				for i in 5 - j:
					img.set_pixel(ox + i * dirs[ix], oy + j * dirs[iy], Palette.PAPER_FRAME)
	# luz na quina de cima/esquerda da moldura
	for i in range(2, w - 2):
		img.set_pixel(i, 1, Palette.PAPER_FRAME.lightened(0.20))
	for j in range(2, h - 2):
		img.set_pixel(1, j, Palette.PAPER_FRAME.lightened(0.14))

	var tex := ImageTexture.create_from_image(img)
	_paper_cache[key] = tex
	return tex


static func draw_back(ci: CanvasItem, rect: Rect2) -> void:
	ci.draw_texture(back_texture(Vector2i(rect.size)), rect.position)


# ---------------------------------------------------------------- verso: "mandíbula" de papel antigo
static var _back_cache: Dictionary = {}


# Verso da carta, gerado por código pra QUALQUER tamanho (deck 42x58, mão do inimigo 16x24...):
# fundo marrom escuro granulado, moldura com filete e tira pontilhada, um anel de papel antigo
# com dentes apontando pra dentro (como a "boca" da referência) em volta de um centro preto
# com losangos. Mesmas cores da frente.
static func back_texture(size: Vector2i) -> ImageTexture:
	if _back_cache.has(size):
		return _back_cache[size]
	var w := size.x
	var h := size.y
	var big := w >= 30
	var seed := 77
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var dark := Palette.PAPER_FRAME.darkened(0.45)

	# geometria da janela central (superelipse = retângulo de cantos arredondados)
	var cx := (w - 1) / 2.0
	var cy := (h - 1) / 2.0
	var rx := w / 2.0 - (8.0 if big else 4.0)
	var ry := h / 2.0 - (9.0 if big else 4.5)
	var unit := minf(rx, ry)
	var n_wide := maxi(2, roundi(rx * 2.0 / 3.8))
	var n_tall := maxi(2, roundi(ry * 2.0 / 3.8))
	var long_h := 5.0 if big else 2.5
	var short_h := 3.0 if big else 1.5
	var band := 2.0 if big else 1.0

	for y in h:
		for x in w:
			var n := _noise(x, y, seed)
			var c := dark
			if n < 0.16:
				c = dark.lightened(0.18)
			elif n > 0.92:
				c = dark.darkened(0.35)
			var nx := (x - cx) / rx
			var ny := (y - cy) / ry
			var r := pow(pow(absf(nx), 3.0) + pow(absf(ny), 3.0), 1.0 / 3.0)
			var depth := (1.0 - r) * unit                     # >0: dentro da janela
			var paper := false
			var edge := false
			if depth >= 0.0:
				# dentes: perfil triangular, uniforme ao longo de cada lado
				var ax := absf(nx)
				var ay := absf(ny)
				var s := ny / maxf(ax, 0.0001) if ax >= ay else nx / maxf(ay, 0.0001)
				var n_side := n_tall if ax >= ay else n_wide
				var u := (s + 1.0) / 2.0 * n_side
				var idx := int(floor(u))
				var tri := pow(1.0 - absf(u - idx - 0.5) * 2.0, 1.4)       # presas afiadas
				var tooth := (long_h if idx % 2 == 0 else short_h) * tri * (1.0 - 0.7 * pow(absf(s), 3.0))
				if depth <= tooth:
					paper = true
					edge = depth > tooth - 1.0
				c = Palette.BORDER_DARK if not paper else c
			else:
				var ring := -depth
				if ring <= band:
					paper = true
					edge = ring > band - 1.0 or ring < 1.0
			if paper:
				var pc := Palette.PAPER
				var pn := _noise(x, y, seed + 9)
				if pn < 0.18:
					pc = pc.darkened(0.09)
				elif pn < 0.30:
					pc = pc.lightened(0.06)
				elif pn > 0.97:
					pc = pc.darkened(0.28)
				if edge:
					pc = pc.darkened(0.30)
				c = pc
			img.set_pixel(x, y, c)

	# losangos no centro (só no tamanho grande)
	if big:
		for k in [-1, 0, 1]:
			var dc := Vector2(cx, cy + k * 8.0)
			for j in range(-2, 3):
				for i in range(-2, 3):
					if absi(i) + absi(j) <= 2 and (absi(i) + absi(j) == 2 or (i == 0 and j == 0)):
						var px := int(roundf(dc.x)) + i
						var py := int(roundf(dc.y)) + j
						img.set_pixel(px, py, Palette.PAPER_LINE.lightened(0.15 if (i == 0 and j == 0) else 0.0))

	# bordas envelhecidas (dithering ordenado), igual à frente
	for y in h:
		for x in w:
			var d := mini(mini(x, y), mini(w - 1 - x, h - 1 - y))
			if d < 8:
				var t := (8.0 - d) / 8.0
				if t * 1.1 > BAYER[(y % 4) * 4 + (x % 4)] / 16.0:
					img.set_pixel(x, y, img.get_pixel(x, y).darkened(0.12 + 0.14 * t))

	# moldura: contorno escuro, filete de papel e tira pontilhada
	for y in h:
		for x in w:
			var d := mini(mini(x, y), mini(w - 1 - x, h - 1 - y))
			if d == 0:
				img.set_pixel(x, y, Palette.BORDER_DARK)
			elif d == 1:
				img.set_pixel(x, y, Palette.PAPER_FRAME)
			elif d == 2:
				img.set_pixel(x, y, Palette.PAPER.darkened(0.30))
			elif d == 3 and big:
				img.set_pixel(x, y, Palette.PAPER.darkened(0.45) if (x + y) % 2 == 0 else Palette.PAPER_FRAME.darkened(0.3))
	for corner in [Vector2i(0, 0), Vector2i(w - 1, 0), Vector2i(0, h - 1), Vector2i(w - 1, h - 1)]:
		img.set_pixel(corner.x, corner.y, Color(0, 0, 0, 0))

	var tex := ImageTexture.create_from_image(img)
	_back_cache[size] = tex
	return tex
