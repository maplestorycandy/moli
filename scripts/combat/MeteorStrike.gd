extends Node2D

@onready var hitbox: HitboxComponent = $HitboxComponent
var caster: Node = null
var magic_damage_mult: float = 2.5
var timer: float = 0.0
var phase: int = 0 # 0: 魔法陣詠唱, 1: 隕石砸落, 2: 爆炸消散
var meteor_height: float = 300.0
var magic_circle_radius: float = 70.0

func _ready() -> void:
	hitbox.damage_multiplier = magic_damage_mult
	hitbox.is_magic = true
	hitbox.element_type = CombatMath.ElementType.EARTH
	hitbox.is_player_team = true
	hitbox.skill_name = "超強隕石魔法"
	$HitboxComponent/CollisionShape2D.disabled = true

func setup(pos: Vector2, caster_node: Node) -> void:
	global_position = pos
	caster = caster_node
	if not is_node_ready():
		await ready
	hitbox.attacker_node = caster_node

func _process(delta: float) -> void:
	timer += delta
	if phase == 0:
		if timer >= 0.4:
			phase = 1
			timer = 0.0
			SoundManager.play_magic()
	elif phase == 1:
		meteor_height = lerp(300.0, 0.0, clamp(timer / 0.35, 0.0, 1.0))
		if timer >= 0.35:
			phase = 2
			timer = 0.0
			# 砸地爆炸
			$HitboxComponent/CollisionShape2D.disabled = false
			SoundManager.play_meteor_explosion()
			EventBus.screen_shake_requested.emit(12.0, 0.35)
	elif phase == 2:
		if timer >= 0.15:
			$HitboxComponent/CollisionShape2D.disabled = true
		if timer >= 0.6:
			queue_free()
			
	queue_redraw()

func _draw() -> void:
	# 地面魔法陣
	if phase <= 1:
		var alpha = clamp(timer * 2.0, 0.2, 0.8) if phase == 0 else 0.8
		var circle_color = Color(0.9, 0.65, 0.2, alpha)
		draw_arc(Vector2.ZERO, magic_circle_radius, 0, TAU, 32, circle_color, 3.0)
		draw_arc(Vector2.ZERO, magic_circle_radius * 0.7, 0, TAU, 24, circle_color, 1.5)
		
		# 符文線條
		for i in range(6):
			var angle = (TAU / 6.0) * i
			var p1 = Vector2.from_angle(angle) * magic_circle_radius
			var p2 = Vector2.from_angle(angle + PI) * magic_circle_radius
			draw_line(p1, p2, circle_color, 1.0)
			
	# 砸落的巨型隕石
	if phase == 1:
		var m_pos = Vector2(0, -meteor_height)
		# 隕石本體 (粗糙岩石質感)
		draw_circle(m_pos, 32.0, Color(0.5, 0.3, 0.15))
		draw_circle(m_pos + Vector2(-6, -6), 26.0, Color(0.7, 0.4, 0.2))
		draw_circle(m_pos + Vector2(4, 4), 18.0, Color(0.9, 0.5, 0.1))
		# 燃燒尾焰
		for k in range(5):
			var flame_off = Vector2(randf_range(-15, 15), randf_range(-50, -20))
			draw_circle(m_pos + flame_off, randf_range(8, 16), Color(1.0, 0.4, 0.1, 0.6))
			
	# 爆炸衝擊波與碎石
	if phase == 2:
		var blast_t = timer / 0.6
		var r = magic_circle_radius * (1.0 + blast_t * 0.6)
		var a = 1.0 - blast_t
		draw_circle(Vector2.ZERO, r, Color(1.0, 0.5, 0.1, a * 0.5))
		draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(1.0, 0.8, 0.2, a), 4.0)
		
		# 炸裂飛散的土石
		for i in range(8):
			var dir = Vector2.from_angle((TAU / 8.0) * i + 0.3)
			var rock_pos = dir * (r * 0.9)
			draw_circle(rock_pos, 6.0 * a, Color(0.4, 0.25, 0.1, a))
