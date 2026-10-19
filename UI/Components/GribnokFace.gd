# GribnokFace.gd
# Retratos do Gribnok (Resources/Portraits/, gerados por tools/cut_portraits.gd) e as regras de
# QUAL expressão usar:
#   - no diálogo: pela fala (palavras-chave em EXPRESSION_HINTS; sem pista = neutro);
#   - na batalha: pela vida dele (face_for_hp).
# As imagens ficam em qualidade original (com mipmaps, pra reduzir suave).

class_name GribnokFace
extends RefCounted

const DIR := "res://Resources/Portraits/gribnok_"

# Primeira dica que aparecer no texto decide a expressão (ordem importa).
const EXPRESSION_HINTS: Array = [
	["HAHAHA", "rindo"],
	["Ha!", "rindo"],
	["ISSO!", "feliz"],
	["AAH!", "surpreso"],
	["ACEITOU", "rindo"],
	["Prepare-se", "ameacador"],
	["PARADO", "bravo"],
	["NÃO ABRE", "bravo"],
	["NINGUÉM passa", "bravo"],
	["NÃO OLHA", "bravo"],
	["INVENCÍVEL", "forte"],
	["MELHOR", "forte"],
	["ESQUECI", "triste"],
	["Eu... ", "triste"],
	["Por favor?", "surpreso"],
	["Essa opção eu nem ia", "surpreso"],
	["Isso é ruim", "fraco"],
	["pressão demais", "fraco"],
	["OBRA-PRIMA", "maligno"],
	["Devorador", "maligno"],
	["plano", "planejando"],
	["Estou pensando", "planejando"],
]

static var _cache: Dictionary = {}


# Textura de uma expressão ("neutro", "bravo"...). strip = true devolve a faixa larga (olhos e boca).
static func texture(expression: String, strip: bool = false) -> Texture2D:
	var key := expression + ("_faixa" if strip else "")
	if not _cache.has(key):
		var path := DIR + key + ".png"
		# ResourceLoader (e não Image.load_from_file): dentro do .exe exportado o arquivo .png solto
		# não existe, só a versão importada, e ler do disco fechava o jogo
		if not ResourceLoader.exists(path):
			path = DIR + "neutro" + ("_faixa" if strip else "") + ".png"
		var img: Image = (load(path) as Texture2D).get_image()
		img.generate_mipmaps()
		_cache[key] = ImageTexture.create_from_image(img)
	return _cache[key]


# Expressão de uma fala do Gribnok (por palavras-chave).
static func expression_for_line(text: String) -> String:
	for hint in EXPRESSION_HINTS:
		if text.contains(hint[0]):
			return hint[1]
	return "neutro"


# Expressão na batalha, pela vida que ele ainda tem (0.0 a 1.0): ele vai ficando pior.
static func face_for_hp(ratio: float) -> String:
	if ratio >= 0.8:
		return "neutro"
	if ratio >= 0.6:
		return "bravo"
	if ratio >= 0.4:
		return "ferido"
	if ratio >= 0.2:
		return "fraco"
	return "triste"
