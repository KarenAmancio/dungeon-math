# cut_cayo.gd
# Corta a folha de expressões do Cayo (reference/expressoes cayo.png: 5 retratos) em arquivos
# separados, SEM reduzir a qualidade (a folha já vem com espaço em volta de cada rosto):
#   Resources/Portraits/cayo_<nome>.png        quadrado (busto inteiro, pra batalha)
#   Resources/Portraits/cayo_<nome>_faixa.png  faixa larga (olhos e boca), pro diálogo
#
# Rodar:   godot --headless --path . --script res://tools/cut_cayo.gd

extends SceneTree

const SOURCE := "res://reference/expressoes cayo.png"
const OUT_DIR := "res://Resources/Portraits/"

# nome, centro x do retrato na folha, linha (0 = de cima, 1 = de baixo)
const FACES: Array = [
	["neutro", 270, 0],
	["chocado", 685, 0],
	["medo", 1120, 0],
	["bravo", 435, 1],
	["feliz", 900, 1],
]
const ROW_TOP: Array = [15, 383]          # onde começa o quadrado em cada linha
const SQUARE := 360
const STRIP_OFFSET := 100                 # da base do quadrado até o topo da faixa (olhos)
const STRIP_W := 300
const STRIP_RATIO := 1.7


func _initialize() -> void:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	sheet.convert(Image.FORMAT_RGBA8)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for f in FACES:
		var cx: int = f[1]
		var y0: int = ROW_TOP[f[2]]
		var square := sheet.get_region(Rect2i(cx - SQUARE / 2, y0, SQUARE, SQUARE))
		var strip := sheet.get_region(Rect2i(cx - STRIP_W / 2, y0 + STRIP_OFFSET, STRIP_W, int(STRIP_W / STRIP_RATIO)))
		var base: String = OUT_DIR + "cayo_" + f[0]
		square.save_png(ProjectSettings.globalize_path(base + ".png"))
		strip.save_png(ProjectSettings.globalize_path(base + "_faixa.png"))
	print("5 retratos do Cayo cortados. Cor do fundo: ", sheet.get_pixel(2, 2).to_html(false))
	quit()
