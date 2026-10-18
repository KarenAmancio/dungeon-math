# AudioManager.gd  (Autoload)
# Música do jogo. Cada cena pode ter uma música (tabela SCENE_MUSIC); o GameManager avisa qual cena
# está abrindo e o AudioManager troca a faixa com um fade (cruzado), sem cortar seco. Se a cena
# nova usa a MESMA faixa (ex.: batalha -> tentar de novo), ela continua tocando sem reiniciar.
# Cena sem música (menu, intro, créditos) = a música atual some com fade.
#
# Efeitos sonoros (SFX) entram aqui depois: play_sfx(id).

extends Node

# id da música -> arquivo
const MUSIC := {
	"gribnok": "res://Audio/Music/gribnok talk.mp3",
	"battle": "res://Audio/Music/battle scene.mp3",
}

# id da cena (GameManager) -> id da música. Cena que não está aqui fica em silêncio.
const SCENE_MUSIC := {
	"dialogue": "gribnok",
	"battle": "battle",
}

const MUSIC_VOLUME_DB := -8.0
const SILENT_DB := -60.0
const FADE_TIME := 0.8

var current_music: String = ""

var _player: AudioStreamPlayer
var _tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS      # a música continua com o jogo pausado
	_player = AudioStreamPlayer.new()
	_player.volume_db = SILENT_DB
	add_child(_player)


# Chamado pelo GameManager quando uma cena começa a abrir.
func play_for_scene(scene_id: String) -> void:
	play_music(SCENE_MUSIC.get(scene_id, ""))


# "" = silêncio (com fade). A mesma música que já toca não reinicia.
func play_music(music_id: String) -> void:
	if music_id == current_music:
		return
	current_music = music_id
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	if _player.playing:
		_tween.tween_property(_player, "volume_db", SILENT_DB, FADE_TIME * 0.5)
	if music_id == "":
		_tween.tween_callback(_player.stop)
		return
	_tween.tween_callback(_start.bind(music_id))
	_tween.tween_property(_player, "volume_db", MUSIC_VOLUME_DB, FADE_TIME)


func _start(music_id: String) -> void:
	var stream: AudioStreamMP3 = load(MUSIC[music_id])
	stream.loop = true
	_player.stream = stream
	_player.volume_db = SILENT_DB
	_player.play()


func stop_music() -> void:
	play_music("")
