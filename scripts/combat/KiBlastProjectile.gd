extends Node2D

@export var speed: float = 520.0
@export var damage_mult: float = 7.5
@export var max_distance: float = 650.0

var direction: Vector2 = Vector2.RIGHT
var distance_traveled: float = 0.0

@onready var hitbox: HitboxComponent = $HitboxComponent

func _ready() -> void:
	hitbox.damage_multiplier = damage_mult
	hitbox.is_magic = false
	hitbox.is_player_team = true
	hitbox.attacker_node = Global.player if Global.player else self
	hitbox.skill_name = "氣功彈"
	hitbox.reset_hit_list()

func setup(dir: Vector2, p_damage_mult: float = 7.5, _count: int = 1) -> void:
	direction = dir.normalized()
	damage_mult = p_damage_mult
	rotation = direction.angle()
	if hitbox:
		hitbox.attacker_node = Global.player if Global.player else self
		hitbox.damage_multiplier = damage_mult
		hitbox.reset_hit_list()

func _physics_process(delta: float) -> void:
	var move_vec = direction * speed * delta
	position += move_vec
	distance_traveled += move_vec.length()
	
	queue_redraw()
	
	if distance_traveled >= max_distance:
		queue_free()

func _draw() -> void:
	# 巨型純陽氣功彈 (多層光暈 + 核心高亮)
	draw_circle(Vector2.ZERO, 22.0, Color(0.3, 0.8, 1.0, 0.4))
	draw_circle(Vector2.ZERO, 15.0, Color(0.6, 0.95, 1.0, 0.75))
	draw_circle(Vector2.ZERO, 9.0, Color(1.0, 1.0, 1.0, 1.0))
	
	# 尾跡氣旋
	draw_circle(-direction * 12, 12.0, Color(0.2, 0.6, 1.0, 0.45))
	draw_circle(-direction * 24, 7.0, Color(0.1, 0.4, 0.9, 0.25))
