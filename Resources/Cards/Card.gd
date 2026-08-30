extends Node2D

signal hovered
signal hovered_off

const FRONT_TEXTURE = preload("res://Resources/Cards/fronte da carta nova.png")
const BACK_TEXTURE = preload("res://Resources/Cards/CARTA NOVA.png")

# Escala usada na frente da carta (definida no Card.tscn), pra saber
# qual é o "tamanho alvo" (retângulo) que o verso também precisa ocupar.
const FRONT_SPRITE_SCALE = Vector2(2.8219101, 2.9625463)

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
		$CardLabel.text = card_label_text
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered",self)


func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off",self)
