extends Node

# 玩家已獲得的天賦清單 (buff_id -> stack_count)
var active_buffs: Dictionary = {}

# 定時器
var timer_auto_force_strike: float = 0.0
var timer_auto_ki_blast: float = 0.0
var timer_auto_meteor: float = 0.0
var timer_frost_ring: float = 0.0

# 預載技能投射物
var kiblast_scene = preload("res://scenes/combat/KiBlastProjectile.tscn")
var meteor_scene = preload("res://scenes/combat/MeteorStrike.tscn")

# 完整天賦資料庫
const BUFF_POOL = [
	{
		"id": "auto_ki_blast",
		"name": "天賦【四方氣功彈】",
		"icon": "🔮",
		"desc": "【自動施法】每隔 2.5 秒自動向東南西北四方轟出 4 枚貫穿氣功彈！",
		"tier": "RARE",
		"color": Color(1.0, 0.85, 0.2)
	},
	{
		"id": "auto_force_strike",
		"name": "天賦【真·乾坤破空】",
		"icon": "💥",
		"desc": "【自動施法】每隔 3.5 秒自動鎖定最近敵人發動 320% 霸體乾坤一擲！",
		"tier": "EPIC",
		"color": Color(1.0, 0.4, 0.1)
	},
	{
		"id": "auto_meteor",
		"name": "天賦【天降神罰隕石】",
		"icon": "☄️",
		"desc": "【自動施法】每隔 5 秒自動在敵人密集處召喚巨型地屬性隕石轟炸！",
		"tier": "LEGENDARY",
		"color": Color(0.9, 0.6, 0.1)
	},
	{
		"id": "frost_ring",
		"name": "天賦【極凍冰霜之環】",
		"icon": "❄️",
		"desc": "【自動施法】每隔 4 秒在自身周圍引爆大範圍冰環，造成水屬性傷害並擊退！",
		"tier": "RARE",
		"color": Color(0.3, 0.8, 1.0)
	},
	{
		"id": "combo_frenzy",
		"name": "天賦【連擊·無盡狂暴】",
		"icon": "⚔️",
		"desc": "【戰鬥強化】手動【連擊】斬擊次數提升至 6 段，傷害大幅提升！",
		"tier": "EPIC",
		"color": Color(0.3, 1.0, 0.8)
	},
	{
		"id": "element_mastery",
		"name": "天賦【四系全元素掌控】",
		"icon": "💎",
		"desc": "【數值強化】地水火風屬性相剋增傷由 30% 暴增至 75%！",
		"tier": "EPIC",
		"color": Color(0.8, 0.4, 1.0)
	},
	{
		"id": "lifesteal",
		"name": "天賦【嗜血暴擊汲取】",
		"icon": "🩸",
		"desc": "【生存強化】每次暴擊時將造成傷害的 25% 轉化為自身生命恢復！",
		"tier": "RARE",
		"color": Color(1.0, 0.2, 0.3)
	},
	{
		"id": "shadow_roll",
		"name": "天賦【神行幻影步】",
		"icon": "🌪️",
		"desc": "【動作強化】翻滾無敵時間延長 100%，並在原地留下誘敵自爆殘影！",
		"tier": "RARE",
		"color": Color(0.5, 0.9, 1.0)
	},
	{
		"id": "pet_resonance",
		"name": "天賦【寵物狂化共鳴】",
		"icon": "🐾",
		"desc": "【寵物強化】寵物攻擊力與攻速 +80%，且與玩家的合擊觸發機率 100%！",
		"tier": "EPIC",
		"color": Color(0.4, 1.0, 0.5)
	},
	{
		"id": "gold_master",
		"name": "天賦【神之封印財富】",
		"icon": "👑",
		"desc": "【資源強化】封印成功率 +30%，怪物掉落魔石與金幣數量 +100%！",
		"tier": "RARE",
		"color": Color(1.0, 0.9, 0.2)
	}
]

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if not Global.player or not is_instance_valid(Global.player):
		return
		
	# 1. 自動氣功彈
	if has_buff("auto_ki_blast"):
		timer_auto_ki_blast += delta
		if timer_auto_ki_blast >= 2.5:
			timer_auto_ki_blast = 0.0
			_trigger_auto_ki_blast()
			
	# 2. 自動乾坤一擲
	if has_buff("auto_force_strike"):
		timer_auto_force_strike += delta
		if timer_auto_force_strike >= 3.5:
			timer_auto_force_strike = 0.0
			_trigger_auto_force_strike()
			
	# 3. 自動超強隕石
	if has_buff("auto_meteor"):
		timer_auto_meteor += delta
		if timer_auto_meteor >= 5.0:
			timer_auto_meteor = 0.0
			_trigger_auto_meteor()
			
	# 4. 極凍冰環
	if has_buff("frost_ring"):
		timer_frost_ring += delta
		if timer_frost_ring >= 4.0:
			timer_frost_ring = 0.0
			_trigger_frost_ring()

