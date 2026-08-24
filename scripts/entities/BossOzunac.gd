extends "res://scripts/entities/EnemyBase.gd"

var special_attack_cooldown: float = 4.0
var boss_phase: int = 1
var is_whirlwind: bool = false
var whirlwind_timer: float = 0.0

func _on_init_custom() -> void:
	stats.character_name = "熱砂之歐茲那克"
	stats.level = 10
	stats.max_hp = 1200
	stats.max_mp = 300
	stats.atk = 45
	stats.def = 30
	stats.move_speed = 100.0
	stats.race = "人形系"
	stats.element_dist = {
		CombatMath.ElementType.EARTH: 5,
		CombatMath.ElementType.WATER: 5
	}
	stats.seal_tier = CombatMath.SealCardTier.GOLD
	stats.exp_reward = 350
	stats.gold_reward_min = 500
	stats.gold_reward_max = 1200

func _physics_process(delta: float) -> void:
	special_attack_cooldown -= delta
	
	if is_whirlwind:
		whirlwind_timer -= delta
		if target and is_instance_valid(target):
			var dir = (target.global_position - global_position).normalized()
			velocity = dir * (stats.move_speed * 1.5)
			move_and_slide()
		if whirlwind_timer <= 0.0:
			is_whirlwind = false
			hitbox_collision.disabled = true
		return
		
	# 觸發 BOSS 技能: 乾坤一擲 或 旋風斬
	if ai_state == AIState.CHASE and special_attack_cooldown <= 0.0 and target:
		var dist = global_position.distance_to(target.global_position)
		if dist <= 120.0:
			if randf() < 0.5:
				_start_boss_force_strike()
			else:
				_start_boss_whirlwind()
			return
			
	super._physics_process(delta)

func _start_boss_force_strike() -> void:
	special_attack_cooldown = 6.0
	ai_state = AIState.ATTACK
	state_timer = 0.0
	attack_cooldown = 2.5
	
	EventBus.damage_spawned.emit(global_position + Vector2(0, -45), "【歐茲那克 乾坤一擲！】", Color(1.0, 0.3, 0.1), true, true)
	EventBus.screen_shake_requested.emit(8.0, 0.3)

func _start_boss_whirlwind() -> void:
	special_attack_cooldown = 8.0
	is_whirlwind = true
	whirlwind_timer = 2.2
	hitbox.damage_multiplier = 1.2
	hitbox.reset_hit_list()
	hitbox_collision.disabled = false
	EventBus.damage_spawned.emit(global_position + Vector2(0, -45), "【狂暴旋風斬！】", Color(1.0, 0.8, 0.2), true, false)

func _spawn_drops() -> void:
	super._spawn_drops()
	
	# 必掉【金卡封印卡】
	var d = drop_item_scene.instantiate()
	d.global_position = global_position + Vector2(15, 0)
	get_parent().add_child(d)
	d.setup("seal_card_gold", "金卡封印卡", "seal_card", 1, 0, Color(1.0, 0.85, 0.2))
	
	# 必掉【巨型魔石】
	var d2 = drop_item_scene.instantiate()
	d2.global_position = global_position + Vector2(-15, 0)
	get_parent().add_child(d2)
	d2.setup("magic_stone_large", "純淨大魔石", "material", 1, 0, Color(0.8, 0.4, 1.0))
	
	EventBus.show_banner_notification.emit("討伐成功！", "已成功擊敗守門人【熱砂之歐茲那克】！")

func _draw() -> void:
	super._draw()
	var bounce = sin(anim_timer * 6.0) * 2.0
	draw_custom_ellipse(Vector2(0, 20), 22.0, 10.0, Color(0, 0, 0, 0.4))
	
	# 巨型身軀 (赤褐色肌肉巨漢 + 熊皮毛披肩)
	# 披風毛皮
	draw_circle(Vector2(0, 4), 18.0, Color(0.35, 0.2, 0.1))
	# 身體
	draw_circle(Vector2(0, 2), 16.0, Color(0.8, 0.5, 0.35))
	# 鋼鐵肩甲與腰帶
	draw_circle(Vector2(-12, -4), 7.0, Color(0.7, 0.75, 0.8))
	draw_circle(Vector2(12, -4), 7.0, Color(0.7, 0.75, 0.8))
	draw_rect(Rect2(-12, 6, 24, 6), Color(0.9, 0.7, 0.1))
	
	# 頭部與狂野黑髮鬍鬚
	draw_circle(Vector2(0, -12), 12.0, Color(0.15, 0.15, 0.15))
	draw_circle(Vector2(0, -10), 9.0, Color(0.8, 0.5, 0.35))
	# 兇悍血眼
	draw_circle(Vector2(-4, -10), 2.5, Color(1.0, 0.1, 0.1))
	draw_circle(Vector2(4, -10), 2.5, Color(1.0, 0.1, 0.1))
	
	# 巨型戰斧
	if is_whirlwind:
		var spin_a = anim_timer * 20.0
		var axe_tip = Vector2.from_angle(spin_a) * 38.0
		draw_line(Vector2.ZERO, axe_tip, Color(0.8, 0.85, 0.9), 6.0)
		draw_arc(Vector2.ZERO, 38.0, 0, TAU, 24, Color(1.0, 0.3, 0.1, 0.8), 4.0)
	else:
		var axe_h = Vector2(16, 2 + bounce)
		var axe_t = axe_h + Vector2(12, -22)
		draw_line(axe_h, axe_t, Color(0.4, 0.25, 0.15), 4.0) # 木柄
		draw_circle(axe_t, 10.0, Color(0.75, 0.8, 0.85)) # 雙刃斧頭

func draw_custom_ellipse(c: Vector2, rx: float, ry: float, color: Color) -> void:
	var points = PackedVector2Array()
	for i in range(24):
		var rad = (TAU / 24.0) * i
		points.append(c + Vector2(cos(rad) * rx, sin(rad) * ry))
	draw_colored_polygon(points, color)
