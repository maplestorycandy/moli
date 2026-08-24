extends StaticBody2D
class_name GoddessStatue

@export var max_hp: int = 8000
var current_hp: int = 8000
var is_destroyed: bool = false
var anim_timer: float = 0.0
var heal_tick_timer: float = 0.0

@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var aura_area: Area2D = $BlessingAura

func _ready() -> void:
	add_to_group("goddess")
	current_hp = max_hp
	hurtbox.is_player_team = true
	hurtbox.hit_received.connect(_on_hit_received)

func _process(delta: float) -> void:
	anim_timer += delta
	heal_tick_timer += delta
	
	# 神聖光環每秒為光環內的友軍治療
	if heal_tick_timer >= 1.0 and not is_destroyed:
		heal_tick_timer = 0.0
		_heal_allies_in_aura()
		
	queue_redraw()

func _heal_allies_in_aura() -> void:
	var bodies = aura_area.get_overlapping_bodies()
	for b in bodies:
		if b.is_in_group("player"):
			var heal_amount = int(Global.max_hp * 0.05) + 15
			var mana_amount = int(Global.max_mp * 0.05) + 10
			Global.hp = min(Global.max_hp, Global.hp + heal_amount)
			Global.mp = min(Global.max_mp, Global.mp + mana_amount)
			EventBus.player_health_changed.emit(Global.hp, Global.max_hp)
			EventBus.player_mana_changed.emit(Global.mp, Global.max_mp)
			EventBus.damage_spawned.emit(b.global_position + Vector2(0, -25), "+%d HP" % heal_amount, Color(0.3, 1.0, 0.5), false, false)

func _on_hit_received(dmg: int, _is_crit: bool, _is_effective: bool, _knock_dir: Vector2, _knock_force: float) -> void:
	if is_destroyed:
		return
		
	current_hp -= dmg
	current_hp = max(0, current_hp)
	EventBus.damage_spawned.emit(global_position + Vector2(0, -60), "女神受擊! -%d" % dmg, Color(1.0, 0.2, 0.2), true, true)
	
	if current_hp <= 0:
		is_destroyed = true
		EventBus.show_banner_notification.emit("女神之像遭到摧毀！", "法蘭城的守護光輝熄滅了...防守失敗！")
		SoundManager.play_meteor_explosion()

func get_hp_ratio() -> float:
	return float(current_hp) / float(max_hp)

func _draw() -> void:
	# 神聖光環半徑
	var aura_r = 180.0
	var pulse = sin(anim_timer * 3.0) * 8.0
	var aura_col = Color(1.0, 0.9, 0.4, 0.12)
	draw_circle(Vector2.ZERO, aura_r + pulse, aura_col)
	draw_arc(Vector2.ZERO, aura_r + pulse, 0, TAU, 36, Color(1.0, 0.85, 0.2, 0.35), 2.0)
	
	# 女神基座 (白金大理石紋理)
	draw_circle(Vector2(0, 16), 36.0, Color(0.2, 0.25, 0.35))
	draw_circle(Vector2(0, 12), 32.0, Color(0.85, 0.88, 0.95))
	draw_arc(Vector2(0, 12), 32.0, 0, TAU, 24, Color(1.0, 0.8, 0.2), 3.0)
	
	# 女神雕像 (愛謝拉女神像：潔白長袍、天使羽翼、手托神聖水晶)
	var float_y = sin(anim_timer * 4.0) * 3.0
	var base_y = -10.0 + float_y
	
	# 神聖羽翼
	var wing_l = PackedVector2Array([Vector2(0, base_y), Vector2(-36, base_y - 25), Vector2(-28, base_y + 15)])
	var wing_r = PackedVector2Array([Vector2(0, base_y), Vector2(36, base_y - 25), Vector2(28, base_y + 15)])
	draw_colored_polygon(wing_l, Color(1.0, 0.98, 0.85, 0.9))
	draw_colored_polygon(wing_r, Color(1.0, 0.98, 0.85, 0.9))
	
	# 身軀與金光神袍
	draw_circle(Vector2(0, base_y + 6), 16.0, Color(0.95, 0.95, 1.0))
	draw_circle(Vector2(0, base_y - 14), 10.0, Color(1.0, 0.9, 0.75)) # 頭部
	draw_circle(Vector2(0, base_y - 18), 12.0, Color(1.0, 0.85, 0.2, 0.4)) # 神聖光環 (Halo)
	draw_arc(Vector2(0, base_y - 18), 12.0, 0, TAU, 16, Color(1.0, 0.9, 0.3), 2.0)
	
	# 手托神聖水晶 (緩慢旋轉發光)
	var crystal_pos = Vector2(0, base_y - 36)
	var c_pts = PackedVector2Array([
		crystal_pos + Vector2(0, -12),
		crystal_pos + Vector2(8, 0),
		crystal_pos + Vector2(0, 12),
		crystal_pos + Vector2(-8, 0)
	])
	draw_colored_polygon(c_pts, Color(0.3, 0.7, 1.0, 0.9))
	draw_polyline(c_pts, Color(0.8, 0.95, 1.0), 2.0)
	
	# 雕像血條
	var bar_w = 64.0
	var bar_h = 6.0
	var bar_pos = Vector2(-bar_w/2, -65.0)
	var hp_r = get_hp_ratio()
	draw_rect(Rect2(bar_pos, Vector2(bar_w, bar_h)), Color(0.1, 0.1, 0.1, 0.9), true)
	draw_rect(Rect2(bar_pos, Vector2(bar_w * hp_r, bar_h)), Color(1.0, 0.8, 0.1), true)
	draw_rect(Rect2(bar_pos, Vector2(bar_w, bar_h)), Color(1.0, 1.0, 1.0), false, 1.0)
