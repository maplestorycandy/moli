extends Node

const MonsterDatabase = preload("res://scripts/data/MonsterDatabase.gd")
const EnemyBase = preload("res://scripts/entities/EnemyBase.gd")

signal wave_started(wave_num: int, is_boss: bool)
signal wave_cleared(wave_num: int)
signal all_waves_completed()
signal wave_timer_updated(time_left: float, total_monsters: int, remaining: int)

var current_wave: int = 1
const MAX_WAVES = 50

var is_wave_active: bool = false
var wave_countdown: float = 6.0 # 整備時間 6 秒
var spawn_queue: Array[Dictionary] = []
var spawn_interval_timer: float = 0.0
var total_wave_enemies_to_spawn: int = 0

var enemy_base_scene = preload("res://scenes/enemies/SlimeEnemy.tscn")

# 四面城外集中出怪魔界裂隙 (西南、東北、西北、東南 4 方跨海長橋起點)
const SPAWN_GATES = [
	Vector2(-150, 1050), # 西南方城外裂隙
	Vector2(1350, -50),  # 東北方城外裂隙
	Vector2(-150, -50),  # 西北方城外裂隙
	Vector2(1350, 1050)  # 東南方城外裂隙
]

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if not is_wave_active:
		wave_countdown -= delta
		var alive_enemies = _get_alive_wave_enemies_count()
		wave_timer_updated.emit(max(0.0, wave_countdown), total_wave_enemies_to_spawn, alive_enemies)
		if wave_countdown <= 0.0:
			_start_next_wave()
	else:
		# 急速隊列出怪 (0.15 秒自四面八方急速湧出)
		if spawn_queue.size() > 0:
			spawn_interval_timer -= delta
			if spawn_interval_timer <= 0.0:
				spawn_interval_timer = 0.15
				var m_data = spawn_queue.pop_front()
				_spawn_wave_monster(m_data)
				
		# 檢查波次是否肅清
		var current_alive = _get_alive_wave_enemies_count()
		wave_timer_updated.emit(0.0, total_wave_enemies_to_spawn, current_alive)
		if spawn_queue.size() == 0 and current_alive == 0:
			_on_wave_cleared()

func trigger_immediate_next_wave() -> void:
	if not is_wave_active:
		wave_countdown = 0.0

func _get_alive_wave_enemies_count() -> int:
	var count = 0
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			if "is_wave_attacker" in e and e.is_wave_attacker:
				count += 1
	return count

func _start_next_wave() -> void:
	is_wave_active = true
	var monster_ids = MonsterDatabase.get_monsters_for_wave(current_wave)
	var is_boss_wave = (current_wave % 5 == 0)
	
	spawn_queue.clear()
	
	# 波次怪量隨波數提升 (波次 1 為 12 隻，波次 50 為 48+ 隻)
	var count = 12 + int(current_wave * 0.9)
	if is_boss_wave:
		count += 6
		
	for i in range(count):
		var m_id = monster_ids[i % monster_ids.size()]
		var m_data = MonsterDatabase.get_monster_by_id(m_id)
		spawn_queue.append(m_data)
		
	total_wave_enemies_to_spawn = spawn_queue.size()
	
	if is_boss_wave:
		var is_final = (current_wave >= 30)
		SoundManager.play_boss_bgm(is_final)
		EventBus.show_banner_notification.emit("⚠️ 四方領主突襲警報 ⚠️", "第 %d 波：強大 BOSS 與魔軍自四方裂隙大舉進攻！" % current_wave)
		SoundManager.play_crit()
		EventBus.screen_shake_requested.emit(15.0, 0.4)
	else:
		SoundManager.resume_normal_playlist()
		EventBus.show_banner_notification.emit("第 %d 波 四面八方魔潮來襲！" % current_wave, "魔物正自【西南/東北/西北/東南】四座城外裂隙湧出！")
		
	wave_started.emit(current_wave, is_boss_wave)

func _spawn_wave_monster(m_data: Dictionary) -> void:
	var enemy = enemy_base_scene.instantiate() as EnemyBase
	var gate_pos = SPAWN_GATES[randi() % SPAWN_GATES.size()]
	var offset = Vector2(randf_range(-40, 40), randf_range(-40, 40))
	enemy.global_position = gate_pos + offset
	enemy.is_wave_attacker = true
	
	var world_map = get_parent().get_node_or_null("WorldMap")
	if world_map:
		world_map.add_child(enemy)
	else:
		get_parent().add_child(enemy)
		
	# 根據地圖等級倍率與波次調整怪獸強度
	var base_lvl = current_wave
	if has_node("/root/MapManager"):
		var map_d = get_node("/root/MapManager").get_current_map()
		base_lvl = max(current_wave, map_d.get("level_min", 1))
	enemy.setup_from_monster_data(m_data, base_lvl)

func _on_wave_cleared() -> void:
	is_wave_active = false
	wave_cleared.emit(current_wave)
	
	# 給予波次結算獎勵
	var reward_gold = 150 + (current_wave * 70)
	var reward_exp = 120 + (current_wave * 60)
	Global.add_gold(reward_gold)
	Global.add_exp(reward_exp)
	
	EventBus.show_banner_notification.emit("第 %d 波 四方防守大捷！" % current_wave, "獲得結算獎勵: +%d G, +%d EXP！" % [reward_gold, reward_exp])
	SoundManager.play_level_up()
	
	# 每 5 波通關觸發一次天賦三選一並切換回常規音樂
	if current_wave % 5 == 0:
		SoundManager.resume_normal_playlist()
		var b_win = get_parent().get_node_or_null("CanvasLayer/BuffSelectionWindow")
		if b_win:
			b_win.open_selection()
		
	if current_wave >= MAX_WAVES:
		all_waves_completed.emit()
		EventBus.show_banner_notification.emit("🏆 傳奇守護者 🏆", "成功抵禦 50 波四方魔潮！拯救了全魔力寶貝世界！")
	else:
		current_wave += 1
		wave_countdown = 6.0 # 6 秒整備時間
