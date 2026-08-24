extends Node2D
class_name IsometricWorldMap

const MonsterDatabase = preload("res://scripts/data/MonsterDatabase.gd")
const EnemyBase = preload("res://scripts/entities/EnemyBase.gd")
var enemy_base_scene = preload("res://scenes/enemies/SlimeEnemy.tscn")

var anim_timer: float = 0.0
var wild_spawn_timer: float = 0.0

# 4 座巨大跨海石橋與城外傳送門座標 (東南、東北、西南、西北)
# 中心點：法蘭城/馬斯城中央大廣場 (Vector2(600, 500))
const CENTER_POS = Vector2(600, 500)
const GATE_SW = Vector2(-150, 1050) # 西南方城外島嶼 (長橋起點)
const GATE_NE = Vector2(1350, -50)  # 東北方城外島嶼 (長橋起點)
const GATE_NW = Vector2(-150, -50)  # 西北方城外島嶼 (長橋起點)
const GATE_SE = Vector2(1350, 1050) # 東南方城外島嶼 (長橋起點)

# 4 個出怪點
const SPAWN_GATES = [
	{ "id": "SW", "pos": GATE_SW, "bridge_start": GATE_SW + Vector2(60, -40), "bridge_end": CENTER_POS + Vector2(-120, 80) },
	{ "id": "NE", "pos": GATE_NE, "bridge_start": GATE_NE + Vector2(-60, 40), "bridge_end": CENTER_POS + Vector2(120, -80) },
	{ "id": "NW", "pos": GATE_NW, "bridge_start": GATE_NW + Vector2(60, 40), "bridge_end": CENTER_POS + Vector2(-120, -80) },
	{ "id": "SE", "pos": GATE_SE, "bridge_start": GATE_SE + Vector2(-60, -40), "bridge_end": CENTER_POS + Vector2(120, 80) }
]

var map_data: Dictionary = {
	"id": "masu",
	"name": "艾爾巴尼亞·馬斯城",
	"level_min": 15,
	"level_max": 30,
	"water_color": Color(0.12, 0.45, 0.78),
	"land_color": Color(0.35, 0.65, 0.32),
	"stone_color": Color(0.48, 0.52, 0.58),
	"races": ["野獸系", "金屬系", "人形系"]
}

func _ready() -> void:
	if has_node("/root/MapManager"):
		var mm = get_node("/root/MapManager")
		mm.map_changed.connect(_on_map_changed)
		map_data = mm.get_current_map()
	_spawn_all_wild_zones()

func _on_map_changed(_map_id: String, new_data: Dictionary) -> void:
	map_data = new_data
	# 清除場上野怪並重新生成該地圖等級野怪
	var cur_enemies = get_tree().get_nodes_in_group("enemies")
	for e in cur_enemies:
		if is_instance_valid(e) and not e.is_wave_attacker:
			e.queue_free()
	_spawn_all_wild_zones()
	queue_redraw()

func _process(delta: float) -> void:
	anim_timer += delta
	wild_spawn_timer += delta
	if wild_spawn_timer >= 5.0:
		wild_spawn_timer = 0.0
		_maintain_wild_population()
	queue_redraw()

func _spawn_all_wild_zones() -> void:
	var races = map_data.get("races", ["特殊系"])
	var lvl_min = map_data.get("level_min", 1)
	var lvl_max = map_data.get("level_max", 15)
	
	# 在 4 個城外島嶼生成各 6 隻野怪
	for g in SPAWN_GATES:
		for i in range(5):
			var pick_race = races[randi() % races.size()]
			var m_list = MonsterDatabase.get_monsters_by_race(pick_race)
			if m_list.size() > 0:
				var m = m_list[randi() % m_list.size()]
				var rand_pos = g["pos"] + Vector2(randf_range(-90, 90), randf_range(-70, 70))
				_spawn_single_wild_monster(m, rand_pos, randi_range(lvl_min, lvl_max))

func _spawn_single_wild_monster(m_data: Dictionary, pos: Vector2, level: int) -> void:
	var enemy = enemy_base_scene.instantiate() as EnemyBase
	enemy.global_position = pos
	enemy.is_wave_attacker = false
	add_child(enemy)
	enemy.setup_from_monster_data(m_data, level)

func _maintain_wild_population() -> void:
	var cur_enemies = 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and not e.is_wave_attacker:
			cur_enemies += 1
			
	if cur_enemies < 30:
		var g = SPAWN_GATES[randi() % SPAWN_GATES.size()]
		var races = map_data.get("races", ["特殊系"])
		var pick_race = races[randi() % races.size()]
		var m_list = MonsterDatabase.get_monsters_by_race(pick_race)
		if m_list.size() > 0:
			var m = m_list[randi() % m_list.size()]
			var rand_pos = g["pos"] + Vector2(randf_range(-90, 90), randf_range(-70, 70))
			_spawn_single_wild_monster(m, rand_pos, randi_range(map_data.get("level_min", 1), map_data.get("level_max", 15)))

