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
var damage_mult: float = 8.5
var radius: float = 120.0
var duration: float = 0.8
var timer: float = 0.0
var has_hit: bool = false
var spell_color: Color = Color(1.0, 0.5, 0.2)
var particles: Array[Dictionary] = []

@onready var hitbox: HitboxComponent = $HitboxComponent
@onready var collision_shape: CollisionShape2D = $HitboxComponent/CollisionShape2D

func _ready() -> void:
	hitbox.is_player_team = true
	hitbox.attacker_node = Global.player if Global.player else self
	collision_shape.disabled = true

func setup(p_type: SpellType, p_tier: SpellTier, p_dmg_mult: float, p_radius: float = 0.0) -> void:
	spell_type = p_type
	spell_tier = p_tier
	damage_mult = p_dmg_mult
	timer = 0.0
	has_hit = false
	
	match spell_tier:
		SpellTier.SINGLE:
			radius = 90.0 if p_radius == 0.0 else p_radius
			duration = 0.6
		SpellTier.STRONG:
			radius = 160.0 if p_radius == 0.0 else p_radius
			duration = 0.8
		SpellTier.MEGA:
			radius = 360.0 if p_radius == 0.0 else p_radius # 全螢幕超大範圍
			duration = 1.2
			
	match spell_type:
		SpellType.METEOR:
			spell_color = Color(0.95, 0.5, 0.1)
			hitbox.element_type = CombatMath.ElementType.EARTH
		SpellType.ICE:
			spell_color = Color(0.2, 0.85, 1.0)
			hitbox.element_type = CombatMath.ElementType.WATER
		SpellType.FIRE:
			spell_color = Color(1.0, 0.2, 0.1)
			hitbox.element_type = CombatMath.ElementType.FIRE
		SpellType.WIND:
			spell_color = Color(0.2, 1.0, 0.5)
			hitbox.element_type = CombatMath.ElementType.WIND
		SpellType.DRAIN:
			spell_color = Color(0.85, 0.15, 0.9)
			hitbox.element_type = CombatMath.ElementType.NONE
		SpellType.MIND_WAVE:
			spell_color = Color(0.9, 0.8, 1.0)
			hitbox.element_type = CombatMath.ElementType.NONE
		SpellType.RAPID_FIRE:
			spell_color = Color(1.0, 0.9, 0.3)
			hitbox.element_type = CombatMath.ElementType.WIND
		SpellType.HEAL:
			spell_color = Color(0.3, 1.0, 0.4)
			hitbox.element_type = CombatMath.ElementType.NONE

	var circle_shape = CircleShape2D.new()
	circle_shape.radius = radius
	collision_shape.shape = circle_shape

	var p_count = 25 if spell_tier == SpellTier.SINGLE else (50 if spell_tier == SpellTier.STRONG else 90)
	for i in range(p_count):
		particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2.from_angle(randf() * TAU) * randf_range(60, radius * 2.0),
			"life": randf_range(0.4, duration),
			"size": randf_range(5.0, 14.0)
		})

