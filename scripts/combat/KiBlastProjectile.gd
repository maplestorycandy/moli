extends Node2D

@export var speed: float = 380.0
@export var damage_mult: float = 1.6
@export var pierce_count: int = 2

var direction: Vector2 = Vector2.RIGHT
var distance_traveled: float = 0.0
var max_distance: float = 550.0
var hits_done: int = 0

@onready var hitbox: HitboxComponent = $HitboxComponent

func _ready() -> void:
	hitbox.damage_multiplier = damage_mult
	hitbox.is_magic = false
	hitbox.is_player_team = true
	hitbox.skill_name = "氣功彈"

func setup(dir: Vector2, shooter: Node) -> void:
	direction = dir.normalized()
	rotation = direction.angle()
	if not is_node_ready():
		await ready
	hitbox.attacker_node = shooter

func _physics_process(delta: float) -> void:
	var move_vec = direction * speed * delta
	position += move_vec
	distance_traveled += move_vec.length()
	
	queue_redraw()
	
	if distance_traveled >= max_distance:
		queue_free()

func _draw() -> void:
	# 繪製氣功彈光球特效 (多層光暈 + 核心高亮)
	draw_circle(Vector2.ZERO, 16.0, Color(1.0, 0.8, 0.2, 0.3))
	draw_circle(Vector2.ZERO, 11.0, Color(1.0, 0.9, 0.4, 0.6))
	draw_circle(Vector2.ZERO, 6.0, Color(1.0, 1.0, 0.9, 1.0))
	
	# 尾跡光暈
	draw_circle(-direction * 8, 8.0, Color(1.0, 0.7, 0.1, 0.4))
	draw_circle(-direction * 16, 4.0, Color(1.0, 0.5, 0.0, 0.2))
