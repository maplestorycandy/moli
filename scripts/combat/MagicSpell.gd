extends Node2D
class_name MagicSpell

enum SpellTier {
	SINGLE,
	STRONG,
	MEGA
}

enum SpellType {
	METEOR,
	ICE,
	FIRE,
	WIND,
	DRAIN,
	MIND_WAVE,
	RAPID_FIRE,
	HEAL
}

var spell_type: SpellType = SpellType.METEOR
var spell_tier: SpellTier = SpellTier.SINGLE
var base_damage: int = 100
var radius: float = 80.0
var duration: float = 0.8
var timer: float = 0.0
var has_hit: bool = false
var spell_color: Color = Color(1.0, 0.5, 0.2)
var particles: Array[Dictionary] = []

@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var collision_shape: CollisionShape2D = $HitboxComponent/CollisionShape2D

func _ready() -> void:
	hitbox.is_player_team = true
	hitbox.attacker_node = self
	collision_shape.disabled = true

func setup(p_type: SpellType, p_tier: SpellTier, p_damage: int, p_radius: float = 0.0) -> void:
	spell_type = p_type
	spell_tier = p_tier
	base_damage = p_damage
	timer = 0.0
	has_hit = false
	
	# 設定範圍與特效色調
	match spell_tier:
		SpellTier.SINGLE:
			radius = 70.0 if p_radius == 0.0 else p_radius
			duration = 0.55
		SpellTier.STRONG:
			radius = 140.0 if p_radius == 0.0 else p_radius
			duration = 0.75
		SpellTier.MEGA:
			radius = 280.0 if p_radius == 0.0 else p_radius
			duration = 1.1
			
	match spell_type:
		SpellType.METEOR:
			spell_color = Color(0.95, 0.5, 0.1) # 熾熱岩土
		SpellType.ICE:
			spell_color = Color(0.2, 0.85, 1.0) # 晶瑩極冰
		SpellType.FIRE:
			spell_color = Color(1.0, 0.2, 0.1) # 煉獄烈焰
		SpellType.WIND:
			spell_color = Color(0.2, 1.0, 0.5) # 翡翠疾風
		SpellType.DRAIN:
			spell_color = Color(0.85, 0.15, 0.9) # 暗影汲取
		SpellType.MIND_WAVE:
			spell_color = Color(0.9, 0.8, 1.0) # 純白精神力
		SpellType.RAPID_FIRE:
			spell_color = Color(1.0, 0.9, 0.3) # 金光箭矢
		SpellType.HEAL:
			spell_color = Color(0.3, 1.0, 0.4) # 治癒聖光

	var circle_shape = CircleShape2D.new()
	circle_shape.radius = radius
	collision_shape.shape = circle_shape

	# 產生環境粒子
	var p_count = 20 if spell_tier == SpellTier.SINGLE else (40 if spell_tier == SpellTier.STRONG else 75)
	for i in range(p_count):
		particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2.from_angle(randf() * TAU) * randf_range(60, radius * 2.2),
			"life": randf_range(0.4, duration),
			"size": randf_range(4.0, 12.0)
		})

func _process(delta: float) -> void:
	timer += delta
	
	# 啟用碰撞傷害幀
	if timer >= 0.15 and not has_hit:
		has_hit = true
		collision_shape.disabled = false
		hitbox.damage_multiplier = float(base_damage) / max(1.0, float(Global.atk))
		hitbox.skill_name = _get_skill_title()
		hitbox.reset_hit_list()
		
		# 音效與震動
		var shake = 8.0 if spell_tier == SpellTier.SINGLE else (16.0 if spell_tier == SpellTier.STRONG else 28.0)
		EventBus.screen_shake_requested.emit(shake, 0.3)
		SoundManager.play_magic()
		
		# 吸血效果反哺玩家 HP
		if spell_type == SpellType.DRAIN and Global.player:
			var heal_val = int(base_damage * 0.45)
			Global.heal(heal_val)
			EventBus.damage_spawned.emit(Global.player.global_position + Vector2(0, -35), "+%d HP (吸血)" % heal_val, Color(0.2, 1.0, 0.4), false, false)
			
	elif timer >= 0.35 and not collision_shape.disabled:
		collision_shape.disabled = true
		
	# 更新粒子
	for p in particles:
		p["pos"] += p["vel"] * delta
		p["vel"] = p["vel"].move_toward(Vector2.ZERO, 150 * delta)
		
	queue_redraw()
	
	if timer >= duration:
		queue_free()

func _get_skill_title() -> String:
	var prefix = ""
	if spell_tier == SpellTier.STRONG: prefix = "強力"
	elif spell_tier == SpellTier.MEGA: prefix = "超強"
	
	match spell_type:
		SpellType.METEOR: return prefix + "隕石魔法"
		SpellType.ICE: return prefix + "冰凍魔法"
		SpellType.FIRE: return prefix + "火焰魔法"
		SpellType.WIND: return prefix + "風刃魔法"
		SpellType.DRAIN: return "吸血魔法"
		SpellType.MIND_WAVE: return "精神衝擊波"
		SpellType.RAPID_FIRE: return "亂射"
		SpellType.HEAL: return prefix + "補血魔法"
	return "魔法打擊"

