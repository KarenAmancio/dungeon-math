# Intro.gd
# Toca o vídeo de introdução em tela cheia. Qualquer tecla ou clique PULA. Ao terminar (ou ao
# pular) só avisa o GameManager: esta cena não sabe qual é a próxima.
#
# O Godot 4 só toca vídeo Ogg Theora (.ogv). O caminho é configurável (video_path). Se o arquivo
# não existir ou não puder ser tocado, a Intro avisa no console e PULA, sem quebrar o jogo.
# Se houver um vídeo em outro formato (mp4, webm...) em Videos/, o aviso diz como converter.

extends Control

@export var video_path: String = "res://Videos/intro.ogv"

const VIDEO_DIR := "res://Videos"
const OTHER_FORMATS: Array[String] = ["mp4", "webm", "mov", "avi", "mkv", "m4v"]

var _player: VideoStreamPlayer
var _done: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(black)
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var stream := _load_stream()
	if stream == null:
		_finish.call_deferred()
		return

	_player = VideoStreamPlayer.new()
	_player.expand = true
	_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_player)
	_player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_player.stream = stream
	_player.finished.connect(_finish)
	_player.play()

	var hint := Label.new()
	hint.text = "Pressione qualquer tecla para pular"
	hint.add_theme_font_size_override("font_size", 30)     # a Intro é em tela cheia (1920x1080), não em pixels internos
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.35))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hint)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hint.position = Vector2(-520, -60)


func _load_stream() -> VideoStream:
	if ResourceLoader.exists(video_path):
		var stream := load(video_path)
		if stream is VideoStream:
			return stream
		push_warning("Intro: '%s' existe mas não pôde ser carregado como vídeo (o Godot só toca .ogv). Pulando a intro." % video_path)
		return null
	_warn_missing()
	return null


func _warn_missing() -> void:
	for file_name in DirAccess.get_files_at(VIDEO_DIR):
		if file_name.get_extension().to_lower() in OTHER_FORMATS:
			push_warning("Intro: encontrei 'Videos/%s', mas o Godot só toca .ogv. Converta assim e salve como Videos/intro.ogv:\n  ffmpeg -i \"Videos/%s\" -c:v libtheora -q:v 7 -c:a libvorbis -q:a 5 Videos/intro.ogv\nPulando a intro por enquanto." % [file_name, file_name])
			return
	push_warning("Intro: vídeo '%s' não encontrado (coloque um .ogv em Videos/ ou ajuste video_path). Pulando a intro." % video_path)


func _input(event: InputEvent) -> void:
	if _done:
		return
	var pressed_key: bool = event is InputEventKey and event.pressed and not event.echo
	var pressed_mouse: bool = event is InputEventMouseButton and event.pressed
	if pressed_key or pressed_mouse:
		_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	if _player != null:
		_player.stop()
	GameManager.scene_finished("intro", "finished")
