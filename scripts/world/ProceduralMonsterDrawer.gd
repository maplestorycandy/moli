extends Node
class_name ProceduralMonsterDrawer

static func draw_monster(ci: CanvasItem, drawer_type: String, col_main: Color, col_sub: Color, anim_t: float, m_scale: float = 1.0, is_boss: bool = false) -> void:
	var bounce = sin(anim_t * 7.0) * (2.5 * m_scale)
	var shadow_rx = 14.0 * m_scale
	var shadow_ry = 7.0 * m_scale
	
	# 底部陰影
	draw_custom_ellipse(ci, Vector2(0, 12 * m_scale), shadow_rx, shadow_ry, Color(0, 0, 0, 0.35))
	
	# BOSS 專屬史詩霸氣光環與六芒星陣
	if is_boss:
		var aura_r = 34.0 * m_scale + sin(anim_t * 10.0) * 4.0
		ci.draw_arc(Vector2.ZERO, aura_r, 0, TAU, 32, col_sub, 3.0)
		ci.draw_circle(Vector2.ZERO, aura_r * 0.4, Color(col_sub.r, col_sub.g, col_sub.b, 0.15))
		for i in range(6):
			var ang = (TAU / 6.0) * i + anim_t * 2.0
			ci.draw_circle(Vector2.from_angle(ang) * aura_r, 3.5 * m_scale, col_main)
		
	match drawer_type:
		"slime":
			# 水滴凝膠形態：流體壓扁彈跳 + 內部氣泡 + 高光
			var squish_x = (1.0 + sin(anim_t * 6.0) * 0.18) * m_scale
			var squish_y = (1.0 - sin(anim_t * 6.0) * 0.18) * m_scale
			ci.draw_circle(Vector2(0, 4 + bounce), 14.0 * squish_x, col_main)
			ci.draw_circle(Vector2(0, -6 + bounce), 8.0 * squish_x, col_main) # 水滴尖頂
			# 晶瑩高光
			ci.draw_circle(Vector2(-5 * squish_x, -2 + bounce), 4.0 * squish_x, Color(1, 1, 1, 0.6))
			# 大眼與黑眼珠
			ci.draw_circle(Vector2(-4 * squish_x, 3 + bounce), 3.2, Color.WHITE)
			ci.draw_circle(Vector2(4 * squish_x, 3 + bounce), 3.2, Color.WHITE)
			ci.draw_circle(Vector2(-4 * squish_x, 3 + bounce), 1.6, Color.BLACK)
			ci.draw_circle(Vector2(4 * squish_x, 3 + bounce), 1.6, Color.BLACK)

		"bomb":
			# 炸彈怪：金屬圓形炸彈、引信火花、怒火紅眼
			var pulse = 1.0 + sin(anim_t * 12.0) * 0.1
			var r = 15.0 * m_scale * pulse
			ci.draw_circle(Vector2(0, bounce), r, col_main)
			ci.draw_arc(Vector2.ZERO, r, 0, TAU, 20, col_sub, 2.0)
			# 引信與燃燒火花
			var fuse_tip = Vector2(8 * m_scale, -r - 12 * m_scale + bounce)
			ci.draw_line(Vector2(0, -r + bounce), fuse_tip, Color(0.4, 0.3, 0.2), 3.0)
			ci.draw_circle(fuse_tip, 5.0 + sin(anim_t * 24.0) * 2.5, Color(1, 0.85, 0.1))
			ci.draw_circle(fuse_tip, 2.5, Color(1, 0.2, 0.1))
			# 憤怒眉毛與紅眼
			ci.draw_line(Vector2(-7 * m_scale, -5 + bounce), Vector2(-2 * m_scale, -2 + bounce), Color.BLACK, 2.0)
			ci.draw_line(Vector2(7 * m_scale, -5 + bounce), Vector2(2 * m_scale, -2 + bounce), Color.BLACK, 2.0)
			ci.draw_circle(Vector2(-5 * m_scale, 0 + bounce), 2.5 * m_scale, Color.RED)
			ci.draw_circle(Vector2(5 * m_scale, 0 + bounce), 2.5 * m_scale, Color.RED)

		"box":
			# 嚇人箱/寶箱怪：開合大嘴、尖牙、紅舌
			var w = 26.0 * m_scale
			var h = 20.0 * m_scale
			var open_jaw = sin(anim_t * 8.0) * 6.0
			# 下箱身
			ci.draw_rect(Rect2(-w/2, 0 + bounce, w, h/2), col_main, true)
			ci.draw_rect(Rect2(-w/2, 0 + bounce, w, h/2), col_sub, false, 2.0)
			# 上箱蓋 (張開)
			ci.draw_rect(Rect2(-w/2, -h/2 + bounce - open_jaw, w, h/2), col_main, true)
			ci.draw_rect(Rect2(-w/2, -h/2 + bounce - open_jaw, w, h/2), col_sub, false, 2.0)
			# 血盆大口尖牙
			for i in range(4):
				var tx = -w/2 + 3 + i * 6
				ci.draw_colored_polygon(PackedVector2Array([
					Vector2(tx, 0 + bounce),
					Vector2(tx + 3, -6 + bounce - open_jaw * 0.5),
					Vector2(tx + 6, 0 + bounce)
				]), Color.WHITE)
			# 紅色長舌
			ci.draw_line(Vector2(0, 2 + bounce), Vector2(sin(anim_t * 10.0) * 6, 12 + bounce), Color(1, 0.2, 0.3), 3.5)

		"crystal":
			# 水晶怪：六角旋轉棱晶、折射晶片
			var rot = anim_t * 2.0
			var r = 16.0 * m_scale
			var pts = PackedVector2Array()
			for i in range(6):
				var a = (TAU / 6.0) * i + rot
				pts.append(Vector2.from_angle(a) * r + Vector2(0, bounce))
			ci.draw_colored_polygon(pts, col_main)
			ci.draw_polyline(pts, col_sub, 2.5)
			ci.draw_circle(Vector2(0, bounce), 6.0 * m_scale, Color(1, 1, 1, 0.8))

		"wasp":
			# 黃蜂：雙對半透明高頻震動蜂翼、腹部毒針條紋
			var flap = sin(anim_t * 32.0) * 8.0
			# 4片羽翼
			draw_custom_ellipse(ci, Vector2(-12 * m_scale, -12 * m_scale + bounce + flap), 12 * m_scale, 4 * m_scale, Color(0.85, 0.95, 1.0, 0.75))
			draw_custom_ellipse(ci, Vector2(12 * m_scale, -12 * m_scale + bounce + flap), 12 * m_scale, 4 * m_scale, Color(0.85, 0.95, 1.0, 0.75))
			# 頭部與複眼
			ci.draw_circle(Vector2(0, -10 * m_scale + bounce), 7.0 * m_scale, col_main)
			ci.draw_circle(Vector2(-3 * m_scale, -11 * m_scale + bounce), 2.5, Color.BLACK)
			ci.draw_circle(Vector2(3 * m_scale, -11 * m_scale + bounce), 2.5, Color.BLACK)
			# 蜂身與毒針
			ci.draw_circle(Vector2(0, 0 + bounce), 10.0 * m_scale, col_main)
			ci.draw_line(Vector2(-7 * m_scale, 0 + bounce), Vector2(7 * m_scale, 0 + bounce), col_sub, 3.0)
			ci.draw_line(Vector2(-5 * m_scale, 4 + bounce), Vector2(5 * m_scale, 4 + bounce), col_sub, 3.0)
			ci.draw_line(Vector2(0, 8 * m_scale + bounce), Vector2(0, 18 * m_scale + bounce), col_sub, 3.0) # 尖銳毒針

		"mantis":
			# 螳螂：凶狠巨大鋸齒雙鐮刀、三段昆蟲軀幹
			var arm_swing = sin(anim_t * 10.0) * 5.0
			ci.draw_circle(Vector2(0, 4 + bounce), 9.0 * m_scale, col_main) # 腹部
			ci.draw_circle(Vector2(0, -6 + bounce), 7.0 * m_scale, col_main) # 胸部
			ci.draw_circle(Vector2(0, -15 * m_scale + bounce), 6.0 * m_scale, col_main) # 倒三角頭
			# 赤目複眼
			ci.draw_circle(Vector2(-4 * m_scale, -16 * m_scale + bounce), 2.5 * m_scale, Color.RED)
			ci.draw_circle(Vector2(4 * m_scale, -16 * m_scale + bounce), 2.5 * m_scale, Color.RED)
			# 雙臂死神大鐮刀
			var l_elbow = Vector2(-16 * m_scale, -12 * m_scale + bounce + arm_swing)
			var l_blade = l_elbow + Vector2(-8 * m_scale, 18 * m_scale)
			ci.draw_line(Vector2(-5 * m_scale, -6 + bounce), l_elbow, col_main, 4.0)
			ci.draw_line(l_elbow, l_blade, col_sub, 4.5)
			
			var r_elbow = Vector2(16 * m_scale, -12 * m_scale + bounce - arm_swing)
			var r_blade = r_elbow + Vector2(8 * m_scale, 18 * m_scale)
			ci.draw_line(Vector2(5 * m_scale, -6 + bounce), r_elbow, col_main, 4.0)
			ci.draw_line(r_elbow, r_blade, col_sub, 4.5)

		"spider", "scorpion":
			# 蜘蛛 / 蠍子：8隻多節肢、尾針
			ci.draw_circle(Vector2(0, 2 + bounce), 12.0 * m_scale, col_main)
			ci.draw_circle(Vector2(0, -8 + bounce), 7.0 * m_scale, col_main)
			for i in range(4):
				var leg_y = (-6 + i * 4) * m_scale + bounce
				var wiggle = sin(anim_t * 12.0 + i) * 4.0
				ci.draw_line(Vector2(-8 * m_scale, leg_y), Vector2(-22 * m_scale, leg_y - 6 + wiggle), col_sub, 2.5)
				ci.draw_line(Vector2(8 * m_scale, leg_y), Vector2(22 * m_scale, leg_y - 6 - wiggle), col_sub, 2.5)
			# 蠍子倒鉤巨尾
			if drawer_type == "scorpion":
				ci.draw_line(Vector2(0, 10 + bounce), Vector2(sin(anim_t * 8.0) * 8, 26 + bounce), col_sub, 4.0)

		"beetle":
			# 甲蟲 / 獨角仙：厚重甲殼、巨大雙叉衝角
			ci.draw_circle(Vector2(0, 2 + bounce), 14.0 * m_scale, col_main)
			ci.draw_line(Vector2(0, -10 + bounce), Vector2(0, 14 + bounce), col_sub, 2.5) # 背甲中線
			# 頭部與衝角
			ci.draw_circle(Vector2(0, -10 * m_scale + bounce), 8.0 * m_scale, col_main)
			var horn_tip = Vector2(0, -26 * m_scale + bounce)
			ci.draw_line(Vector2(0, -10 * m_scale + bounce), horn_tip, col_sub, 4.0)
			ci.draw_line(horn_tip, horn_tip + Vector2(-6 * m_scale, -6 * m_scale), col_sub, 3.0)
			ci.draw_line(horn_tip, horn_tip + Vector2(6 * m_scale, -6 * m_scale), col_sub, 3.0)

		"humanoid", "boss_human":
			# 人形系 / 哥布林 / 矮人 / 狂戰士：身軀、頭盔、武器、盾牌
			ci.draw_circle(Vector2(0, 3 + bounce), 11.0 * m_scale, col_main) # 戰甲
			ci.draw_circle(Vector2(0, -9 * m_scale + bounce), 8.0 * m_scale, col_main) # 頭部
			# 盾牌
			ci.draw_circle(Vector2(-12 * m_scale, 2 + bounce), 7.0 * m_scale, col_sub)
			# 武器大劍/戰斧
			ci.draw_line(Vector2(10 * m_scale, 6 * m_scale + bounce), Vector2(22 * m_scale, -14 * m_scale + bounce), col_sub, 4.0)
			# 雙眼
			ci.draw_circle(Vector2(-3 * m_scale, -10 * m_scale + bounce), 2.0 * m_scale, Color.WHITE)
			ci.draw_circle(Vector2(3 * m_scale, -10 * m_scale + bounce), 2.0 * m_scale, Color.WHITE)

		"beast":
			# 野獸系：熊 / 狼 / 狂暴野豬 (尖耳、毛皮、利爪、長尾)
			ci.draw_circle(Vector2(0, 2 + bounce), 14.0 * m_scale, col_main)
			ci.draw_circle(Vector2(0, -10 * m_scale + bounce), 10.0 * m_scale, col_main)
			# 尖耳
			ci.draw_circle(Vector2(-8 * m_scale, -18 * m_scale + bounce), 4.5 * m_scale, col_sub)
			ci.draw_circle(Vector2(8 * m_scale, -18 * m_scale + bounce), 4.5 * m_scale, col_sub)
			# 鋒利犬齒獠牙
			ci.draw_line(Vector2(-4 * m_scale, -6 * m_scale + bounce), Vector2(-4 * m_scale, -2 * m_scale + bounce), Color.WHITE, 2.0)
			ci.draw_line(Vector2(4 * m_scale, -6 * m_scale + bounce), Vector2(4 * m_scale, -2 * m_scale + bounce), Color.WHITE, 2.0)

		"plant":
			# 植物系：樹精 / 妖草 / 仙人掌
			var sway = sin(anim_t * 5.0) * (4.0 * m_scale)
			ci.draw_circle(Vector2(0, 5), 14.0 * m_scale, col_main) # 樹幹底座
			ci.draw_circle(Vector2(-8 * m_scale, -8 * m_scale + sway), 12.0 * m_scale, col_sub)
			ci.draw_circle(Vector2(8 * m_scale, -8 * m_scale + sway), 12.0 * m_scale, col_sub)
			ci.draw_circle(Vector2(0, -18 * m_scale + sway), 15.0 * m_scale, col_sub) # 茂密樹冠
			# 樹精雙眼
			ci.draw_circle(Vector2(-4 * m_scale, -16 * m_scale + sway), 2.5 * m_scale, Color(1, 0.9, 0.2))
			ci.draw_circle(Vector2(4 * m_scale, -16 * m_scale + sway), 2.5 * m_scale, Color(1, 0.9, 0.2))

		"undead":
			# 不死系：殭屍 / 骷髏 / 幽靈 (骨骼、幽綠毒氣、空洞眼窩)
			var ghost_float = sin(anim_t * 6.0) * 4.0
			ci.draw_circle(Vector2(0, 2 + bounce + ghost_float), 11.0 * m_scale, col_main)
			ci.draw_circle(Vector2(0, -10 * m_scale + bounce + ghost_float), 9.0 * m_scale, col_main)
			# 幽暗空洞眼窩
			ci.draw_circle(Vector2(-3.5 * m_scale, -10 * m_scale + bounce + ghost_float), 3.0 * m_scale, col_sub)
			ci.draw_circle(Vector2(3.5 * m_scale, -10 * m_scale + bounce + ghost_float), 3.0 * m_scale, col_sub)
			# 亡靈幽火
			ci.draw_circle(Vector2(0, -22 * m_scale + bounce + ghost_float), 4.0 + sin(anim_t * 15.0) * 2.0, col_sub)

		"flying":
			# 飛行系：使魔 / 惡魔 / 蝙蝠 (巨大惡魔蝠翼、尖角)
			var flap = sin(anim_t * 18.0) * (9.0 * m_scale)
			var p_l = PackedVector2Array([Vector2(0, -4 + bounce), Vector2(-24 * m_scale, -18 * m_scale + bounce + flap), Vector2(-16 * m_scale, 8 * m_scale + bounce)])
			var p_r = PackedVector2Array([Vector2(0, -4 + bounce), Vector2(24 * m_scale, -18 * m_scale + bounce + flap), Vector2(16 * m_scale, 8 * m_scale + bounce)])
			ci.draw_colored_polygon(p_l, col_sub)
			ci.draw_colored_polygon(p_r, col_sub)
			ci.draw_circle(Vector2(0, 0 + bounce), 10.0 * m_scale, col_main)
			ci.draw_circle(Vector2(0, -9 * m_scale + bounce), 7.0 * m_scale, col_main)
			# 惡魔雙角
			ci.draw_line(Vector2(-5 * m_scale, -14 * m_scale + bounce), Vector2(-10 * m_scale, -22 * m_scale + bounce), col_sub, 3.0)
			ci.draw_line(Vector2(5 * m_scale, -14 * m_scale + bounce), Vector2(10 * m_scale, -22 * m_scale + bounce), col_sub, 3.0)

		"metal":
			# 金屬系：血腥之刃 / 烈風之刃 / 鋼鐵巨像
			var spin = anim_t * 12.0
			var blade_len = 20.0 * m_scale
			ci.draw_circle(Vector2(0, bounce), 8.0 * m_scale, col_main)
			ci.draw_line(Vector2.from_angle(spin) * blade_len + Vector2(0, bounce), Vector2.from_angle(spin + PI) * blade_len + Vector2(0, bounce), col_sub, 4.5)
			ci.draw_line(Vector2.from_angle(spin + PI/2) * blade_len + Vector2(0, bounce), Vector2.from_angle(spin + PI*1.5) * blade_len + Vector2(0, bounce), col_sub, 4.5)

		"dragon":
			# 龍系：水龍蜥 / 翼龍 / 滅世紅龍 (龍首、龍角、背棘、甩尾)
			var tail_w = sin(anim_t * 6.0) * (9.0 * m_scale)
			ci.draw_line(Vector2(0, 6 * m_scale + bounce), Vector2(tail_w, 24 * m_scale + bounce), col_sub, 6.0 * m_scale)
			ci.draw_circle(Vector2(0, 2 + bounce), 15.0 * m_scale, col_main) # 龍身
			ci.draw_circle(Vector2(0, -12 * m_scale + bounce), 11.0 * m_scale, col_main) # 龍頭
			# 霸氣巨龍角
			ci.draw_line(Vector2(-6 * m_scale, -18 * m_scale + bounce), Vector2(-16 * m_scale, -30 * m_scale + bounce), col_sub, 3.5)
			ci.draw_line(Vector2(6 * m_scale, -18 * m_scale + bounce), Vector2(16 * m_scale, -30 * m_scale + bounce), col_sub, 3.5)
			# 金黃龍瞳
			ci.draw_circle(Vector2(-4 * m_scale, -13 * m_scale + bounce), 2.5 * m_scale, Color(1, 0.85, 0.2))
			ci.draw_circle(Vector2(4 * m_scale, -13 * m_scale + bounce), 2.5 * m_scale, Color(1, 0.85, 0.2))

		"boss_ozunac":
			# 熱砂之歐茲那克：巨漢熊皮披風、巨型狂暴戰斧
			ci.draw_circle(Vector2(0, 4 + bounce), 16.0 * m_scale, Color(0.6, 0.35, 0.2)) # 熊皮
			ci.draw_circle(Vector2(0, -12 * m_scale + bounce), 11.0 * m_scale, Color(0.85, 0.65, 0.45)) # 臉部
			# 巨型熱砂狂戰斧
			var axe_p = Vector2(22 * m_scale, -10 * m_scale + bounce)
			ci.draw_line(Vector2(10 * m_scale, 10 * m_scale + bounce), axe_p + Vector2(10, -20), Color(0.4, 0.3, 0.2), 5.0)
			ci.draw_circle(axe_p + Vector2(8, -16), 14.0 * m_scale, col_sub)

		"boss_ruby":
			# 露比 (Ruby)：蘿莉魔女斗篷、魔杖、3枚圍繞旋轉小炸彈
			ci.draw_circle(Vector2(0, 2 + bounce), 11.0 * m_scale, Color(0.7, 0.15, 0.25))
			ci.draw_circle(Vector2(0, -9 * m_scale + bounce), 8.0 * m_scale, Color(1.0, 0.88, 0.8))
			# 3枚圍繞旋轉的小炸彈
			for i in range(3):
				var ang = (TAU / 3.0) * i + anim_t * 5.0
				var b_pos = Vector2.from_angle(ang) * (26.0 * m_scale) + Vector2(0, bounce)
				ci.draw_circle(b_pos, 5.0 * m_scale, Color(0.15, 0.15, 0.2))
				ci.draw_circle(b_pos, 2.0 * m_scale, Color.RED)

		"boss_judas", "boss_riberius":
			# 猶大 / 軍神李貝留斯：六翼墮天羽翼、神罰裁決聖光
			var flap = sin(anim_t * 8.0) * 8.0
			for i in range(3):
				var w_offset = (i - 1) * 12.0
				var p_l = PackedVector2Array([Vector2(0, bounce), Vector2(-32 * m_scale, w_offset - 16 + bounce + flap), Vector2(-20 * m_scale, w_offset + 12 + bounce)])
				var p_r = PackedVector2Array([Vector2(0, bounce), Vector2(32 * m_scale, w_offset - 16 + bounce + flap), Vector2(20 * m_scale, w_offset + 12 + bounce)])
				ci.draw_colored_polygon(p_l, col_sub)
				ci.draw_colored_polygon(p_r, col_sub)
			ci.draw_circle(Vector2(0, 0 + bounce), 14.0 * m_scale, col_main)
			ci.draw_circle(Vector2(0, -12 * m_scale + bounce), 10.0 * m_scale, col_main)
			ci.draw_arc(Vector2(0, -22 * m_scale + bounce), 12.0 * m_scale, 0, TAU, 24, Color(1, 0.9, 0.3), 3.0) # 神之光環

		_:
			ci.draw_circle(Vector2(0, bounce), 13.0 * m_scale, col_main)
			ci.draw_arc(Vector2.ZERO, 16.0 * m_scale, 0, TAU, 24, col_sub, 2.5)

static func draw_custom_ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, color: Color) -> void:
	var points = PackedVector2Array()
	for i in range(20):
		var rad = (TAU / 20.0) * i
		points.append(c + Vector2(cos(rad) * rx, sin(rad) * ry))
	ci.draw_colored_polygon(points, color)
