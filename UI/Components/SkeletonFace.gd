# SkeletonFace.gd
# Retrato do ESQUELETO (nível 2): um recorte fixo do rosto, tirado da foto Backgrounds/intro/esqueleto.png
# (Resources/Portraits/esqueleto.png e esqueleto_faixa.png). Sem expressões por enquanto: quando a arte
# própria existir, é só trocar os dois arquivos (ou ligar às expressões como o GribnokFace).

class_name SkeletonFace
extends RefCounted

const SQUARE := "res://Resources/Portraits/esqueleto.png"
const STRIP := "res://Resources/Portraits/esqueleto_faixa.png"

static var _cache: Dictionary = {}


# strip = true devolve a faixa larga (usada no diálogo); senão o quadrado (usado na batalha).
static func texture(strip: bool = false) -> Texture2D:
	var path := STRIP if strip else SQUARE
	if not _cache.has(path):
		var img: Image = (load(path) as Texture2D).get_image()
		img.generate_mipmaps()
		_cache[path] = ImageTexture.create_from_image(img)
	return _cache[path]
