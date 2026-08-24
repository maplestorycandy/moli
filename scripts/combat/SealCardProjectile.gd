extends Node2D

@export var speed: float = 400.0
var target_pos: Vector2
var card_tier: CombatMath.SealCardTier = CombatMath.SealCardTier.NORMAL
var card_name: String = "普卡封印卡"
var thrower: Node = null

var state: String = "FLYING" # FLYING, SEALING, SUCCESS, FAILED
var target_enemy: Node2D = null
var timer: float = 0.0
var seal_stage: int = 0 # 0, 1, 2, 3 shakes
var card_color: Color = Color(0.85, 0.85, 0.9)
var success_rate: float = 0.5
var will_succeed: bool = false

func setup(target_p: Vector2, tier: CombatMath.SealCardTier, c_name: String, thrower_node: Node) -> void:
	target_pos = target_p
	card_tier = tier
	card_name = c_name
	thrower = thrower_node
	
	if card_tier == CombatMath.SealCardTier.SILVER:
		card_color = Color(0.7, 0.9, 1.0)
	elif card_tier == CombatMath.SealCardTier.GOLD:
		card_color = Color(1.0, 0.85, 0.2)
		
	SoundManager.play_seal_throw()

func _physics_process(delta: float) -> void:
	if state == "FLYING":
		var to_target = target_pos - global_position
		rotation += 15.0 * delta
		if to_target.length() < 15.0:
			# 到達目標位置，尋找最近的敵人進行捕捉
			_find_and_begin_seal()
		else:
			global_position += to_target.normalized() * speed * delta
			
	elif state == "SEALING":
		timer += delta
		if is_instance_valid(target_enemy):
			target_enemy.global_position = global_position
			if target_enemy.has_method("set_stunned"):
				target_enemy.set_stunned(true)
				
		# 3次封印晃動判定節奏 (魔力寶貝經典封印掙扎)
		if timer >= 0.5 and seal_stage == 0:
			seal_stage = 1
			SoundManager.play_swing()
			EventBus.damage_spawned.emit(global_position + Vector2(0, -30), "封印中...", Color(1.0, 0.9, 0.3), false, false)
		elif timer >= 1.0 and seal_stage == 1:
			seal_stage = 2
			SoundManager.play_swing()
		elif timer >= 1.5 and seal_stage == 2:
			seal_stage = 3
			SoundManager.play_swing()
		elif timer >= 2.0:
			# 結算結果
			if will_succeed:
				_on_seal_success()
			else:
				_on_seal_failed()
				
	elif state == "SUCCESS" or state == "FAILED":
		timer += delta
		if timer >= 0.8:
			queue_free()
			
	queue_redraw()

func _find_and_begin_seal() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var min_dist = 120.0
	for e in enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			var d = global_position.distance_to(e.global_position)
			if d < min_dist:
				min_dist = d
				closest = e
				
	if closest and closest.has_node("StatsComponent") and closest.has_node("HealthComponent"):
		target_enemy = closest
		global_position = closest.global_position
		state = "SEALING"
		timer = 0.0
		
		var stats = closest.get_node("StatsComponent") as StatsComponent
		var health = closest.get_node("HealthComponent") as HealthComponent
		
		var player_lvl = Global.player_level
		var monster_lvl = stats.level
		var hp_ratio = health.get_hp_ratio()
		
		success_rate = CombatMath.calculate_seal_success_rate(card_tier, stats.seal_tier, player_lvl, monster_lvl, hp_ratio)
		will_succeed = randf() < success_rate
		
		EventBus.show_banner_notification.emit("發動封印！", "封印成功率預估: %d%%" % int(success_rate * 100))
	else:
		# 空拋未中目標
		EventBus.damage_spawned.emit(global_position, "未命中目標", Color(0.7, 0.7, 0.7), false, false)
		state = "FAILED"
		timer = 0.0

