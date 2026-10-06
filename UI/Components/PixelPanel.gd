# PixelPanel.gd
# Painel "caixa de RPG": borda externa escura grossa + uma segunda borda
# interna mais clara, que dá a sensação de profundidade sem usar gradiente.
# Cantos sempre retos (ver Palette.box).

class_name PixelPanel
extends Panel


func configure(fill: Color, border: Color, inner_border: Color, border_w: int = 4, inner_w: int = 2) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", Palette.box(fill, border, border_w))

	# A segunda borda é um Panel filho colado por dentro da primeira.
	var inner := Panel.new()
	inner.name = "InnerBorder"
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_stylebox_override("panel", Palette.outline(inner_border, inner_w))
	add_child(inner)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, border_w)
