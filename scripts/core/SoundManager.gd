extends Node

# 程序化合成經典復古音效生成器 (無須額外音效檔即可發聲)
var sfx_players: Array[AudioStreamPlayer] = []
var bgm_player: AudioStreamPlayer = null
const MAX_PLAYERS = 12

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(MAX_PLAYERS):
		var asp = AudioStreamPlayer.new()
		asp.bus = "Master"
		add_child(asp)
		sfx_players.append(asp)
		
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "Master"
	bgm_player.volume_db = -12.0
	add_child(bgm_player)

func get_free_player() -> AudioStreamPlayer:
	for p in sfx_players:
		if not p.playing:
			return p
	return sfx_players[0]

# 生成單音頻樣本流
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
			
		# 轉為 8-bit unsigned (0..255)
		var byte_val = int(clamp((sample_val * env * 0.75 + 1.0) * 127.5, 0, 255))
		data[i] = byte_val
		
	stream.data = data
	return stream

# 複合音效生成 (序列音符)
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

# 播放各種經典動作與戰鬥音效
func play_swing() -> void:
	var p = get_free_player()
	p.stream = generate_tone(350.0, 0.12, "noise", 0.15)
	p.volume_db = -6.0
	p.pitch_scale = randf_range(0.9, 1.2)
	p.play()

func play_hit() -> void:
	var p = get_free_player()
	p.stream = generate_tone(180.0, 0.15, "square", 0.1)
	p.volume_db = -3.0
	p.pitch_scale = randf_range(0.85, 1.15)
	p.play()

func play_crit() -> void:
	var p = get_free_player()
	p.stream = generate_tone(120.0, 0.28, "triangle", 0.2)
	p.volume_db = 0.0
	p.pitch_scale = randf_range(0.9, 1.05)
	p.play()

func play_dodge() -> void:
	var p = get_free_player()
	p.stream = generate_tone(520.0, 0.15, "sine", 0.1)
	p.volume_db = -8.0
	p.pitch_scale = 1.2
	p.play()

func play_magic() -> void:
	var p = get_free_player()
	p.stream = generate_arpeggio([523.25, 659.25, 783.99, 1046.5], 0.05, "sine")
	p.volume_db = -4.0
	p.play()

func play_meteor_explosion() -> void:
	var p = get_free_player()
	p.stream = generate_tone(80.0, 0.45, "noise", 0.35)
	p.volume_db = 2.0
	p.play()

func play_seal_throw() -> void:
	var p = get_free_player()
	p.stream = generate_arpeggio([440.0, 554.37, 659.25, 880.0], 0.04, "triangle")
	p.volume_db = -2.0
	p.play()

func play_seal_success() -> void:
	var p = get_free_player()
	p.stream = generate_arpeggio([523.25, 659.25, 783.99, 1046.5, 1318.51, 1567.98], 0.08, "square")
	p.volume_db = 0.0
	p.play()

func play_seal_fail() -> void:
	var p = get_free_player()
	p.stream = generate_arpeggio([400.0, 350.0, 280.0, 200.0], 0.08, "square")
	p.volume_db = -2.0
	p.play()

func play_level_up() -> void:
	var p = get_free_player()
	p.stream = generate_arpeggio([440.0, 554.37, 659.25, 880.0, 1108.73, 1318.51], 0.1, "square")
	p.volume_db = 1.0
	p.play()

func play_heal() -> void:
	var p = get_free_player()
	p.stream = generate_arpeggio([659.25, 830.61, 987.77, 1318.51], 0.06, "sine")
	p.volume_db = -3.0
	p.play()

func play_gold() -> void:
	var p = get_free_player()
	p.stream = generate_arpeggio([987.77, 1318.51], 0.04, "square")
	p.volume_db = -6.0
	p.play()
