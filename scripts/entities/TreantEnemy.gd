extends "res://scripts/entities/EnemyBase.gd"

func _on_init_custom() -> void:
	stats.character_name = "樹精"
	stats.level = 3
	stats.max_hp = 220
	stats.max_mp = 80
	stats.atk = 28
	stats.def = 25
	stats.move_speed = 70.0
	stats.race = "植物系"
	stats.element_dist = {
		CombatMath.ElementType.EARTH: 10
	}
	stats.seal_tier = CombatMath.SealCardTier.SILVER
	stats.exp_reward = 60
	stats.gold_reward_min = 30
	stats.gold_reward_max = 70

func _draw() -> void:
	super._draw()
	var sway = sin(anim_timer * 4.0) * 2.0
	draw_custom_ellipse(Vector2(0, 14), 16.0, 8.0, Color(0, 0, 0, 0.35))
	
	# 樹幹本體
	draw_circle(Vector2(0, 4), 14.0, Color(0.4, 0.25, 0.15))
	# 樹冠枝葉 (深綠與淺綠)
	draw_circle(Vector2(-6, -10 + sway), 12.0, Color(0.15, 0.55, 0.25))
	draw_circle(Vector2(6, -10 + sway), 12.0, Color(0.18, 0.65, 0.28))
	draw_circle(Vector2(0, -18 + sway), 14.0, Color(0.25, 0.75, 0.35))
	
	# 發光的古木之眼
	draw_circle(Vector2(-4, 0), 2.5, Color(1.0, 0.8, 0.2))
	draw_circle(Vector2(4, 0), 2.5, Color(1.0, 0.8, 0.2))
	draw_circle(Vector2(-4, 0), 1.0, Color.BLACK)
	draw_circle(Vector2(4, 0), 1.0, Color.BLACK)

func draw_custom_ellipse(c: Vector2, rx: float, ry: float, color: Color) -> void:
	var points = PackedVector2Array()
	for i in range(20):
		var rad = (TAU / 20.0) * i
		points.append(c + Vector2(cos(rad) * rx, sin(rad) * ry))
	draw_colored_polygon(points, color)
