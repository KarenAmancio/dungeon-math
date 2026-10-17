class_name Card
extends Node2D

signal hovered
signal hovered_off

# Tamanho padrão da carta em pixels internos (um pouco maior que o miolo dos slots, pra cobrir
# qualquer desencaixe). A ARTE é uma imagem em qualidade original (CardArt), desenhada com filtro
# suave: a batalha roda em resolução cheia, então a carta mantém todo o desenho. O NÚMERO é uma
# fonte de pixel e fica num nó filho com filtro nearest (nítido).
const CARD_SIZE := Vector2(38, 58)
const SCALE_NORMAL := Vector2.ONE
const HOVER_LIFT := 4.0           # a carta "sobe" 4 px quando o mouse passa

var card_label_text = "?"
var card_value: int = 0
var card_operation: String = ""

# Quando true, essa carta é só "de mentira": mostra o verso, não reage
# a clique/hover e não é arrastável. Usado pra representar a mão do
# Gribnok sem revelar o que ele tem.
var face_down: bool = false
var card_size: Vector2 = CARD_SIZE   # a mão do inimigo usa um tamanho menor

var paper_variant: int = 0          # (não usado mais: a frente é uma imagem só)

var _hovered: bool = false
var _dragging: bool = false
var _number_layer: Node2D


func _ready() -> void:
	# cada carta tem a sua própria forma (o tamanho pode variar, ex.: mão do inimigo)
	var shape := RectangleShape2D.new()
	shape.size = card_size
	$Area2D/CollisionShape2D.shape = shape
	if face_down:
		$Area2D/CollisionShape2D.disabled = true
	else:
		get_parent().connect_card_signals(self)
	paper_variant = get_instance_id() % 4
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS     # arte em qualidade original, reduzida suave
	_number_layer = _NumberLayer.new()
	add_child(_number_layer)
	_refresh()


# Único ponto que muda o texto da carta (o Battle.gd também usa este).
func set_label_text(text: String) -> void:
	card_label_text = text
	_refresh()


func set_hovered(on: bool) -> void:
	if _hovered != on:
		_hovered = on
		_refresh()


func set_dragging(on: bool) -> void:
	if _dragging != on:
		_dragging = on
		_refresh()


func _refresh() -> void:
	queue_redraw()
	if _number_layer != null:
		_number_layer.queue_redraw()


# Retângulo da carta (a carta "sobe" um pouco com o mouse em cima).
func _face_rect() -> Rect2:
	var r := Rect2(-card_size / 2.0, card_size)
	if _hovered and not _dragging:
		r.position.y -= HOVER_LIFT
	return r


func _draw() -> void:
	var r := _face_rect()
	if _dragging:
		draw_rect(Rect2(r.position + Vector2(2, 3), r.size), Color(0, 0, 0, 0.45))   # sombra de arrasto
	if face_down:
		CardArt.draw_back(self, r)
	else:
		CardArt.draw_face_art(self, r)
	if _hovered or _dragging:
		draw_rect(r.grow(1), Palette.GOLD, false)


# Chamado pelo nó filho (_NumberLayer), que desenha o número com filtro nearest.
func _draw_number(ci: CanvasItem) -> void:
	if face_down:
		return
	CardArt.draw_number(ci, _face_rect(), str(card_label_text))


func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered",self)


func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off",self)


# Nó que só desenha o número da carta (nítido, sem suavização).
class _NumberLayer extends Node2D:
	func _ready() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	func _draw() -> void:
		(get_parent() as Card)._draw_number(self)
