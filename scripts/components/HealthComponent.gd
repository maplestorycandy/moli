extends Node
class_name HealthComponent

signal health_changed(current: int, max_hp: int)
signal mana_changed(current: int, max_mp: int)
signal died()
signal damaged(amount: int, is_crit: bool, is_effective: bool)

@export var stats: StatsComponent
var current_hp: int = 100
var current_mp: int = 50
var is_dead: bool = false

func _ready() -> void:
	if stats:
		current_hp = stats.max_hp
		current_mp = stats.max_mp
	else:
		current_hp = 100
		current_mp = 50
	health_changed.emit(current_hp, get_max_hp())

func get_max_hp() -> int:
	return stats.max_hp if stats else 100

func get_max_mp() -> int:
	return stats.max_mp if stats else 50

func take_damage(amount: int, is_crit: bool = false, is_effective: bool = false, attacker: Node = null) -> int:
	if is_dead:
		return 0
		
	current_hp -= amount
	current_hp = max(0, current_hp)
	health_changed.emit(current_hp, get_max_hp())
	damaged.emit(amount, is_crit, is_effective)
	
	if current_hp <= 0:
		is_dead = true
		died.emit()
		
	return amount

func heal(amount: int) -> void:
	if is_dead:
		return
	current_hp = min(get_max_hp(), current_hp + amount)
	health_changed.emit(current_hp, get_max_hp())

func restore_mp(amount: int) -> void:
	current_mp = min(get_max_mp(), current_mp + amount)
	mana_changed.emit(current_mp, get_max_mp())

func consume_mp(amount: int) -> bool:
	if current_mp >= amount:
		current_mp -= amount
		mana_changed.emit(current_mp, get_max_mp())
		return true
	return false

func get_hp_ratio() -> float:
	var m = get_max_hp()
	return float(current_hp) / float(m) if m > 0 else 0.0
