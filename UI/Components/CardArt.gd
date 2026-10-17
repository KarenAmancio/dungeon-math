# CardArt.gd
# Desenho de cartas por código (sem PNG), compartilhado entre as cartas, o deck e a mão do
# inimigo. Tudo em pixels internos (640x360); quem chama passa o CanvasItem onde desenhar e
# o retângulo da carta.
#
#   draw_face: frente da carta (+4, ×2, ×(-1)...): papel antigo simples (granulado leve, borda
#              envelhecida, tudo em pixels) com moldura fina e SÓ o número no meio.
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

	# Propositalmente SIMPLES (poucas cores, baixa resolução): combina com o fundo retrô e fica
	# com cara de pixel art antigo quando a tela cresce. Papel + granulado leve + moldura fina.
	# 1) papel com pontinhos claros e escuros esparsos
	for y in h:
		for x in w:
			var n := _noise(x, y, seed)
			var c := base
			if n < 0.10:
				c = base.darkened(0.07)
			elif n < 0.16:
				c = base.lightened(0.05)
			elif n > 0.985:
				c = base.darkened(0.2)
			img.set_pixel(x, y, c)

	# 2) bordas envelhecidas: escurece perto da moldura com dithering ordenado
	for y in h:
		for x in w:
			var d := mini(mini(x, y), mini(w - 1 - x, h - 1 - y))
			if d < 8:
				var t := (8.0 - d) / 8.0
				if t > BAYER[(y % 4) * 4 + (x % 4)] / 16.0:
					img.set_pixel(x, y, img.get_pixel(x, y).darkened(0.12))

	# 3) moldura fina: contorno escuro, faixa de moldura e filete interno
	for y in h:
		for x in w:
			var d := mini(mini(x, y), mini(w - 1 - x, h - 1 - y))
			if d == 0:
				img.set_pixel(x, y, Palette.BORDER_DARK)
			elif d == 1:
				img.set_pixel(x, y, Palette.PAPER_FRAME)
			elif d == 2:
				img.set_pixel(x, y, Palette.PAPER_LINE)
	for corner in [Vector2i(0, 0), Vector2i(w - 1, 0), Vector2i(0, h - 1), Vector2i(w - 1, h - 1)]:
		img.set_pixel(corner.x, corner.y, Color(0, 0, 0, 0))       # cantos vazados

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
