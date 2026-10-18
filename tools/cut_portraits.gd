# cut_portraits.gd
# Corta a folha de expressões do Gribnok (reference/gribnok expressoes.webp: 12 retratos em grade
# 3x4) em arquivos separados, SEM reduzir a qualidade:
#   Resources/Portraits/gribnok_<nome>.png        quadrado (rosto inteiro, sem a plaquinha de nome)
#   Resources/Portraits/gribnok_<nome>_faixa.png  faixa larga (olhos e boca), pro diálogo
#
# Rodar:   godot --headless --path . --script res://tools/cut_portraits.gd

extends SceneTree

const SOURCE := "res://reference/gribnok expressoes.webp"
const OUT_DIR := "res://Resources/Portraits/"

# Molduras na folha (medidas na imagem): colunas e linhas [início, fim].
const COLS: Array = [[10, 318], [327, 618], [627, 924]]
const ROWS: Array = [[14, 433], [443, 851], [863, 1246], [1256, 1663]]
const NAMES: Array = [
	["neutro", "bravo", "feliz"],
	["fraco", "forte", "ferido"],
	["ameacador", "surpreso", "maligno"],
	["rindo", "triste", "planejando"],
]

const INNER_X := 12            # tira a moldura escura dos lados
const SQUARE_TOP := 34         # onde começa o quadrado, dentro da moldura
const STRIP_TOP := 135         # onde começa a faixa (um pouco acima dos olhos)
const STRIP_RATIO := 1.7       # largura / altura da faixa (vai dos olhos ao queixo)


func _initialize() -> void:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	sheet.convert(Image.FORMAT_RGBA8)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for r in ROWS.size():
		for c in COLS.size():
			var x0: int = COLS[c][0] + INNER_X
			var x1: int = COLS[c][1] - INNER_X
			var y0: int = ROWS[r][0]
			var w := x1 - x0
			var square := sheet.get_region(Rect2i(x0, y0 + SQUARE_TOP, w, w))
			var strip := sheet.get_region(Rect2i(x0, y0 + STRIP_TOP, w, int(w / STRIP_RATIO)))
			var base: String = OUT_DIR + "gribnok_" + NAMES[r][c]
			square.save_png(ProjectSettings.globalize_path(base + ".png"))
			strip.save_png(ProjectSettings.globalize_path(base + "_faixa.png"))
	print("12 retratos cortados em ", OUT_DIR)
	quit()
