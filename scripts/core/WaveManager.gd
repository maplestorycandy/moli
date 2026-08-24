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

# 城外集中出怪傳送門座標 (東門城外荒野)
const OUTSIDE_INVASION_PORTAL = Vector2(1300, 500)

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
		# 急速隊列出怪 (0.15 秒急速湧出)
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
	
	# 波次怪量隨波數提升 (波次 1 為 8 隻，波次 50 為 35+ 隻)
	var count = 8 + int(current_wave * 0.9)
	if is_boss_wave:
		count += 5
		
	for i in range(count):
		var m_id = monster_ids[i % monster_ids.size()]
		var m_data = MonsterDatabase.get_monster_by_id(m_id)
		spawn_queue.append(m_data)
		
	total_wave_enemies_to_spawn = spawn_queue.size()
	
	if is_boss_wave:
		EventBus.show_banner_notification.emit("⚠️ 領主入侵警報 ⚠️", "第 %d 波：強大 BOSS 降臨城外裂隙！全軍備戰！" % current_wave)
		SoundManager.play_crit()
		EventBus.screen_shake_requested.emit(14.0, 0.4)
	else:
		EventBus.show_banner_notification.emit("第 %d 波 魔物衝鋒！" % current_wave, "魔物正自【城外魔界裂隙】蜂擁湧出衝向女神像！")
		
	wave_started.emit(current_wave, is_boss_wave)

func _spawn_wave_monster(m_data: Dictionary) -> void:
	var enemy = enemy_base_scene.instantiate() as EnemyBase
	var offset = Vector2(randf_range(-35, 35), randf_range(-35, 35))
	enemy.global_position = OUTSIDE_INVASION_PORTAL + offset
	enemy.is_wave_attacker = true
	get_parent().get_node("WorldMap").add_child(enemy)
	enemy.setup_from_monster_data(m_data, current_wave)

func _on_wave_cleared() -> void:
	is_wave_active = false
	wave_cleared.emit(current_wave)
	
	# 給予波次結算獎勵
	var reward_gold = 120 + (current_wave * 60)
	var reward_exp = 100 + (current_wave * 50)
	Global.add_gold(reward_gold)
	Global.add_exp(reward_exp)
	
	EventBus.show_banner_notification.emit("第 %d 波 防守成功！" % current_wave, "獲得獎勵: +%d G, +%d EXP！" % [reward_gold, reward_exp])
	SoundManager.play_level_up()
	
	# 每 5 波通關觸發一次天賦三選一
	if current_wave % 5 == 0:
		get_parent().get_node("CanvasLayer/BuffSelectionWindow").open_selection()
		
	if current_wave >= MAX_WAVES:
		all_waves_completed.emit()
		EventBus.show_banner_notification.emit("🏆 傳奇守護者 🏆", "恭喜成功防守全部 50 波！拯救了法蘭王國與愛謝拉女神！")
	else:
		current_wave += 1
		wave_countdown = 6.0 # 6 秒整備時間
