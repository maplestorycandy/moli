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
	var attacker_atk = float(Global.atk) if hitbox.is_player_team else 25.0
	var attacker_crit = Global.crit_rate if hitbox.is_player_team else 0.05
	var attacker_elem_dist = Global.player_crystal if hitbox.is_player_team else {}
	
	if hitbox.custom_element_dist.size() > 0:
		attacker_elem_dist = hitbox.custom_element_dist
	elif hitbox.element_type != CombatMath.ElementType.NONE:
		attacker_elem_dist = { hitbox.element_type: 10 }
	elif attacker and "stats" in attacker and attacker.stats is StatsComponent:
		attacker_atk = float(attacker.stats.atk)
		attacker_crit = attacker.stats.crit_rate
		attacker_elem_dist = attacker.stats.element_dist
		
	var defender_def = float(stats_component.def) if stats_component else 10.0
	var defender_elem_dist = stats_component.element_dist if stats_component else { CombatMath.ElementType.NONE: 10 }
	
	# 元素剋制倍率
	var elem_mod = CombatMath.calculate_element_advantage(attacker_elem_dist, defender_elem_dist)
	if elem_mod > 1.05 and BuffManager.has_buff("element_mastery"):
		elem_mod *= 1.45
		
	var is_crit = (randf() < attacker_crit)
	var is_effective = (elem_mod >= 1.2)
	
	# 真正高額傷害計算 (保證技能發揮數倍毀滅威力)
	var mult = max(1.0, hitbox.damage_multiplier)
	var raw_dmg = (attacker_atk * 1.2 - defender_def * 0.35) * mult * elem_mod
	var final_damage = int(max(attacker_atk * mult * 0.6, raw_dmg))
	if is_crit:
		final_damage = int(final_damage * 1.85)
	
	# 嗜血暴擊天賦
	if is_crit and hitbox.is_player_team and BuffManager.has_buff("lifesteal"):
		var heal_val = int(final_damage * 0.25)
		if heal_val > 0:
			Global.heal(heal_val)
			EventBus.damage_spawned.emit(Global.player.global_position, "+%d HP" % heal_val, Color(0.2, 1.0, 0.4), false, false)
	
	if health_component:
		health_component.take_damage(final_damage, is_crit, is_effective, attacker)
		
	var knockback_dir = Vector2.ZERO
	if attacker:
		knockback_dir = (global_position - attacker.global_position).normalized()
	elif hitbox:
		knockback_dir = (global_position - hitbox.global_position).normalized()
		
	# 飄字事件
	var spawn_pos = global_position + Vector2(randf_range(-15, 15), randf_range(-30, -10))
	var color = Color(1.0, 1.0, 1.0)
	if is_player_team:
		color = Color(1.0, 0.3, 0.3)
	elif is_crit:
		color = Color(1.0, 0.85, 0.1)
	elif is_effective:
		color = Color(1.0, 0.4, 0.1)
		
	var dmg_text = str(final_damage)
	if is_crit:
		dmg_text = "💥" + dmg_text + "!"
		
	EventBus.damage_spawned.emit(spawn_pos, dmg_text, color, is_crit, is_effective)
	
	if is_crit:
		SoundManager.play_crit()
		EventBus.screen_shake_requested.emit(8.0, 0.2)
	else:
		SoundManager.play_hit()
		
	if attacker and attacker.is_in_group("pet") and Global.player:
		if (global_position - Global.player.global_position).length() < 160.0:
			EventBus.combo_dual_attack_triggered.emit(global_position)
			
	is_invulnerable = true
	invul_timer = invincible_time_after_hit
	
	hit_received.emit(final_damage, is_crit, is_effective, knockback_dir, hitbox.knockback_force)
