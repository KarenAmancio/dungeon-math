class_name Card
extends Node2D

signal hovered
signal hovered_off

# Tamanho padrão da carta em pixels internos (igual ao slot). O desenho é todo por código
# (CardArt), centrado na origem do nó; sem PNG e sem escala (carta em escala 1 = pixels nítidos).
const CARD_SIZE := Vector2(36, 56)
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

var paper_variant: int = 0          # qual das 4 texturas de papel (cada carta tem a sua, fixa)

var _hovered: bool = false
var _dragging: bool = false


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
	queue_redraw()


# Único ponto que muda o texto da carta (o Battle.gd também usa este).
func set_label_text(text: String) -> void:
	card_label_text = text
	queue_redraw()


func set_hovered(on: bool) -> void:
	if _hovered != on:
		_hovered = on
		queue_redraw()


func set_dragging(on: bool) -> void:
	if _dragging != on:
		_dragging = on
		queue_redraw()


func _draw() -> void:
	var r := Rect2(-card_size / 2.0, card_size)
	if _dragging:
		draw_rect(Rect2(r.position + Vector2(2, 3), r.size), Color(0, 0, 0, 0.45))   # sombra de arrasto
	if _hovered and not _dragging:
		r.position.y -= HOVER_LIFT
	if face_down:
		CardArt.draw_back(self, r)
	else:
		CardArt.draw_face(self, r, str(card_label_text), paper_variant)
	if _hovered or _dragging:
		draw_rect(r.grow(1), Palette.GOLD, false)


func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered",self)


func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off",self)