func _draw() -> void:
	var progress = clamp(timer / duration, 0.0, 1.0)
	var alpha = (1.0 - progress) * 0.95
	
	# 1. 地面法陣光環
	var cur_r = radius * (0.3 + 0.7 * sin(progress * PI * 0.5))
	draw_circle(Vector2.ZERO, cur_r, Color(spell_color.r, spell_color.g, spell_color.b, alpha * 0.35))
	draw_arc(Vector2.ZERO, cur_r, 0, TAU, 36, Color(spell_color.r, spell_color.g, spell_color.b, alpha), 4.0)
	draw_arc(Vector2.ZERO, cur_r * 0.65, 0, TAU, 28, Color.WHITE * alpha, 2.5)
	
	# 2. 元素具象視覺
	match spell_type:
		SpellType.METEOR:
			# 從天而降的巨型隕石
			var drop_y = -350 * (1.0 - min(1.0, timer / 0.2))
			var m_size = 28.0 if spell_tier == SpellTier.SINGLE else (45.0 if spell_tier == SpellTier.STRONG else 75.0)
			if timer < 0.3:
				draw_circle(Vector2(0, drop_y), m_size, Color(0.9, 0.4, 0.1, alpha))
				draw_circle(Vector2(0, drop_y), m_size * 0.6, Color(1.0, 0.8, 0.2, alpha))
			else:
				# 碎石擴散
				for i in range(12):
					var ang = (TAU / 12.0) * i + timer * 2.0
					var pt = Vector2.from_angle(ang) * (cur_r * 0.8)
					draw_circle(pt, 8.0, Color(0.8, 0.3, 0.1, alpha))
					
		SpellType.ICE:
			# 晶瑩尖銳冰刺群
			var spike_count = 6 if spell_tier == SpellTier.SINGLE else (12 if spell_tier == SpellTier.STRONG else 24)
			for i in range(spike_count):
				var ang = (TAU / float(spike_count)) * i
				var spike_len = cur_r * randf_range(0.7, 1.1)
				var tip = Vector2.from_angle(ang) * spike_len
				var left = Vector2.from_angle(ang + 0.3) * (spike_len * 0.2)
				var right = Vector2.from_angle(ang - 0.3) * (spike_len * 0.2)
				var pts = PackedVector2Array([tip, left, Vector2.ZERO, right])
				draw_colored_polygon(pts, Color(0.3, 0.85, 1.0, alpha * 0.8))
				draw_line(Vector2.ZERO, tip, Color.WHITE * alpha, 2.5)
				
		SpellType.FIRE:
			# 熾烈火海與爆鳴
			for i in range(8):
				var ang = (TAU / 8.0) * i + timer * 5.0
				var f_pos = Vector2.from_angle(ang) * (cur_r * 0.6)
				draw_circle(f_pos, cur_r * 0.35, Color(1.0, 0.2, 0.05, alpha * 0.7))
				draw_circle(f_pos, cur_r * 0.2, Color(1.0, 0.8, 0.1, alpha * 0.9))
				
		SpellType.WIND:
			# 翡翠風刃狂舞龍捲
			for i in range(6):
				var ang = (TAU / 6.0) * i + timer * 14.0
				draw_arc(Vector2.ZERO, cur_r * 0.85, ang, ang + 1.2, 12, Color(0.2, 1.0, 0.4, alpha), 6.0)
				draw_arc(Vector2.ZERO, cur_r * 0.45, -ang, -ang + 1.2, 12, Color.WHITE * alpha, 3.5)
				
		SpellType.DRAIN:
			# 暗影血魄漩渦
			draw_arc(Vector2.ZERO, cur_r * 0.7, timer * 10.0, timer * 10.0 + 3.0, 24, Color(0.9, 0.1, 0.8, alpha), 6.0)
			draw_circle(Vector2.ZERO, cur_r * 0.4, Color(0.4, 0.05, 0.3, alpha * 0.9))
			if Global.player:
				var to_player = Global.player.global_position - global_position
				draw_line(Vector2.ZERO, to_player * min(1.0, timer / 0.4), Color(0.9, 0.2, 0.8, alpha), 4.0)
				
		SpellType.MIND_WAVE:
			# 純白精神震盪衝擊環
			draw_arc(Vector2.ZERO, cur_r, 0, TAU, 36, Color(1.0, 1.0, 1.0, alpha), 8.0)
			draw_arc(Vector2.ZERO, cur_r * 0.7, 0, TAU, 28, Color(0.8, 0.7, 1.0, alpha * 0.8), 5.0)
			draw_arc(Vector2.ZERO, cur_r * 0.4, 0, TAU, 20, Color(0.6, 0.5, 1.0, alpha * 0.9), 3.0)
			
		SpellType.RAPID_FIRE:
			# 金光箭雨天降
			for i in range(10):
				var arrow_pos = Vector2(randf_range(-cur_r, cur_r), randf_range(-cur_r, cur_r))
				draw_line(arrow_pos + Vector2(-15, -30), arrow_pos, Color(1.0, 0.85, 0.2, alpha), 3.5)
				draw_line(arrow_pos + Vector2(-15, -30), arrow_pos, Color.WHITE * alpha, 1.5)

	# 3. 粒子繪製
	for p in particles:
		draw_circle(p["pos"], p["size"] * (1.0 - progress), Color(spell_color.r, spell_color.g, spell_color.b, alpha))
