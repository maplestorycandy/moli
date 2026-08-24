extends Area2D
class_name HurtboxComponent

signal hit_received(damage: int, is_crit: bool, is_effective: bool, knockback_dir: Vector2, knockback_force: float)

@export var health_component: HealthComponent
@export var stats_component: StatsComponent
@export var is_player_team: bool = false
@export var invincible_time_after_hit: float = 0.25

var is_invulnerable: bool = false
var invul_timer: float = 0.0

func _process(delta: float) -> void:
	if is_invulnerable:
		invul_timer -= delta
		if invul_timer <= 0.0:
			is_invulnerable = false

func receive_hit(hitbox: HitboxComponent) -> void:
	if is_invulnerable:
		return
		
	var attacker = hitbox.attacker_node
	var attacker_atk = 20.0
	var attacker_crit = 0.05
	var attacker_elem_dist = {}
	
	if hitbox.custom_element_dist.size() > 0:
		attacker_elem_dist = hitbox.custom_element_dist
	elif hitbox.element_type != CombatMath.ElementType.NONE:
		attacker_elem_dist = { hitbox.element_type: 10 }
	elif attacker and "stats" in attacker and attacker.stats is StatsComponent:
		attacker_atk = float(attacker.stats.atk)
		attacker_crit = attacker.stats.crit_rate
		attacker_elem_dist = attacker.stats.element_dist
	elif attacker and attacker.is_in_group("player"):
		attacker_atk = float(Global.atk)
		attacker_crit = Global.crit_rate
		attacker_elem_dist = Global.player_crystal
		
	var defender_def = float(stats_component.def) if stats_component else 10.0
	var defender_elem_dist = stats_component.element_dist if stats_component else { CombatMath.ElementType.NONE: 10 }
	
	# 計算元素剋制倍率 (支援天賦: 四系全元素掌控)
	var elem_mod = CombatMath.calculate_element_advantage(attacker_elem_dist, defender_elem_dist)
	if elem_mod > 1.05 and BuffManager.has_buff("element_mastery"):
		elem_mod *= 1.45
		
	# 計算物理/魔法傷害
	var dmg_result = CombatMath.calculate_physical_damage(attacker_atk, defender_def, hitbox.damage_multiplier, elem_mod, attacker_crit)
	var final_damage = dmg_result["damage"]
	var is_crit = dmg_result["is_crit"]
	var is_effective = dmg_result["is_effective"]
	
	# 支援天賦: 嗜血暴擊汲取
	if is_crit and attacker and attacker.is_in_group("player") and BuffManager.has_buff("lifesteal"):
		var heal_val = int(final_damage * 0.25)
		if heal_val > 0:
			Global.hp = min(Global.max_hp, Global.hp + heal_val)
			EventBus.player_health_changed.emit(Global.hp, Global.max_hp)
			EventBus.damage_spawned.emit(Global.player.global_position, "+%d HP" % heal_val, Color(0.2, 1.0, 0.4), false, false)
	
	if health_component:
		health_component.take_damage(final_damage, is_crit, is_effective, attacker)
		
	# 擊退方向
	var knockback_dir = Vector2.ZERO
	if attacker:
		knockback_dir = (global_position - attacker.global_position).normalized()
		
	# 飄字事件
	var spawn_pos = global_position + Vector2(randf_range(-15, 15), randf_range(-30, -10))
	var color = Color(1.0, 1.0, 1.0)
	if is_player_team:
		color = Color(1.0, 0.3, 0.3) # 玩家受傷紅字
	elif is_crit:
		color = Color(1.0, 0.85, 0.1) # 爆擊黃金字
	elif is_effective:
		color = Color(1.0, 0.4, 0.1) # 元素剋制大增傷橙紅字
		
	var dmg_text = str(final_damage)
	if is_crit:
		dmg_text = "💥" + dmg_text + "!"
		
	EventBus.damage_spawned.emit(spawn_pos, dmg_text, color, is_crit, is_effective)
	
	# 音效
	if is_crit:
		SoundManager.play_crit()
		EventBus.screen_shake_requested.emit(8.0, 0.2)
	else:
		SoundManager.play_hit()
		
	# 合擊判定 (若寵物與玩家接連攻擊同個目標)
	if attacker and attacker.is_in_group("pet") and Global.player:
		if (global_position - Global.player.global_position).length() < 160.0:
			EventBus.combo_dual_attack_triggered.emit(global_position)
			
	# 無敵幀保護
	is_invulnerable = true
	invul_timer = invincible_time_after_hit
	
	hit_received.emit(final_damage, is_crit, is_effective, knockback_dir, hitbox.knockback_force)
