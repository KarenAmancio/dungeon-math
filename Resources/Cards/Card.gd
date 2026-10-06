class_name Card
extends Node2D

signal hovered
signal hovered_off

const FRONT_TEXTURE = preload("res://Resources/Cards/fronte da carta nova.png")
const BACK_TEXTURE = preload("res://Resources/Cards/CARTA NOVA.png")

# Escala usada na frente da carta (definida no Card.tscn), pra saber
# qual é o "tamanho alvo" (retângulo) que o verso também precisa ocupar.
const FRONT_SPRITE_SCALE = Vector2(2.8219101, 2.9625463)

# Escalas da carta, centralizadas aqui (o CardManager usa estas constantes).
const SCALE_NORMAL := Vector2(0.40, 0.40)
const SCALE_HOVER := Vector2(0.43, 0.43)

# Miolo em branco do PNG (dentro dos ornamentos), em coordenadas locais da carta.
# A "placa" colorida e o texto ocupam exatamente esse retângulo.
const PLATE_RECT := Rect2(-128, -92, 256, 210)
const PLATE_BORDER := 8
const TEXT_PADDING := 20.0
const MIN_FONT_SIZE := 36
const TINT_STRENGTH := 0.3  # quanto o PNG é tingido pela cor do tipo

var card_label_text = "?"
var card_value: int = 0
var card_operation: String = ""

# Quando true, essa carta é só "de mentira": mostra o verso, não reage
# a clique/hover e não é arrastável. Usado pra representar a mão do
# Gribnok sem revelar o que ele tem.
var face_down: bool = false


func _ready() -> void:
	if face_down:
		$CardImage.texture = BACK_TEXTURE
		# A imagem do verso tem proporção diferente da frente (mais
		# quadrada). Recalcula a escala pra ela ocupar exatamente o
		# mesmo retângulo que a frente ocupa, em vez de ficar quadrada.
		var target_size = FRONT_TEXTURE.get_size() * FRONT_SPRITE_SCALE
		var back_size = BACK_TEXTURE.get_size()
		$CardImage.scale = Vector2(target_size.x / back_size.x, target_size.y / back_size.y)
		$CardLabel.visible = false
		$Area2D/CollisionShape2D.disabled = true
	else:
		get_parent().connect_card_signals(self)
		_apply_type_look()
		set_label_text(card_label_text)


# Soma, subtração e multiplicação têm cores diferentes.
func _type_color() -> Color:
	if card_operation == "multiply":
		return Palette.CARD_MUL
	if card_value < 0:
		return Palette.CARD_SUB
	return Palette.CARD_ADD


# Tint leve no PNG + placa colorida só no miolo vazio (não cobre os ornamentos).
func _apply_type_look() -> void:
	var color := _type_color()
	$CardImage.modulate = Color.WHITE.lerp(color, TINT_STRENGTH)

	var plate := get_node_or_null("TypePlate") as Panel
	if plate == null:
		plate = Panel.new()
		plate.name = "TypePlate"
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.position = PLATE_RECT.position
		plate.size = PLATE_RECT.size
		add_child(plate)
		move_child(plate, $CardLabel.get_index())  # placa atrás do texto
	plate.add_theme_stylebox_override("panel", Palette.box(color, Palette.BORDER_DARK, PLATE_BORDER))


# Único ponto que muda o texto da carta (o Battle.gd também usa este).
# O tamanho da fonte depende do nº de caracteres e é reduzido até o texto
# caber na placa, então "×(-1)" nunca quebra nem estoura.
func set_label_text(text: String) -> void:
	card_label_text = text
	var label := $CardLabel as Label
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var font := label.get_theme_font("font")
	var font_size := _base_font_size(text.length())
	var max_width := PLATE_RECT.size.x - TEXT_PADDING * 2.0
	while font_size > MIN_FONT_SIZE and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > max_width:
		font_size -= 4

	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Palette.TEXT_LIGHT)
	label.add_theme_color_override("font_outline_color", Palette.BORDER_DARK)
	label.add_theme_color_override("font_shadow_color", Palette.BORDER_DARK)
	label.add_theme_constant_override("outline_size", 3)   # ~1px na tela (escala 0.4)
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	label.position = PLATE_RECT.position
	label.size = PLATE_RECT.size


# Curto = grande, longo = menor.
func _base_font_size(char_count: int) -> int:
	if char_count <= 2:
		return 170
	if char_count == 3:
		return 140
	if char_count == 4:
		return 112
	return 120


func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered",self)


func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off",self)
