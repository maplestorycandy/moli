extends "res://scripts/entities/EnemyBase.gd"

func _on_init_custom() -> void:
	stats.character_name = "哥布林"
	stats.level = 2
	stats.max_hp = 120
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

func _draw() -> void:
	super._draw()
	var bounce = sin(anim_timer * 8.0) * 1.5
	draw_custom_ellipse(Vector2(0, 10), 12.0, 6.0, Color(0, 0, 0, 0.3))
	
	var skin_col = Color(0.2, 0.7, 0.3)
	# 身體
	draw_circle(Vector2(0, 0 + bounce), 10.0, skin_col)
	# 獸皮短褲
	draw_circle(Vector2(0, 3 + bounce), 7.0, Color(0.4, 0.25, 0.1))
	# 大頭與尖耳
	draw_circle(Vector2(0, -9 + bounce), 8.0, skin_col)
	draw_line(Vector2(-6, -9 + bounce), Vector2(-13, -13 + bounce), skin_col, 2.5)
	draw_line(Vector2(6, -9 + bounce), Vector2(13, -13 + bounce), skin_col, 2.5)
	# 邪惡黃眼
	draw_circle(Vector2(-3, -10 + bounce), 2.0, Color(1.0, 0.9, 0.2))
	draw_circle(Vector2(3, -10 + bounce), 2.0, Color(1.0, 0.9, 0.2))
	draw_circle(Vector2(-3, -10 + bounce), 1.0, Color.BLACK)
	draw_circle(Vector2(3, -10 + bounce), 1.0, Color.BLACK)
	# 木棒狼牙棒
	draw_line(Vector2(7, 2 + bounce), Vector2(14, -8 + bounce), Color(0.45, 0.3, 0.15), 3.5)

func draw_custom_ellipse(c: Vector2, rx: float, ry: float, color: Color) -> void:
	var points = PackedVector2Array()
	for i in range(20):
		var rad = (TAU / 20.0) * i
		points.append(c + Vector2(cos(rad) * rx, sin(rad) * ry))
	draw_colored_polygon(points, color)
