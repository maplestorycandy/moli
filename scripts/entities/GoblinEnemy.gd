extends "res://scripts/entities/EnemyBase.gd"

func _on_init_custom() -> void:
	stats.character_name = "哥布林"
	stats.level = 2
	stats.max_hp = 360
	stats.max_mp = 50
	stats.atk = 24
	stats.def = 12
	stats.move_speed = 110.0
	stats.race = "人形系"
	stats.element_dist = {
		CombatMath.ElementType.EARTH: 7,
		CombatMath.ElementType.WIND: 3
	}
	stats.seal_tier = CombatMath.SealCardTier.NORMAL
	stats.exp_reward = 35
	stats.gold_reward_min = 15
	stats.gold_reward_max = 40