func has_buff(id: String) -> bool:
	return active_buffs.has(id) and active_buffs[id] > 0

func add_buff(id: String) -> void:
	if active_buffs.has(id):
		active_buffs[id] += 1
	else:
		active_buffs[id] = 1
		
	for b in BUFF_POOL:
		if b["id"] == id:
			EventBus.show_banner_notification.emit("解鎖特殊天賦！", "已獲得【%s】！" % b["name"])
			SoundManager.play_level_up()
			break

func get_3_random_buffs() -> Array[Dictionary]:
	var pool_copy = BUFF_POOL.duplicate()
	pool_copy.shuffle()
	var res: Array[Dictionary] = []
	for i in range(min(3, pool_copy.size())):
		res.append(pool_copy[i])
	return res

# --- 自動施法邏輯 ---

func _trigger_auto_ki_blast() -> void:
	if not Global.player: return
	var p_pos = Global.player.global_position
	var dirs = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
	SoundManager.play_swing()
	EventBus.damage_spawned.emit(p_pos + Vector2(0, -35), "⚡【天賦 氣功波】", Color(1.0, 0.9, 0.2), false, false)
	for d in dirs:
		var proj = kiblast_scene.instantiate()
		proj.global_position = p_pos + d * 20
		Global.player.get_parent().add_child(proj)
		proj.setup(d, Global.player)

func _trigger_auto_force_strike() -> void:
	if not Global.player: return
	var nearest_enemy = _find_nearest_enemy(Global.player.global_position)
	if not nearest_enemy: return
	
	var dir = (nearest_enemy.global_position - Global.player.global_position).normalized()
	EventBus.damage_spawned.emit(nearest_enemy.global_position + Vector2(0, -30), "💥【天賦 乾坤重擊！】", Color(1.0, 0.4, 0.1), true, true)
	SoundManager.play_crit()
	EventBus.screen_shake_requested.emit(10.0, 0.2)
	
	if nearest_enemy.has_node("HurtboxComponent"):
		var hb = nearest_enemy.get_node("HurtboxComponent")
		if hb.has_method("receive_hit"):
			var fake_hitbox = HitboxComponent.new()
			fake_hitbox.damage_multiplier = 3.5
			fake_hitbox.attacker_node = Global.player
			fake_hitbox.is_player_team = true
			fake_hitbox.knockback_force = 220.0
			hb.receive_hit(fake_hitbox)
			fake_hitbox.queue_free()

func _trigger_auto_meteor() -> void:
	if not Global.player: return
	var target_enemy = _find_nearest_enemy(Global.player.global_position)
	var spawn_p = target_enemy.global_position if target_enemy else Global.player.global_position + Vector2(100, 0)
	
	EventBus.damage_spawned.emit(spawn_p + Vector2(0, -40), "☄️【天賦 降世隕石】", Color(0.9, 0.6, 0.1), false, false)
	var spell = meteor_scene.instantiate()
	Global.player.get_parent().add_child(spell)
	spell.setup(spawn_p, Global.player)

func _trigger_frost_ring() -> void:
	if not Global.player: return
	var p_pos = Global.player.global_position
	EventBus.damage_spawned.emit(p_pos + Vector2(0, -35), "❄️【天賦 極凍冰環】", Color(0.3, 0.8, 1.0), false, false)
	SoundManager.play_magic()
	
	# 冰環爆破傷害周圍 160px 敵人
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and e.global_position.distance_to(p_pos) <= 170.0:
			if e.has_node("HurtboxComponent"):
				var hb = e.get_node("HurtboxComponent")
				var fake_hitbox = HitboxComponent.new()
				fake_hitbox.damage_multiplier = 2.0
				fake_hitbox.element_type = CombatMath.ElementType.WATER
				fake_hitbox.attacker_node = Global.player
				fake_hitbox.is_player_team = true
				fake_hitbox.knockback_force = 200.0
				hb.receive_hit(fake_hitbox)
				fake_hitbox.queue_free()

func _find_nearest_enemy(from_pos: Vector2) -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var min_dist = 400.0
	for e in enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			var d = from_pos.distance_to(e.global_position)
			if d < min_dist:
				min_dist = d
				closest = e
	return closest
