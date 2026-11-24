# StoryScene.gd
# Base das cenas contadas em imagens e texto que vai surgindo letra por letra (Intro e Ending).
# A cena filha só diz o seu id (scene_id) e a lista de passos (_steps); aqui fica todo o motor.
# Cada ESPAÇO (ou clique) avança um passo; se o texto ainda está sendo digitado, o primeiro aperto
# completa o texto. Segurar ESC ou Enter pula tudo.
#
# Cada passo é um dicionário:
#   "layout"  card   tela preta com o texto grande no centro
#             frame  foto num quadro menor, com o texto embaixo
#             title  como o "frame", mas com o texto grande no centro (fonte de títulos)
#             full   foto em tela cheia, com o texto numa faixa escura embaixo
#   "image"   caminho da foto (sem "image" a tela fica preta)
#   "zoom"    zoom final da câmera (1.0 = normal). "walk" = true faz a câmera andar (zoom + balanço)
#   "shake"   true: a foto treme (usado só nas imagens do Arkhon)
#   "style"   "flame" pinta a foto em vermelho/amarelo, em listras (dragão)
#   "text"    o texto. Destaques: [color=#ffe066]amarelo[/color] e [color=#ff3b3b]vermelho[/color]
#   "char_time"  segundos por letra (se quiser mais devagar que o padrão do layout)
#   "auto"    avança sozinho depois desse tanto de segundos (o espaço também avança antes)
#   "sfx"     id do efeito sonoro (AudioManager) tocado no passo; fica vazio até os sons existirem
#   "choice"  pergunta com opções: {"prompt": "7 × ? = 56", "options": [{"text": "8", "correct": true},
#             {"text": "6", "reply": "texto se errar"}]}. Só avança quando acerta.
#             Opções aceitam: "penalty": N (errar tira N de vida do jogador no começo da próxima batalha;
#             a opção errada some depois de escolhida), "unlock": "div_2" (acertar desbloqueia essa carta).
#             Na pergunta também: "row_width" (largura das opções, padrão 80).
#
# No fim só avisa o GameManager com o id da cena: a próxima cena fica na tabela FLOW.

extends Control

const FRAME_RECT := Rect2(120, 20, 400, 200)   # quadro das cenas da história (pixels internos)
const FRAME_BORDER := 3.0
const CHOICE_RECT := Rect2(190, 40, 260, 150)  # janela da pergunta (pixels internos)
const SCREEN := Vector2(640, 360)              # tela interna
const S := 3.0                                 # interna -> tela cheia (1920x1080): fotos e texto saem em ALTA qualidade

const TEXT_FONT: Font = preload("res://UI/Fonts/VT323-Regular.ttf")
const TITLE_FONT: Font = preload("res://UI/Fonts/Sorcery Code.ttf")
const TEXT_COLOR := Color("#f4f0e8")
const CHOICE_COLOR := Color("#c9bd9d")
const CHOICE_ACTIVE := Color("#ffd24a")

const ZOOM_TIME := 6.0                          # segundos para a câmera se aproximar
const MAX_ZOOM := 1.03                          # zoom mínimo, quase imperceptível (vale pra todas as cenas)
const WALK_ZOOM_TIME := 7.0                     # a caminhada é mais lenta
const WALK_BOB := 7.0                           # balanço dos passos (pixels da tela)
const WALK_STEPS_PER_SEC := 1.8
const FADE_TIME := 0.3

# Layout de cada tipo de texto: onde fica, quão grande é, se é centralizado e a velocidade da digitação.
const LAYOUTS := {
	"card": {"pos": Vector2(50, 130), "size": Vector2(540, 110), "font_size": 32, "center": true, "char_time": 0.05},
	"frame": {"pos": Vector2(120, 232), "size": Vector2(400, 110), "font_size": 20, "center": false, "char_time": 0.035},
	"title": {"pos": Vector2(60, 236), "size": Vector2(520, 100), "font_size": 28, "center": true, "char_time": 0.05},
	"full": {"pos": Vector2(40, 268), "size": Vector2(560, 84), "font_size": 20, "center": false, "char_time": 0.035},
}

var scene_id: String = ""                       # a cena filha define em _init()

