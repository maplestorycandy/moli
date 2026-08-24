extends Node2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 650.0
var damage_mult: float = 3.5
var lifetime: float = 2.0
var timer: float = 0.0

@onready var hitbox: HitboxComponent = $HitboxComponent

func _ready() -> void:
	hitbox.is_player_team = true
	hitbox.attacker_node = Global.player if Global.player else self
	hitbox.skill_name = "亂射"
	hitbox.damage_multiplier = damage_mult
	hitbox.element_type = CombatMath.ElementType.WIND
	hitbox.reset_hit_list()

func setup(dir: Vector2, dmg_m: float) -> void:
	direction = dir.normalized()
	damage_mult = dmg_m
	rotation = direction.angle()
	if hitbox:
		hitbox.attacker_node = Global.player if Global.player else self
		hitbox.damage_multiplier = damage_mult
		hitbox.reset_hit_list()

func _process(delta: float) -> void:
	timer += delta
	global_position += direction * speed * delta
	queue_redraw()
	
	if timer >= lifetime:
		queue_free()

func _draw() -> void:
	draw_line(Vector2(-20, 0), Vector2(16, 0), Color(1.0, 0.9, 0.2), 3.5)
	draw_line(Vector2(-12, 0), Vector2(16, 0), Color.WHITE, 2.0)
	
	var pts = PackedVector2Array([
		Vector2(20, 0),
		Vector2(10, -5),
		Vector2(12, 0),
		Vector2(10, 5)
	])
	draw_colored_polygon(pts, Color(1.0, 0.95, 0.4))
	
	draw_line(Vector2(-20, 0), Vector2(-26, -6), Color(0.2, 0.8, 1.0), 2.5)
	draw_line(Vector2(-20, 0), Vector2(-26, 6), Color(0.2, 0.8, 1.0), 2.5)