func _draw() -> void:
	var water_c = map_data.get("water_color", Color(0.12, 0.45, 0.78))
	var land_c = map_data.get("land_color", Color(0.35, 0.65, 0.32))
	var stone_c = map_data.get("stone_color", Color(0.48, 0.52, 0.58))
	
	# 1. 廣闊 3D 蔚藍水面與動態波紋背景
	draw_rect(Rect2(-800, -800, 2800, 2800), water_c, true)
	for i in range(12):
		var w_y = -600 + i * 200 + sin(anim_timer * 1.5 + i) * 15.0
		draw_line(Vector2(-700, w_y), Vector2(2000, w_y), water_c.lightened(0.15), 3.0)
		
	# 2. 繪製 4 座跨海巨大 3D 石橋 (通往西南、東北、西北、東南四方)
	for g in SPAWN_GATES:
		_draw_isometric_bridge(g["bridge_start"], g["bridge_end"], stone_c)
		
	# 3. 繪製 4 個城外島嶼 (出怪裂隙島)
	for g in SPAWN_GATES:
		_draw_isometric_island(g["pos"], Vector2(160, 110), land_c, stone_c)
		# 魔界傳送門裂隙
		var p_pulse = sin(anim_timer * 8.0) * 6.0
		draw_circle(g["pos"], 36.0 + p_pulse, Color(0.1, 0.05, 0.15, 0.9))
		draw_arc(g["pos"], 36.0 + p_pulse, 0, TAU, 28, Color(1.0, 0.2, 0.2), 3.5)
		draw_arc(g["pos"], 24.0 - p_pulse * 0.4, 0, TAU, 20, Color(1.0, 0.8, 0.2), 2.5)
		
	# 4. 繪製中央主城海島 (馬斯城 / 法蘭城 經典 2.5D Isometric 八角海島要塞)
	_draw_central_fortress_city(CENTER_POS, land_c, stone_c)
	
	# 5. 繪製中央神聖愛謝拉大聖堂 (3D 建築本體、紅色地毯與金色十字架)
	_draw_central_cathedral(CENTER_POS + Vector2(0, -60))
	
	# 6. 繪製 8 座 3D 守護石塔與防禦箭塔
	var tower_offsets = [
		Vector2(-160, -120), Vector2(160, -120),
		Vector2(-240, 0), Vector2(240, 0),
		Vector2(-160, 140), Vector2(160, 140),
		Vector2(-90, 220), Vector2(90, 220)
	]
	for off in tower_offsets:
		_draw_isometric_tower(CENTER_POS + off, stone_c)

func _draw_isometric_island(center: Vector2, size: Vector2, l_col: Color, s_col: Color) -> void:
	# 3D 浮島厚度陰影
	var pts_depth = PackedVector2Array([
		center + Vector2(-size.x, 0),
		center + Vector2(0, size.y),
		center + Vector2(size.x, 0),
		center + Vector2(size.x, 24),
		center + Vector2(0, size.y + 24),
		center + Vector2(-size.x, 24)
	])
	draw_colored_polygon(pts_depth, s_col.darkened(0.45))
	
	# 浮島綠茵表面 (Isometric Diamond)
	var pts_top = PackedVector2Array([
		center + Vector2(0, -size.y),
		center + Vector2(size.x, 0),
		center + Vector2(0, size.y),
		center + Vector2(-size.x, 0)
	])
	draw_colored_polygon(pts_top, l_col)
	draw_polyline(pts_top, l_col.lightened(0.2), 2.0)

func _draw_isometric_bridge(p1: Vector2, p2: Vector2, col: Color) -> void:
	var perp = (p2 - p1).orthogonal().normalized() * 24.0
	# 橋身立體厚度
	var b_depth = PackedVector2Array([
		p1 + perp, p2 + perp,
		p2 + perp + Vector2(0, 16), p1 + perp + Vector2(0, 16)
	])
	draw_colored_polygon(b_depth, col.darkened(0.4))
	
	# 橋面大理石地磚
	var b_top = PackedVector2Array([
		p1 - perp, p2 - perp,
		p2 + perp, p1 + perp
	])
	draw_colored_polygon(b_top, col.lightened(0.1))
	# 橋兩側金屬護欄與石雕燈柱
	draw_line(p1 - perp, p2 - perp, Color(0.9, 0.8, 0.3), 3.0)
	draw_line(p1 + perp, p2 + perp, Color(0.9, 0.8, 0.3), 3.0)
	# 橋面中線
	draw_line(p1, p2, col.lightened(0.3), 2.0)

