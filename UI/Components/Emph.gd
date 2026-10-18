# Emph.gd
# Destaque de palavras importantes no meio de um texto: escreva [b]palavra[/b] e o RichTextLabel
# mostra a palavra na fonte de destaque do tema (CS Wavelle Pixel) e na cor de hover.
# Os textos longos (tutorial, Como jogar) passam por aqui antes de ir pro RichTextLabel.

class_name Emph
extends RefCounted


static func prep(text: String) -> String:
	var color := Palette.TEXT_HOVER.to_html(false)
	return text.replace("[b]", "[color=#%s][b]" % color).replace("[/b]", "[/b][/color]")


# Trecho de conta dentro de um texto longo: usa a fonte das contas (Jersey10) no tamanho dado.
static func math(text: String, size: int = 20) -> String:
	return "[font=res://UI/Fonts/math_font.tres][font_size=%d]%s[/font_size][/font]" % [size, text]
