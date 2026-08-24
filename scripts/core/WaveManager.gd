extends Node

const MonsterDatabase = preload("res://scripts/data/MonsterDatabase.gd")
const EnemyBase = preload("res://scripts/entities/EnemyBase.gd")

signal wave_started(wave_num: int, is_boss: bool)
signal wave_cleared(wave_num: int)
signal all_waves_completed()
signal wave_timer_updated(time_left: float, total_monsters: int, remaining: int)

var current_wave: int = 1
const MAX_WAVES = 1000

var is_wave_active: bool = false
var wave_countdown: float = 6.0
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
		if spawn_queue.size() > 0:
			spawn_interval_timer -= delta
			if spawn_interval_timer <= 0.0:
				spawn_interval_timer = 0.04 # 極速出怪 (0.04s)
				# 每次自四方裂隙同時湧出 2~3 隻
				var spawn_batch = min(3, spawn_queue.size())
				for s in range(spawn_batch):
					var m_data = spawn_queue.pop_front()
					_spawn_wave_monster(m_data)
				
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
	
	# 怪物量提升 3 倍 (初波即有 36~40+ 隻，隨波次逐步攀升至 120 隻超大魔潮)
	var count = min(120, int((12 + current_wave * 0.45) * 3.0))
	if is_boss_wave:
		count += 15
		
	for i in range(count):
		var m_id = monster_ids[i % monster_ids.size()]
		var m_data = MonsterDatabase.get_monster_by_id(m_id)
		spawn_queue.append(m_data)
		
	total_wave_enemies_to_spawn = spawn_queue.size()
	
	SoundManager.play_for_wave(current_wave)
	
	if is_boss_wave:
		var boss_data = MonsterDatabase.get_monster_by_id(monster_ids[0])
		var b_name = boss_data.get("name", "強大 BOSS")
		EventBus.show_banner_notification.emit("⚠️ 主線領主決戰降臨 ⚠️", "第 %d 波：【%s】率領魔軍自四方裂隙突襲！" % [current_wave, b_name])
		SoundManager.play_crit()
		EventBus.screen_shake_requested.emit(18.0, 0.45)
	else:
		EventBus.show_banner_notification.emit("第 %d 波 魔力全圖鑑魔潮來襲！" % current_wave, "魔物正自【西南/東北/西北/東南】四座城外裂隙湧出！")
		
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
		
	var base_lvl = current_wave
	if has_node("/root/MapManager"):
		var map_d = get_node("/root/MapManager").get_current_map()
		base_lvl = max(current_wave, map_d.get("level_min", 1))
	enemy.setup_from_monster_data(m_data, base_lvl)

func _on_wave_cleared() -> void:
	is_wave_active = false
	wave_cleared.emit(current_wave)
	
	var reward_gold = 200 + (current_wave * 50)
	var reward_exp = 150 + (current_wave * 40)
	Global.add_gold(reward_gold)
	Global.add_exp(reward_exp)
	
	EventBus.show_banner_notification.emit("第 %d 波 四方防守大捷！" % current_wave, "獲得結算獎勵: +%d G, +%d EXP！" % [reward_gold, reward_exp])
	SoundManager.play_level_up()
	
	if current_wave % 5 == 0:
		SoundManager.resume_normal_playlist()
		var b_win = get_parent().get_node_or_null("CanvasLayer/BuffSelectionWindow")
		if b_win:
			b_win.open_selection()
		
	if current_wave >= MAX_WAVES:
		all_waves_completed.emit()
		EventBus.show_banner_notification.emit("🏆 傳奇守護者 🏆", "成功抵禦 1000 波四方魔潮！拯救了全魔力寶貝世界！")
	else:
		current_wave += 1
		wave_countdown = 5.0
