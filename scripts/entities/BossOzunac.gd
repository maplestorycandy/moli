extends "res://scripts/entities/EnemyBase.gd"

var special_attack_cooldown: float = 4.0
var boss_phase: int = 1

func _on_init_custom() -> void:
	stats.character_name = "熱砂之歐茲那克"
	stats.level = 10
	stats.max_hp = 22500
	stats.max_mp = 500
	stats.atk = 85
	stats.def = 45
	stats.move_speed = 130.0
	stats.race = "邪魔系"
	stats.element_dist = {
		CombatMath.ElementType.EARTH: 5,
		CombatMath.ElementType.FIRE: 5
	}
	stats.seal_tier = CombatMath.SealCardTier.GOLD
	stats.exp_reward = 350
	stats.gold_reward_min = 200
	stats.gold_reward_max = 500
	is_boss = true
	monster_scale = 1.4