func _draw_central_fortress_city(center: Vector2, l_col: Color, s_col: Color) -> void:
	var rx = 440.0
	var ry = 300.0
	
	# 1. 3D 海島基座厚度
	var pts_depth = PackedVector2Array([
		center + Vector2(-rx, 0),
		center + Vector2(0, ry),
		center + Vector2(rx, 0),
		center + Vector2(rx, 35),
		center + Vector2(0, ry + 35),
		center + Vector2(-rx, 35)
	])
	draw_colored_polygon(pts_depth, s_col.darkened(0.5))
	
	# 2. 主島草坪表面
	var pts_top = PackedVector2Array([
		center + Vector2(0, -ry),
		center + Vector2(rx, 0),
		center + Vector2(0, ry),
		center + Vector2(-rx, 0)
	])
	draw_colored_polygon(pts_top, l_col)
	
	# 3. 3D 十字形石板主幹大道 (寬 70px)
	var st_w = 60.0
	var road_h = PackedVector2Array([
		center + Vector2(-rx + 30, -st_w * 0.4),
		center + Vector2(rx - 30, -st_w * 0.4),
		center + Vector2(rx - 30, st_w * 0.4),
		center + Vector2(-rx + 30, st_w * 0.4)
	])
	draw_colored_polygon(road_h, s_col)
	
	var road_v = PackedVector2Array([
		center + Vector2(-st_w * 0.7, -ry + 30),
		center + Vector2(st_w * 0.7, -ry + 30),
		center + Vector2(st_w * 0.7, ry - 30),
		center + Vector2(-st_w * 0.7, ry - 30)
	])
	draw_colored_polygon(road_v, s_col)
	
	# 中央大理石八角廣場
	var pts_plaza = PackedVector2Array()
	for i in range(8):
		var a = (TAU / 8.0) * i
		pts_plaza.append(center + Vector2(cos(a) * 110.0, sin(a) * 80.0))
	draw_colored_polygon(pts_plaza, s_col.lightened(0.2))
	draw_polyline(pts_plaza, Color(0.9, 0.8, 0.3), 3.0)

func _draw_central_cathedral(pos: Vector2) -> void:
	# 3D 宏偉愛謝拉大聖堂
	var b_w = 110.0
	var b_h = 90.0
	var wall_col = Color(0.78, 0.75, 0.72)
	var roof_col = Color(0.65, 0.25, 0.25)
	
	# 聖堂陰影
	draw_circle(pos + Vector2(0, 45), 65.0, Color(0, 0, 0, 0.4))
	
	# 聖堂紅地毯步道
	var carpet = PackedVector2Array([
		pos + Vector2(-22, 10), pos + Vector2(22, 10),
		pos + Vector2(30, 95), pos + Vector2(-30, 95)
	])
	draw_colored_polygon(carpet, Color(0.85, 0.15, 0.2))
	draw_line(pos + Vector2(-22, 10), pos + Vector2(-30, 95), Color(1.0, 0.8, 0.2), 2.0)
	draw_line(pos + Vector2(22, 10), pos + Vector2(30, 95), Color(1.0, 0.8, 0.2), 2.0)
	
	# 牆體
	var wall_pts = PackedVector2Array([
		pos + Vector2(-b_w/2, -b_h/2), pos + Vector2(b_w/2, -b_h/2),
		pos + Vector2(b_w/2, b_h/2), pos + Vector2(-b_w/2, b_h/2)
	])
	draw_colored_polygon(wall_pts, wall_col)
	
	# 3D 尖頂屋頂
	var roof_pts = PackedVector2Array([
		pos + Vector2(-b_w/2 - 8, -b_h/2),
		pos + Vector2(0, -b_h - 25),
		pos + Vector2(b_w/2 + 8, -b_h/2)
	])
	draw_colored_polygon(roof_pts, roof_col)
	
	# 頂部金色聖十字架
	var cross_p = pos + Vector2(0, -b_h - 40)
	draw_line(cross_p + Vector2(0, -16), cross_p + Vector2(0, 16), Color(1.0, 0.85, 0.2), 4.0)
	draw_line(cross_p + Vector2(-12, -4), cross_p + Vector2(12, -4), Color(1.0, 0.85, 0.2), 4.0)

func _draw_isometric_tower(pos: Vector2, col: Color) -> void:
	# 3D 圓柱防禦石塔
	var r = 18.0
	var h = 42.0
	draw_circle(pos + Vector2(0, 10), r, Color(0, 0, 0, 0.35))
	
	# 塔身
	var body_pts = PackedVector2Array([
		pos + Vector2(-r, -h), pos + Vector2(r, -h),
		pos + Vector2(r, 0), pos + Vector2(-r, 0)
	])
	draw_colored_polygon(body_pts, col)
	
	# 塔頂圓錐屋頂
	var roof_pts = PackedVector2Array([
		pos + Vector2(-r - 4, -h),
		pos + Vector2(0, -h - 22),
		pos + Vector2(r + 4, -h)
	])
	draw_colored_polygon(roof_pts, Color(0.2, 0.45, 0.85))
	draw_circle(pos + Vector2(0, -h - 24), 3.5, Color(1.0, 0.85, 0.2))
