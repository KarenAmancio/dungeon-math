# CayoFace.gd
# Retratos do Cayo (Resources/Portraits/cayo_*.png, gerados por tools/cut_cayo.gd) e as regras de
# QUAL expressão usar:
#   - no diálogo: pela fala (palavras-chave em EXPRESSION_HINTS; sem pista = neutro);
#   - na batalha: pela vida dele (face_for_hp) e feliz quando ganha.
# Expressões: neutro, chocado, medo, bravo, feliz. As imagens ficam em qualidade original.

class_name CayoFace
extends RefCounted

const DIR := "res://Resources/Portraits/cayo_"
const BACKGROUND := Color("#130a1b")       # fundo roxo escuro das artes (preenche as margens)

# Primeira dica que aparecer no texto decide a expressão (ordem importa).
const EXPRESSION_HINTS: Array = [
	["finge tremer", "medo"],
	["só uma criança", "medo"],
	["9999", "chocado"],
	["Eram quatro metros", "chocado"],
	["acabou de me contar", "chocado"],
	["PUXE", "chocado"],
	["roubou a matemática", "bravo"],
	["não vou perder", "bravo"],
	["Se eu ganhar", "bravo"],
	["Então você viaja muito", "feliz"],
	["Eu aceito.", "bravo"],
]

static var _cache: Dictionary = {}


# Textura de uma expressão. strip = true devolve a faixa larga (olhos e boca).
static func texture(expression: String, strip: bool = false) -> Texture2D:
	var key := expression + ("_faixa" if strip else "")
	if not _cache.has(key):
		var path := DIR + key + ".png"
		if not FileAccess.file_exists(path):
			path = DIR + "neutro" + ("_faixa" if strip else "") + ".png"
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))
		img.generate_mipmaps()
		_cache[key] = ImageTexture.create_from_image(img)
	return _cache[key]


# Expressão de uma fala do Cayo (por palavras-chave).
static func expression_for_line(text: String) -> String:
	for hint in EXPRESSION_HINTS:
		if text.contains(hint[0]):
			return hint[1]
	return "neutro"


# Expressão na batalha, pela vida que ele ainda tem (0.0 a 1.0): vai ficando mais apertado e,
# quando está quase no fim, "brigando".
static func face_for_hp(ratio: float) -> String:
	if ratio >= 0.75:
		return "neutro"
	if ratio >= 0.5:
		return "chocado"
	if ratio >= 0.25:
		return "medo"
	return "bravo"
