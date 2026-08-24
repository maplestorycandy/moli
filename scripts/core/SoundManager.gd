extends Node

# 經典魔力寶貝音效與高傳真 BGM 輪播 / Boss 音樂切換管理器 (支援音量自訂與特效音靜音)
var sfx_players: Array[AudioStreamPlayer] = []
var bgm_player: AudioStreamPlayer = null
var current_playlist_idx: int = 0
var is_in_boss_mode: bool = false
var has_user_interacted: bool = false
var current_playing_wave: int = 1

# 音量控制與靜音設定 (0.0 ~ 1.0)
var bgm_volume: float = 0.8
var sfx_volume: float = 0.9
var is_bgm_muted: bool = false
var is_sfx_muted: bool = false

const MAX_PLAYERS = 12

const PLAYLIST = [
	{ "id": "bgm_01", "path": "res://assets/audio/bgm/bgm_01.ogg", "name": "法蘭城 主題曲 (啟程)" },
	{ "id": "bgm_02", "path": "res://assets/audio/bgm/bgm_02.ogg", "name": "法蘭城 東門 (熱血戰鬥)" },
	{ "id": "bgm_03", "path": "res://assets/audio/bgm/bgm_03.ogg", "name": "芙蕾雅島 (野外探索)" },
	{ "id": "bgm_04", "path": "res://assets/audio/bgm/bgm_04.ogg", "name": "索奇亞 (迷宮冒險)" },
	{ "id": "bgm_05", "path": "res://assets/audio/bgm/bgm_05.ogg", "name": "亞諾曼 (寧靜村莊)" },
	{ "id": "bgm_06", "path": "res://assets/audio/bgm/bgm_06.ogg", "name": "召喚之間 (聖詔之音)" },
	{ "id": "bgm_07", "path": "res://assets/audio/bgm/bgm_07.ogg", "name": "靈堂 (神秘地宮)" },
	{ "id": "bgm_08", "path": "res://assets/audio/bgm/bgm_08.ogg", "name": "阿巴尼斯 (雪山高原)" },
	{ "id": "bgm_09", "path": "res://assets/audio/bgm/bgm_09.ogg", "name": "黃昏暮色 (靜謐之夜)" },
	{ "id": "bgm_10", "path": "res://assets/audio/bgm/bgm_10.ogg", "name": "勇者激戰 (神之鬥志)" },
	{ "id": "bgm_11", "path": "res://assets/audio/bgm/bgm_11.ogg", "name": "傳奇終曲 (冒險勝利)" }
]

