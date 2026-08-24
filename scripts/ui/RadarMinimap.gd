extends Control
class_name RadarMinimap

@export var map_world_size: Vector2 = Vector2(3400, 4200)
@export var radar_size: Vector2 = Vector2(220, 180)

var zoom_level: float = 1.0 # 1.0 = 全圖概覽, 2.5 = 區域特寫
var anim_timer: float = 0.0

@onready var panel: Panel = $Panel
@onready var zoom_btn: Button = $Panel/ZoomBtn
@onready var map_name_label: Label = $Panel/MapNameLabel

func _ready() -> void:
	zoom_btn.pressed.connect(_on_zoom_toggled)

func _process(delta: float) -> void:
	anim_timer += delta
	map_name_label.text = Global.current_map_name
	queue_redraw()

func _on_zoom_toggled() -> void:
	if zoom_level == 1.0:
		zoom_level = 2.5
		zoom_btn.text = "🔍 局部"
	else:
		zoom_level = 1.0
		zoom_btn.text = "🌐 全圖"

func _draw() -> void:
	var rect_pos = panel.position + Vector2(10, 32)
	var rect_size = Vector2(200, 138)
	
	# 雷達背景與網格
	draw_rect(Rect2(rect_pos, rect_size), Color(0.04, 0.08, 0.18, 0.92), true)
	draw_rect(Rect2(rect_pos, rect_size), Color(0.85, 0.7, 0.2), false, 1.5)
	
	# 雷達掃描線
	var scan_y = rect_pos.y + fmod(anim_timer * 60.0, rect_size.y)
	draw_line(Vector2(rect_pos.x, scan_y), Vector2(rect_pos.x + rect_size.x, scan_y), Color(0.2, 0.8, 1.0, 0.25), 1.5)
	
	# 中心基準點 (全圖模式以地圖中心為準，局部模式以玩家為準)
	var center_world_pos = map_world_size / 2.0
	if zoom_level > 1.0 and Global.player and is_instance_valid(Global.player):
		center_world_pos = Global.player.global_position
		
	var scale_factor = (rect_size.x / map_world_size.x) * zoom_level
	var radar_center = rect_pos + (rect_size / 2.0)
	
	# 1. 繪製城外魔界出怪傳送門 (紅黑旋渦光圈)
	var portal_world_pos = Vector2(1300, 500)
	var portal_radar_pos = radar_center + (portal_world_pos - center_world_pos) * scale_factor
	if _is_inside_radar(portal_radar_pos, rect_pos, rect_size):
		var p_r = 6.0 + sin(anim_timer * 10.0) * 2.0
		draw_circle(portal_radar_pos, p_r, Color(1.0, 0.1, 0.1, 0.7))
		draw_arc(portal_radar_pos, p_r + 2.0, 0, TAU, 12, Color(1.0, 0.8, 0.2), 1.5)
		
	# 2. 繪製中央愛謝拉女神像 (湛藍星形)
	var goddess = get_tree().get_first_node_in_group("goddess")
	if goddess and is_instance_valid(goddess):
		var g_radar_pos = radar_center + (goddess.global_position - center_world_pos) * scale_factor
		if _is_inside_radar(g_radar_pos, rect_pos, rect_size):
			draw_circle(g_radar_pos, 5.5, Color(0.2, 0.7, 1.0))
			draw_circle(g_radar_pos, 2.5, Color.WHITE)
			draw_arc(g_radar_pos, 8.0, 0, TAU, 16, Color(1.0, 0.85, 0.2), 1.0)
			
	# 3. 繪製所有怪物 (進攻怪 = 紅色三角 / 野怪 = 黃色圓點 / BOSS = 巨大骷髏紅圈)
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			var e_radar_pos = radar_center + (e.global_position - center_world_pos) * scale_factor
			if _is_inside_radar(e_radar_pos, rect_pos, rect_size):
				if "is_boss" in e and e.is_boss:
					# BOSS (巨大閃爍骷髏 / 紅色六角星)
					var b_r = 7.0 + sin(anim_timer * 12.0) * 2.0
					draw_circle(e_radar_pos, b_r, Color(1.0, 0.1, 0.1))
					draw_arc(e_radar_pos, b_r + 2.0, 0, TAU, 8, Color(1.0, 0.9, 0.2), 2.0)
				elif "is_wave_attacker" in e and e.is_wave_attacker:
					# 入侵進攻怪 (紅色小點)
					draw_circle(e_radar_pos, 2.5, Color(1.0, 0.2, 0.2))
				else:
					# 野怪 (黃色小點)
					draw_circle(e_radar_pos, 2.0, Color(1.0, 0.85, 0.3))
					
	# 4. 繪製出戰寵物 (翠綠小點)
	var pets = get_tree().get_nodes_in_group("pet")
	for p in pets:
		if is_instance_valid(p) and p.visible:
			var p_radar_pos = radar_center + (p.global_position - center_world_pos) * scale_factor
			if _is_inside_radar(p_radar_pos, rect_pos, rect_size):
				draw_circle(p_radar_pos, 3.5, Color(0.2, 1.0, 0.5))
				
	# 5. 繪製玩家本體 (金色旋轉箭頭)
	if Global.player and is_instance_valid(Global.player):
		var player_radar_pos = radar_center + (Global.player.global_position - center_world_pos) * scale_factor
		if _is_inside_radar(player_radar_pos, rect_pos, rect_size):
			var facing = Global.player.facing_direction.normalized()
			var tip = player_radar_pos + facing * 6.0
			var left_wing = player_radar_pos + facing.rotated(2.4) * 5.0
			var right_wing = player_radar_pos + facing.rotated(-2.4) * 5.0
			var arrow_pts = PackedVector2Array([tip, left_wing, player_radar_pos, right_wing])
			draw_colored_polygon(arrow_pts, Color(1.0, 0.9, 0.2))
			draw_circle(player_radar_pos, 2.0, Color.WHITE)

func _is_inside_radar(p: Vector2, rect_pos: Vector2, rect_size: Vector2) -> bool:
	return p.x >= rect_pos.x and p.x <= rect_pos.x + rect_size.x and p.y >= rect_pos.y and p.y <= rect_pos.y + rect_size.y
