extends "res://scripts/entities/EnemyBase.gd"

func _on_init_custom() -> void:
	stats.character_name = "樹精"
	stats.level = 3
	stats.max_hp = 15000
	stats.max_mp = 60
	stats.atk = 28
	stats.def = 22
	stats.move_speed = 70.0
	stats.race = "植物系"
	stats.element_dist = {
		CombatMath.ElementType.EARTH: 8,
		CombatMath.ElementType.WATER: 2
	}
	stats.seal_tier = CombatMath.SealCardTier.SILVER
	stats.exp_reward = 50
	stats.gold_reward_min = 25
	stats.gold_reward_max = 60