var _steps_data: Array = []
var _bg_holder: Control
var _bg: TextureRect
var _frame_root: Control
var _frame_img: TextureRect
var _band: ColorRect
var _body: RichTextLabel
var _hint: Label
var _skip: HoldSkipButton
var _choice_panel: Control
var _choice_prompt: Label
var _choice_holder: Control
var _choice_rows: Array = []                # as opções (Labels em tela cheia)
var _choice_ids: Array = []                 # índice de cada opção na lista original
var _choice_sel: int = 0
var _choice_pointer: Label
var _choice: Dictionary = {}
var _choice_active: bool = false
var _used_options: Dictionary = {}          # opções erradas com penalidade já escolhidas ("passo:opção")
var _active: TextureRect
var _flame: ShaderMaterial
var _index: int = -1
var _layout: String = "frame"
var _current_image: String = ""
var _current_mode: String = ""
var _current_style: String = ""
var _zoom: float = 1.0
var _zoom_tween: Tween
var _type_tween: Tween
var _auto_tween: Tween
var _typing: bool = false
var _walking: bool = false
var _shaking: bool = false                 # passo com "shake": a foto treme (só nas imagens do Arkhon)
const SHAKE_AMOUNT := 1.5                   # pixels de tela
var _done: bool = false


# A cena filha devolve aqui a lista de passos.
func _steps() -> Array:
	return []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(black)
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_steps_data = _steps()
	if _steps_data.is_empty() or not _images_exist():
		_finish.call_deferred()
		return

	# foto em tela cheia (num suporte que balança quando o Cayo anda)
	_bg_holder = Control.new()
	_bg_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_holder)
	_bg_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg = _make_picture()
	_bg_holder.add_child(_bg)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# quadro, faixa e texto em TELA CHEIA (alta qualidade, sem passar pela tela de pixel de 640x360)
	var hires := Control.new()
	hires.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hires)
	hires.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_frame(hires)
	_build_text(hires)

	_build_choice(hires)

	_flame = ShaderMaterial.new()
	_flame.shader = _make_flame_shader()

	_skip = HoldSkipButton.new()
	add_child(_skip)
	_skip.completed.connect(_finish)
	# no canto de cima (como o "pular" do diálogo), pra não cobrir o texto
	_skip.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_skip.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_skip.grow_vertical = Control.GROW_DIRECTION_END
	_skip.offset_left = -(HoldSkipButton.BOX.x + HoldSkipButton.MARGIN)
	_skip.offset_right = -HoldSkipButton.MARGIN
	_skip.offset_top = HoldSkipButton.MARGIN
	_skip.offset_bottom = HoldSkipButton.MARGIN + HoldSkipButton.BOX.y

	CursorManager.use_hand()
	_show_step(0)


func _exit_tree() -> void:
	CursorManager.use_default()


func _process(_delta: float) -> void:
	if _bg_holder == null:
		return
	if _active != null:
		_active.position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * SHAKE_AMOUNT if _shaking else Vector2.ZERO
	if _walking:
		# balanço dos passos: sobe e desce a cada passada
		var t := Time.get_ticks_msec() / 1000.0
		_bg_holder.position.y = -absf(sin(t * PI * WALK_STEPS_PER_SEC)) * WALK_BOB
	elif _bg_holder.position.y != 0.0:
		_bg_holder.position.y = move_toward(_bg_holder.position.y, 0.0, 0.5)


func _images_exist() -> bool:
	for step in _steps_data:
		if step.has("image") and not ResourceLoader.exists(step["image"]):
			push_warning("%s: imagem '%s' não encontrada. Pulando a cena." % [scene_id, step["image"]])
			return false
	return true


# Uma foto que o zoom centraliza (o pivô acompanha o tamanho).
func _make_picture() -> TextureRect:
	var picture := TextureRect.new()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.visible = false
	picture.resized.connect(func() -> void: picture.pivot_offset = picture.size / 2.0)
	return picture


# Qualidade máxima: a foto original (1376x768) é ampliada UMA vez com Lanczos (mais nítido que o
# filtro da placa de vídeo) exatamente pro tamanho em que aparece na tela (cobrindo a área), e
# fica em cache. Aí a placa quase não precisa esticar nada.
var _texture_cache: Dictionary = {}
var dedither: float = 1.0                   # < 1: reduz a foto antes (mistura a trama de pontinhos, o zoom fica liso)


func _smooth_texture(path: String, area: Vector2) -> Texture2D:
	var key := "%s@%dx%d" % [path, int(area.x), int(area.y)]
	if _texture_cache.has(key):
		return _texture_cache[key]
	var source: Texture2D = load(path)
	var img: Image = source.get_image()
	if img.is_compressed():
		img.decompress()
	if dedither < 1.0:
		img.resize(int(img.get_width() * dedither), int(img.get_height() * dedither), Image.INTERPOLATE_TRILINEAR)
	var scale_to_cover := maxf(area.x / img.get_width(), area.y / img.get_height())
	img.resize(ceili(img.get_width() * scale_to_cover), ceili(img.get_height() * scale_to_cover), Image.INTERPOLATE_LANCZOS)
	var tex := ImageTexture.create_from_image(img)
	_texture_cache[key] = tex
	return tex


