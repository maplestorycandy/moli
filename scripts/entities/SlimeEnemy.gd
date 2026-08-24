extends "res://scripts/entities/EnemyBase.gd"

func _on_init_custom() -> void:
	stats.character_name = "史萊姆"
	stats.level = 1
	stats.max_hp = 1200
	stats.max_mp = 40
	stats.atk = 16
	stats.def = 8
	stats.move_speed = 90.0
	stats.race = "特殊系"
	stats.element_dist = {
		CombatMath.ElementType.WATER: 8,
		CombatMath.ElementType.FIRE: 2
	}
	stats.seal_tier = CombatMath.SealCardTier.NORMAL
	stats.exp_reward = 20
	stats.gold_reward_min = 8
	stats.gold_reward_max = 20
