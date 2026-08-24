extends Area2D
class_name HitboxComponent

@export var damage_multiplier: float = 1.0
@export var knockback_force: float = 180.0
@export var is_magic: bool = false
@export var element_type: CombatMath.ElementType = CombatMath.ElementType.NONE
@export var custom_element_dist: Dictionary = {}
@export var hit_sound_type: String = "hit" # "hit", "crit", "slash"
@export var is_player_team: bool = false

var attacker_node: Node = null
var skill_name: String = "普通攻擊"
var already_hit_targets: Array[Node] = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func reset_hit_list() -> void:
	already_hit_targets.clear()

func _on_area_entered(area: Area2D) -> void:
	if area is HurtboxComponent:
		var hurtbox = area as HurtboxComponent
		if hurtbox.is_player_team == is_player_team:
			return # 友軍免傷
			
		var target_parent = hurtbox.get_parent()
		if target_parent in already_hit_targets:
			return
			
		already_hit_targets.append(target_parent)
		hurtbox.receive_hit(self)