const BOSS_TRACKS = [
	{ "id": "boss_01", "path": "res://assets/audio/bgm/boss_01.ogg", "name": "Boss 戰鬥曲 (熱鬥決戰)" },
	{ "id": "boss_02", "path": "res://assets/audio/bgm/boss_02.ogg", "name": "Boss 戰鬥曲 (李貝留斯神戰)" }
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	for i in range(MAX_PLAYERS):
		var asp = AudioStreamPlayer.new()
		asp.bus = "Master"
		add_child(asp)
		sfx_players.append(asp)
		
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master"
	_update_bgm_volume()
	bgm_player.finished.connect(_on_bgm_finished)
	add_child(bgm_player)
	
	play_for_wave(1)

func _input(event: InputEvent) -> void:
	if not has_user_interacted:
		if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
			has_user_interacted = true
			if not bgm_player.playing:
				play_for_wave(current_playing_wave)

func set_bgm_volume(val: float) -> void:
	bgm_volume = clamp(val, 0.0, 1.0)
	_update_bgm_volume()

func set_sfx_volume(val: float) -> void:
	sfx_volume = clamp(val, 0.0, 1.0)

func set_bgm_muted(muted: bool) -> void:
	is_bgm_muted = muted
	_update_bgm_volume()

func set_sfx_muted(muted: bool) -> void:
	is_sfx_muted = muted

func _update_bgm_volume() -> void:
	if not bgm_player:
		return
	if is_bgm_muted or bgm_volume <= 0.001:
		bgm_player.volume_db = -80.0
	else:
		bgm_player.volume_db = -6.0 + linear_to_db(bgm_volume)

func play_for_wave(wave_num: int) -> void:
	current_playing_wave = wave_num
	var is_boss_wave = (wave_num % 5 == 0)
	
	if is_boss_wave:
		var boss_idx = (int(wave_num / 5) - 1) % 2
		play_boss_track(boss_idx)
	else:
		var non_boss_order = (wave_num - 1) - int((wave_num - 1) / 5)
		var playlist_idx = non_boss_order % PLAYLIST.size()
		play_playlist_track(playlist_idx)

func play_boss_track(idx: int) -> void:
	is_in_boss_mode = true
	var track = BOSS_TRACKS[idx % BOSS_TRACKS.size()]
	
	if ResourceLoader.exists(track["path"]):
		var stream = load(track["path"])
		if stream:
			bgm_player.stream = stream
			_update_bgm_volume()
			bgm_player.play()
			EventBus.show_banner_notification.emit("🔥 BOSS 決戰降臨！", "戰鬥曲目: 【%s】" % track["name"])

func play_playlist_track(idx: int) -> void:
	is_in_boss_mode = false
	current_playlist_idx = idx % PLAYLIST.size()
	var track = PLAYLIST[current_playlist_idx]
	
	if ResourceLoader.exists(track["path"]):
		var stream = load(track["path"])
		if stream:
			bgm_player.stream = stream
			_update_bgm_volume()
			bgm_player.play()
			EventBus.show_banner_notification.emit("🎵 正在播放 BGM", "【%s】" % track["name"])

func resume_normal_playlist() -> void:
	if is_in_boss_mode:
		is_in_boss_mode = false
		play_for_wave(current_playing_wave)

func next_playlist_track() -> void:
	current_playlist_idx = (current_playlist_idx + 1) % PLAYLIST.size()
	play_playlist_track(current_playlist_idx)

func _on_bgm_finished() -> void:
	if is_in_boss_mode:
		bgm_player.play()
	else:
		next_playlist_track()

func get_free_player() -> AudioStreamPlayer:
	for p in sfx_players:
		if not p.playing:
			return p
	return sfx_players[0]

func _play_sfx(stream: AudioStream, base_vol_db: float = 0.0, pitch: float = 1.0) -> void:
	if is_sfx_muted or sfx_volume <= 0.001:
		return
	var p = get_free_player()
	p.stream = stream
	p.volume_db = base_vol_db + linear_to_db(sfx_volume)
	p.pitch_scale = pitch
	p.play()

# --- 經典復古音效生成器 ---
func generate_tone(freq: float, duration: float, wave_type: String = "sine", decay: float = 0.05, vibrato: float = 0.0) -> AudioStreamWAV:
	var sample_rate = 22050
	var total_samples = int(sample_rate * duration)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(total_samples)
	
	var phase = 0.0
	for i in range(total_samples):
		var t = float(i) / float(sample_rate)
		var env = clamp(1.0 - (t / duration) * (1.0 / max(0.01, decay)), 0.0, 1.0)
		var current_freq = freq
		if vibrato > 0.0:
			current_freq += sin(t * 30.0) * vibrato
			
		var delta_phase = (current_freq * TAU) / float(sample_rate)
		phase += delta_phase
		
		var sample_val = 0.0
		if wave_type == "sine":
			sample_val = sin(phase)
		elif wave_type == "square":
			sample_val = 1.0 if sin(phase) > 0.0 else -1.0
		elif wave_type == "triangle":
			sample_val = asin(sin(phase)) * (2.0 / PI)
		elif wave_type == "noise":
			sample_val = randf_range(-1.0, 1.0)
			
		var byte_val = int(clamp((sample_val * env * 0.75 + 1.0) * 127.5, 0, 255))
		data[i] = byte_val
		
	stream.data = data
	return stream

func generate_arpeggio(freqs: Array, note_duration: float, wave_type: String = "square") -> AudioStreamWAV:
	var sample_rate = 22050
	var total_samples = int(sample_rate * (note_duration * freqs.size()))
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	
	var data = PackedByteArray()
	data.resize(total_samples)
	
	var current_note_idx = 0
	var phase = 0.0
	var note_samples = int(sample_rate * note_duration)
	
	for i in range(total_samples):
		current_note_idx = int(i / note_samples)
		var current_freq = freqs[min(current_note_idx, freqs.size() - 1)]
		var t_in_note = float(i % note_samples) / float(sample_rate)
		var env = clamp(1.0 - (t_in_note / note_duration), 0.1, 1.0)
		
		var delta_phase = (current_freq * TAU) / float(sample_rate)
		phase += delta_phase
		
		var sample_val = 0.0
		if wave_type == "square":
			sample_val = 1.0 if sin(phase) > 0.0 else -1.0
		elif wave_type == "triangle":
			sample_val = asin(sin(phase)) * (2.0 / PI)
		elif wave_type == "sine":
			sample_val = sin(phase)
			
		var byte_val = int(clamp((sample_val * env * 0.7 + 1.0) * 127.5, 0, 255))
		data[i] = byte_val
		
	stream.data = data
	return stream

func play_swing() -> void:
	_play_sfx(generate_tone(350.0, 0.12, "noise", 0.15), -6.0, randf_range(0.9, 1.2))

func play_hit() -> void:
	_play_sfx(generate_tone(180.0, 0.15, "square", 0.1), -3.0, randf_range(0.85, 1.15))

func play_crit() -> void:
	_play_sfx(generate_tone(120.0, 0.28, "triangle", 0.2), 0.0, randf_range(0.9, 1.05))

func play_dodge() -> void:
	_play_sfx(generate_tone(520.0, 0.15, "sine", 0.1), -8.0, 1.2)

func play_magic() -> void:
	_play_sfx(generate_arpeggio([523.25, 659.25, 783.99, 1046.5], 0.05, "sine"), -4.0)

func play_meteor_explosion() -> void:
	_play_sfx(generate_tone(80.0, 0.45, "noise", 0.35), 2.0)

func play_seal_throw() -> void:
	_play_sfx(generate_arpeggio([440.0, 554.37, 659.25, 880.0], 0.04, "triangle"), -2.0)

func play_seal_success() -> void:
	_play_sfx(generate_arpeggio([523.25, 659.25, 783.99, 1046.5, 1318.51, 1567.98], 0.08, "square"), 0.0)

func play_seal_fail() -> void:
	_play_sfx(generate_arpeggio([400.0, 350.0, 280.0, 200.0], 0.08, "square"), -2.0)

func play_level_up() -> void:
	_play_sfx(generate_arpeggio([440.0, 554.37, 659.25, 880.0, 1108.73, 1318.51], 0.1, "square"), 1.0)

func play_heal() -> void:
	_play_sfx(generate_arpeggio([659.25, 830.61, 987.77, 1318.51], 0.06, "sine"), -3.0)

func play_gold() -> void:
	_play_sfx(generate_arpeggio([987.77, 1318.51], 0.04, "square"), -6.0)
