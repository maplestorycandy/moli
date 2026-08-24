extends "res://scripts/entities/EnemyBase.gd"

func _on_init_custom() -> void:
	stats.character_name = "史萊姆"
	stats.level = 1
	stats.max_hp = 80
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

func _draw() -> void:
	super._draw()
	# 史萊姆果凍動態彈跳
	var squish_x = 1.0 + sin(anim_timer * 6.0) * 0.15
	var squish_y = 1.0 - sin(anim_timer * 6.0) * 0.15
	
	draw_custom_ellipse(Vector2(0, 10), 12.0 * squish_x, 6.0, Color(0, 0, 0, 0.3))
	
	# 果凍本體 (翠綠水潤)
	var col = Color(0.2, 0.85, 0.45, 0.9)
	var highlight = Color(0.6, 1.0, 0.7, 0.95)
	
	var center = Vector2(0, 0)
	draw_circle(center, 12.0 * squish_x, col)
	draw_circle(center + Vector2(-3, -4), 4.0, highlight)
	
	# 經典水汪汪大眼睛
	draw_circle(center + Vector2(-4, 0), 2.5, Color.WHITE)
	draw_circle(center + Vector2(4, 0), 2.5, Color.WHITE)
	draw_circle(center + Vector2(-4, 0), 1.2, Color(0.1, 0.3, 0.1))
	draw_circle(center + Vector2(4, 0), 1.2, Color(0.1, 0.3, 0.1))

func draw_custom_ellipse(c: Vector2, rx: float, ry: float, color: Color) -> void:
	var points = PackedVector2Array()
	for i in range(20):
		var rad = (TAU / 20.0) * i
		points.append(c + Vector2(cos(rad) * rx, sin(rad) * ry))
	draw_colored_polygon(points, color)