func _on_seal_success() -> void:
	state = "SUCCESS"
	timer = 0.0
	SoundManager.play_seal_success()
	
	if is_instance_valid(target_enemy):
		var stats = target_enemy.get_node_or_null("StatsComponent") as StatsComponent
		var pet_name = stats.character_name if stats else "野生魔物"
		var m_data = target_enemy.get("monster_data") if "monster_data" in target_enemy else {}
		
		# 創建新寵物資料加入背包 (保留完整外觀繪製參數)
		var new_pet = {
			"id": "pet_" + str(Time.get_unix_time_from_system()) + "_" + str(randi() % 1000),
			"name": pet_name,
			"title": "野生封印",
			"level": stats.level if stats else 1,
			"exp": 0,
			"max_exp": 70,
			"race": stats.race if stats else "特殊系",
			"element": stats.element_dist.duplicate() if stats else { CombatMath.ElementType.NONE: 10 },
			"element_desc": "原生屬性",
			"hp": int((stats.max_hp if stats else 100) * 0.9),
			"max_hp": int((stats.max_hp if stats else 100) * 0.9),
			"mp": stats.max_mp if stats else 50,
			"max_mp": stats.max_mp if stats else 50,
			"atk": int((stats.atk if stats else 20) * 0.95),
			"def": int((stats.def if stats else 10) * 0.95),
			"agi": 22,
			"spirit": stats.spirit if stats else 90,
			"loyalty": 85,
			"grade_loss": randi_range(0, 4), # 掉檔 0~4
			"active_skill": "普通攻擊",
			"drawer_type": target_enemy.get("drawer_type") if "drawer_type" in target_enemy else "slime",
			"color_main": target_enemy.get("color_main") if "color_main" in target_enemy else Color.GREEN,
			"color_sub": target_enemy.get("color_sub") if "color_sub" in target_enemy else Color.WHITE,
			"scale": target_enemy.get("monster_scale") if "monster_scale" in target_enemy else 1.0
		}
		
		Global.add_pet(new_pet)
		EventBus.seal_attempt_result.emit(true, pet_name, card_name)
		EventBus.damage_spawned.emit(global_position, "✨ 封印成功！", Color(1.0, 0.9, 0.1), true, true)
		
		target_enemy.remove_from_group("enemies")
		target_enemy.queue_free()

func _on_seal_failed() -> void:
	state = "FAILED"
	timer = 0.0
	SoundManager.play_seal_fail()
	if is_instance_valid(target_enemy):
		if target_enemy.has_method("set_stunned"):
			target_enemy.set_stunned(false)
		if "ai_state" in target_enemy:
			target_enemy.ai_state = 0 # IDLE / CHASE
		var stats = target_enemy.get_node_or_null("StatsComponent") as StatsComponent
		EventBus.seal_attempt_result.emit(false, stats.character_name if stats else "目標", card_name)
		EventBus.damage_spawned.emit(global_position, "封印失敗！", Color(1.0, 0.2, 0.2), false, false)

func _draw() -> void:
	if state == "FLYING":
		# 旋轉飛行的封印卡 (卡牌外框 + 寶石)
		draw_rect(Rect2(-12, -18, 24, 36), card_color, true)
		draw_rect(Rect2(-12, -18, 24, 36), Color(0.2, 0.2, 0.2), false, 2.0)
		draw_circle(Vector2.ZERO, 5.0, Color(0.2, 0.6, 1.0))
		
	elif state == "SEALING":
		# 六芒星封印陣束縛敵人
		var pulse = sin(timer * 12.0) * 4.0
		var r = 48.0 + pulse
		var color = card_color
		color.a = 0.75
		draw_arc(Vector2.ZERO, r, 0, TAU, 32, color, 3.0)
		for i in range(6):
			var a = (TAU / 6.0) * i + timer * 2.0
			var p1 = Vector2.from_angle(a) * r
			var p2 = Vector2.from_angle(a + PI) * r
			draw_line(p1, p2, color, 1.5)
			
	elif state == "SUCCESS":
		# 金色光芒晶體化
		var r = 30.0 * (1.0 - timer / 0.8)
		draw_circle(Vector2.ZERO, r, Color(1.0, 0.9, 0.3, 0.8))
		draw_circle(Vector2.ZERO, r * 0.6, Color.WHITE)