func _process(delta: float) -> void:
	timer += delta
	
	if timer >= 0.12 and not has_hit:
		has_hit = true
		collision_shape.disabled = false
		hitbox.damage_multiplier = damage_mult
		hitbox.skill_name = _get_skill_title()
		hitbox.reset_hit_list()
		
		var shake = 8.0 if spell_tier == SpellTier.SINGLE else (18.0 if spell_tier == SpellTier.STRONG else 32.0)
		EventBus.screen_shake_requested.emit(shake, 0.3)
		SoundManager.play_magic()
		
		if spell_type == SpellType.DRAIN and Global.player:
			var heal_val = int(Global.atk * damage_mult * 0.45)
			Global.heal(heal_val)
			EventBus.damage_spawned.emit(Global.player.global_position + Vector2(0, -35), "+%d HP (吸血)" % heal_val, Color(0.2, 1.0, 0.4), false, false)
			
	elif timer >= 0.40 and not collision_shape.disabled:
		collision_shape.disabled = true
		
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
	
	var cur_r = radius * (0.3 + 0.7 * sin(progress * PI * 0.5))
	draw_circle(Vector2.ZERO, cur_r, Color(spell_color.r, spell_color.g, spell_color.b, alpha * 0.35))
	draw_arc(Vector2.ZERO, cur_r, 0, TAU, 36, Color(spell_color.r, spell_color.g, spell_color.b, alpha), 4.5)
	draw_arc(Vector2.ZERO, cur_r * 0.65, 0, TAU, 28, Color.WHITE * alpha, 3.0)
	
	match spell_type:
		SpellType.METEOR:
			var drop_y = -400 * (1.0 - min(1.0, timer / 0.18))
			var m_size = 35.0 if spell_tier == SpellTier.SINGLE else (60.0 if spell_tier == SpellTier.STRONG else 100.0)
			if timer < 0.25:
				draw_circle(Vector2(0, drop_y), m_size, Color(0.9, 0.4, 0.1, alpha))
				draw_circle(Vector2(0, drop_y), m_size * 0.6, Color(1.0, 0.8, 0.2, alpha))
			else:
				for i in range(12):
					var ang = (TAU / 12.0) * i + timer * 2.0
					var pt = Vector2.from_angle(ang) * (cur_r * 0.8)
					draw_circle(pt, 10.0, Color(0.8, 0.3, 0.1, alpha))
					
		SpellType.ICE:
			var spike_count = 8 if spell_tier == SpellTier.SINGLE else (16 if spell_tier == SpellTier.STRONG else 32)
			for i in range(spike_count):
				var ang = (TAU / float(spike_count)) * i
				var spike_len = cur_r * randf_range(0.7, 1.1)
				var tip = Vector2.from_angle(ang) * spike_len
				var left = Vector2.from_angle(ang + 0.3) * (spike_len * 0.2)
				var right = Vector2.from_angle(ang - 0.3) * (spike_len * 0.2)
				var pts = PackedVector2Array([tip, left, Vector2.ZERO, right])
				draw_colored_polygon(pts, Color(0.3, 0.85, 1.0, alpha * 0.85))
				draw_line(Vector2.ZERO, tip, Color.WHITE * alpha, 3.0)
				
		SpellType.FIRE:
			for i in range(10):
				var ang = (TAU / 10.0) * i + timer * 6.0
				var f_pos = Vector2.from_angle(ang) * (cur_r * 0.6)
				draw_circle(f_pos, cur_r * 0.4, Color(1.0, 0.2, 0.05, alpha * 0.75))
				draw_circle(f_pos, cur_r * 0.22, Color(1.0, 0.8, 0.1, alpha * 0.95))
				
		SpellType.WIND:
			for i in range(8):
				var ang = (TAU / 8.0) * i + timer * 16.0
				draw_arc(Vector2.ZERO, cur_r * 0.85, ang, ang + 1.2, 12, Color(0.2, 1.0, 0.4, alpha), 7.0)
				draw_arc(Vector2.ZERO, cur_r * 0.45, -ang, -ang + 1.2, 12, Color.WHITE * alpha, 4.0)
				
		SpellType.DRAIN:
			draw_arc(Vector2.ZERO, cur_r * 0.7, timer * 10.0, timer * 10.0 + 3.0, 24, Color(0.9, 0.1, 0.8, alpha), 7.0)
			draw_circle(Vector2.ZERO, cur_r * 0.45, Color(0.4, 0.05, 0.3, alpha * 0.9))
			if Global.player:
				var to_player = Global.player.global_position - global_position
				draw_line(Vector2.ZERO, to_player * min(1.0, timer / 0.4), Color(0.9, 0.2, 0.8, alpha), 5.0)
				
		SpellType.MIND_WAVE:
			draw_arc(Vector2.ZERO, cur_r, 0, TAU, 36, Color(1.0, 1.0, 1.0, alpha), 10.0)
			draw_arc(Vector2.ZERO, cur_r * 0.7, 0, TAU, 28, Color(0.8, 0.7, 1.0, alpha * 0.85), 6.0)
			draw_arc(Vector2.ZERO, cur_r * 0.4, 0, TAU, 20, Color(0.6, 0.5, 1.0, alpha * 0.95), 4.0)

	for p in particles:
		draw_circle(p["pos"], p["size"] * (1.0 - progress), Color(spell_color.r, spell_color.g, spell_color.b, alpha))