# Dragão do Arkhon: tons de vermelho e amarelo sobre o preto, em listras verticais (sombra de chama).
func _make_flame_shader() -> Shader:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float l = dot(c.rgb, vec3(0.3, 0.59, 0.11));
	vec3 col = mix(vec3(0.0), vec3(0.85, 0.1, 0.2), smoothstep(0.08, 0.45, l));
	col = mix(col, vec3(1.0, 0.85, 0.3), smoothstep(0.5, 0.85, l));
	float stripe = mod(floor(FRAGCOORD.x / 3.0), 2.0);
	col *= mix(0.4, 1.0, stripe);
	COLOR = vec4(col, c.a);
}
"""
	return shader


func _build_frame(content: Control) -> void:
	_frame_root = Control.new()
	_frame_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame_root.visible = false
	content.add_child(_frame_root)

	var border := ColorRect.new()
	border.color = Palette.PANEL_LIGHT
	border.position = (FRAME_RECT.position - Vector2(FRAME_BORDER, FRAME_BORDER)) * S
	border.size = (FRAME_RECT.size + Vector2(FRAME_BORDER, FRAME_BORDER) * 2.0) * S
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame_root.add_child(border)

	# a foto dentro do quadro é cortada no próprio quadro, então o zoom não vaza pra borda
	var inner := Control.new()
	inner.clip_contents = true
	inner.position = FRAME_RECT.position * S
	inner.size = FRAME_RECT.size * S
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame_root.add_child(inner)

	var inner_bg := ColorRect.new()
	inner_bg.color = Color.BLACK
	inner_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(inner_bg)
	inner_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_frame_img = _make_picture()
	inner.add_child(_frame_img)
	_frame_img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _build_text(content: Control) -> void:
	# faixa escura atrás do texto quando a foto é em tela cheia
	_band = ColorRect.new()
	_band.color = Color(0, 0, 0, 0.72)
	_band.position = Vector2(0, 256) * S
	_band.size = Vector2(SCREEN.x, SCREEN.y - 256) * S
	_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_band.visible = false
	content.add_child(_band)

	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.scroll_active = false
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_theme_color_override("default_color", TEXT_COLOR)
	_body.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	content.add_child(_body)

	_hint = Label.new()
	_hint.text = "espaço >"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.position = Vector2(SCREEN.x - 90, SCREEN.y - 16) * S
	_hint.size = Vector2(80, 12) * S
	_hint.add_theme_font_override("font", TEXT_FONT)
	_hint.add_theme_font_size_override("font_size", int(16 * S))
	_hint.add_theme_color_override("font_color", TEXT_COLOR.darkened(0.45))
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_hint)


# Janela da pergunta (conta + opções), desenhada em TELA CHEIA pra ficar nítida. É só um lugar
# provisório: dá pra trocar por imagens depois.
func _build_choice(parent: Control) -> void:
	_choice_panel = Control.new()
	_choice_panel.position = CHOICE_RECT.position * S
	_choice_panel.size = CHOICE_RECT.size * S
	_choice_panel.visible = false
	_choice_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(_choice_panel)

	var edge := ColorRect.new()
	edge.color = Palette.PANEL_LIGHT
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_choice_panel.add_child(edge)
	edge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fill := ColorRect.new()
	fill.color = Color("#0b0b0d")
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_choice_panel.add_child(fill)
	fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, int(1 * S))

	_choice_prompt = Label.new()
	_choice_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_choice_prompt.position = Vector2(0, 10 * S)
	_choice_prompt.size = Vector2(CHOICE_RECT.size.x * S, 40 * S)
	_choice_prompt.add_theme_font_override("font", TEXT_FONT)
	_choice_prompt.add_theme_font_size_override("font_size", int(32 * S))
	_choice_prompt.add_theme_color_override("font_color", CHOICE_COLOR)
	_choice_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_choice_panel.add_child(_choice_prompt)

	_choice_holder = Control.new()
	_choice_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_choice_panel.add_child(_choice_holder)


# ---------------------------------------------------------------------------
# Passos
# ---------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if _done:
		return
	if _choice_active:
		# na pergunta: setas/W-S movem, Enter/Espaço escolhem (o mouse é tratado em cada opção)
		if event.is_action_pressed("ui_down"):
			_select_choice_row((_choice_sel + 1) % maxi(_choice_rows.size(), 1))
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_up"):
			_select_choice_row((_choice_sel - 1 + _choice_rows.size()) % maxi(_choice_rows.size(), 1))
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept") and not _choice_ids.is_empty():
			_on_choice(_choice_ids[_choice_sel])
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		_advance()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _skip != null and _skip.get_global_rect().has_point(event.position):
			return                               # o clique no "pular" não avança a história
		_advance()
		get_viewport().set_input_as_handled()


func _advance() -> void:
	if _done or _choice_active:
		return
	if _typing:
		_finish_typing()
		return
	_show_step(_index + 1)


func _show_step(i: int) -> void:
	if i >= _steps_data.size():
		_finish()
		return
	_index = i
	var step: Dictionary = _steps_data[i]
	_layout = step.get("layout", "frame")
	# onde a foto aparece: nenhum (tela preta), quadro menor ou tela cheia
	var mode := "none"
	if step.has("image"):
		mode = "full" if _layout == "full" else "frame"
	var path: String = step.get("image", "")
	var style: String = step.get("style", "")
	_walking = false                          # sem balanço de passos
	_shaking = step.get("shake", false)
	if path != _current_image or mode != _current_mode or style != _current_style:
		_change_picture(path, mode, style, step.get("zoom", 1.0))
	else:
		_zoom_to(step.get("zoom", 1.0))
	_type_text(step.get("text", ""), step.get("char_time", 0.0))
	if step.has("choice"):
		_open_choice(step["choice"])
	else:
		_close_choice()
	if step.get("sfx", "") != "":
		AudioManager.play_sfx(step["sfx"])
	if _auto_tween != null and _auto_tween.is_valid():
		_auto_tween.kill()
	if step.has("auto"):
		var this_step := i
		_auto_tween = create_tween()
		_auto_tween.tween_interval(float(step["auto"]))
		_auto_tween.tween_callback(func() -> void:
			if not _done and _index == this_step and not _choice_active:
				_show_step(this_step + 1))


# Troca a foto com um fade curto (a antiga some, a nova aparece) e começa a câmera de novo do 1.0.
func _change_picture(path: String, mode: String, style: String, target_zoom: float) -> void:
	_current_image = path
	_current_mode = mode
	_current_style = style
	if _zoom_tween != null and _zoom_tween.is_valid():
		_zoom_tween.kill()
	var next: TextureRect = null
	if mode == "frame":
		next = _frame_img
	elif mode == "full":
		next = _bg
	var prev: TextureRect = _active
	var tween := create_tween()
	if prev != null:
		tween.tween_property(prev, "modulate:a", 0.0, FADE_TIME)
	tween.tween_callback(func() -> void:
		if prev != null and prev != next:
			prev.visible = false
		_frame_root.visible = mode == "frame"
		_active = next
		if next == null:
			return
		next.visible = true
		next.texture = _smooth_texture(path, FRAME_RECT.size * S if mode == "frame" else SCREEN * S)
		next.material = _flame if style == "flame" else null
		next.scale = Vector2.ONE
		next.modulate.a = 0.0
		_zoom = 1.0)
	if next != null:
		tween.tween_property(next, "modulate:a", 1.0, FADE_TIME)
		tween.tween_callback(func() -> void: _zoom_to(target_zoom))


# Sem zoom nas cenas (a trama de pontinhos das fotos parece tremer quando a foto cresce). O único
# zoom que sobrou é o do dragão do Arkhon (passo com "shake"), que treme de propósito.
func _zoom_to(target: float) -> void:
	target = minf(target, MAX_ZOOM) if _shaking else 1.0
	if _active == null or absf(target - _zoom) < 0.001:
		return
	_zoom = target
	if _zoom_tween != null and _zoom_tween.is_valid():
		_zoom_tween.kill()
	_zoom_tween = create_tween()
	_zoom_tween.tween_property(_active, "scale", Vector2(target, target), ZOOM_TIME)		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# O texto vai surgindo letra por letra, na posição e no tamanho do layout atual.
func _type_text(text: String, char_time: float = 0.0) -> void:
	if _type_tween != null and _type_tween.is_valid():
		_type_tween.kill()
	if text == "":
		_typing = false
		_body.visible = false
		_band.visible = false
		return
	var cfg: Dictionary = LAYOUTS[_layout]
	_body.visible = true
	_band.visible = _layout == "full"
	_body.position = cfg["pos"] * S
	_body.size = cfg["size"] * S
	var font: Font = TITLE_FONT if _layout == "title" else TEXT_FONT
	_body.add_theme_font_override("normal_font", font)
	_body.add_theme_font_size_override("normal_font_size", int(cfg["font_size"] * S))
	_body.text = "[center]%s[/center]" % text if cfg["center"] else text
	_body.visible_characters = 0
	_typing = true
	var total := maxi(_body.get_total_character_count(), 1)
	var per_char: float = char_time if char_time > 0.0 else float(cfg["char_time"])
	_type_tween = create_tween()
	_type_tween.tween_property(_body, "visible_characters", total, total * per_char)
	_type_tween.tween_callback(_on_typed)


func _on_typed() -> void:
	_typing = false
	_body.visible_characters = -1


func _finish_typing() -> void:
	if _type_tween != null and _type_tween.is_valid():
		_type_tween.kill()
	_on_typed()


# ---------------------------------------------------------------------------
# Pergunta com opções (só avança quando acerta)
# ---------------------------------------------------------------------------
func _open_choice(choice: Dictionary) -> void:
	_choice = choice
	_choice_active = true
	_choice_prompt.text = choice["prompt"]
	for row in _choice_rows:
		row.queue_free()
	_choice_rows.clear()
	_choice_ids.clear()
	for i in choice["options"].size():
		if _used_options.has("%d:%d" % [_index, i]):
			continue
		_choice_ids.append(str(i))
	var row_w: float = float(choice.get("row_width", 80)) * S
	var panel_w: float = CHOICE_RECT.size.x * S
	var x0: float = (panel_w - row_w) / 2.0 + 14.0 * S
	for r in _choice_ids.size():
		var label := Label.new()
		label.text = choice["options"][int(_choice_ids[r])]["text"]
		label.position = Vector2(x0, (62.0 + r * 20.0) * S)
		label.size = Vector2(row_w, 20.0 * S)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", TEXT_FONT)
		label.add_theme_font_size_override("font_size", int(16 * S))
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		label.mouse_entered.connect(_select_choice_row.bind(r))
		label.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_select_choice_row(r)
				_on_choice(_choice_ids[r]))
		_choice_panel.add_child(label)
		_choice_rows.append(label)
	if _choice_pointer == null:
		_choice_pointer = Label.new()
		_choice_pointer.text = ">"
		_choice_pointer.add_theme_font_override("font", TEXT_FONT)
		_choice_pointer.add_theme_font_size_override("font_size", int(16 * S))
		_choice_pointer.add_theme_color_override("font_color", CHOICE_ACTIVE)
		_choice_pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_choice_panel.add_child(_choice_pointer)
	_choice_pointer.visible = true
	_choice_panel.size.y = maxf(CHOICE_RECT.size.y, 62.0 + _choice_ids.size() * 20.0 + 12.0) * S   # cabe 5 opções
	_select_choice_row(0)
	_choice_panel.visible = true
	_hint.visible = false


func _select_choice_row(r: int) -> void:
	_choice_sel = clampi(r, 0, maxi(_choice_rows.size() - 1, 0))
	for i in _choice_rows.size():
		_choice_rows[i].add_theme_color_override("font_color", CHOICE_ACTIVE if i == _choice_sel else CHOICE_COLOR)
	if _choice_pointer != null and not _choice_rows.is_empty():
		_choice_pointer.position = _choice_rows[_choice_sel].position - Vector2(14.0 * S, 0)
		_choice_pointer.size = Vector2(14.0 * S, 20.0 * S)
		_choice_pointer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _close_choice() -> void:
	_choice_active = false
	_choice_panel.visible = false
	_hint.visible = true
	for row in _choice_rows:
		row.queue_free()
	_choice_rows.clear()
	_choice_ids.clear()
	if _choice_pointer != null:
		_choice_pointer.visible = false


func _on_choice(id: String) -> void:
	var option: Dictionary = _choice["options"][int(id)]
	if option.get("correct", false):
		if option.get("unlock", "") != "":
			GameManager.unlock_card(option["unlock"])
		_close_choice()
		_show_step(_index + 1)
	else:
		if option.get("penalty", 0) > 0:
			GameManager.add_hp_penalty(option["penalty"])
			_used_options["%d:%d" % [_index, int(id)]] = true
			_open_choice(_choice)                 # refaz a lista sem a opção que já foi
		_type_text(option.get("reply", "..."))


# ---------------------------------------------------------------------------
# Fim
# ---------------------------------------------------------------------------
func _finish() -> void:
	if _done:
		return
	_done = true
	_walking = false
	_shaking = false
	for tween in [_zoom_tween, _type_tween, _auto_tween]:
		if tween != null and tween.is_valid():
			tween.kill()
	GameManager.scene_finished(scene_id, "finished")
