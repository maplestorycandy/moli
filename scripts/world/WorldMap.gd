extends Node2D

const MonsterDatabase = preload("res://scripts/data/MonsterDatabase.gd")
const EnemyBase = preload("res://scripts/entities/EnemyBase.gd")
var enemy_base_scene = preload("res://scenes/enemies/SlimeEnemy.tscn")

var anim_timer: float = 0.0
var wild_spawn_timer: float = 0.0

# 4 座巨大跨海石橋與城外傳送門座標 (東南、東北、西南、西北)
# 中心點：中央大聖堂與女神像 (Vector2(600, 500))
const CENTER_POS = Vector2(600, 500)
const GATE_SW = Vector2(-200, 1100) # 西南方城外島嶼 (長橋起點)
const GATE_NE = Vector2(1400, -100)  # 東北方城外島嶼 (長橋起點)
const GATE_NW = Vector2(-200, -100)  # 西北方城外島嶼 (長橋起點)
const GATE_SE = Vector2(1400, 1100) # 東南方城外島嶼 (長橋起點)

# 4 個出怪點
const SPAWN_GATES = [
	{ "id": "SW", "pos": GATE_SW, "bridge_start": GATE_SW + Vector2(60, -40), "bridge_end": CENTER_POS + Vector2(-150, 90) },
	{ "id": "NE", "pos": GATE_NE, "bridge_start": GATE_NE + Vector2(-60, 40), "bridge_end": CENTER_POS + Vector2(150, -90) },
	{ "id": "NW", "pos": GATE_NW, "bridge_start": GATE_NW + Vector2(60, 40), "bridge_end": CENTER_POS + Vector2(-150, -90) },
	{ "id": "SE", "pos": GATE_SE, "bridge_start": GATE_SE + Vector2(-60, -40), "bridge_end": CENTER_POS + Vector2(150, 90) }
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
	# 清除舊野怪並重新生成新地圖魔物
	var cur_enemies = get_tree().get_nodes_in_group("enemies")
	for e in cur_enemies:
		if is_instance_valid(e) and not e.is_wave_attacker:
			e.queue_free()
	_spawn_all_wild_zones()
	queue_redraw()

func _process(delta: float) -> void:
	anim_timer += delta
	wild_spawn_timer += delta
	if wild_spawn_timer >= 4.5:
		wild_spawn_timer = 0.0
		_maintain_wild_population()
	queue_redraw()

func _spawn_all_wild_zones() -> void:
	var races = map_data.get("races", ["特殊系"])
	var lvl_min = map_data.get("level_min", 1)
	var lvl_max = map_data.get("level_max", 15)
	
	# 在 4 個城外島嶼生成各 6 隻野怪
	for g in SPAWN_GATES:
		for i in range(6):
			var pick_race = races[randi() % races.size()]
			var m_list = MonsterDatabase.get_monsters_by_race(pick_race)
			if m_list.size() > 0:
				var m = m_list[randi() % m_list.size()]
				var rand_pos = g["pos"] + Vector2(randf_range(-100, 100), randf_range(-80, 80))
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
			
	if cur_enemies < 35:
		var g = SPAWN_GATES[randi() % SPAWN_GATES.size()]
		var races = map_data.get("races", ["特殊系"])
		var pick_race = races[randi() % races.size()]
		var m_list = MonsterDatabase.get_monsters_by_race(pick_race)
		if m_list.size() > 0:
			var m = m_list[randi() % m_list.size()]
			var rand_pos = g["pos"] + Vector2(randf_range(-100, 100), randf_range(-80, 80))
			_spawn_single_wild_monster(m, rand_pos, randi_range(map_data.get("level_min", 1), map_data.get("level_max", 15)))

func get_region_at_position(pos: Vector2) -> String:
	var dist = pos.distance_to(CENTER_POS)
	if dist < 420.0:
		return map_data.get("name", "主城要塞")
	for g in SPAWN_GATES:
		if pos.distance_to(g["pos"]) < 260.0:
			return "%s·城外%s荒野" % [map_data.get("name", "要塞"), g["id"]]
	return "%s·跨海長橋" % map_data.get("name", "要塞")

func _draw() -> void:
	var water_c = map_data.get("water_color", Color(0.12, 0.45, 0.78))
	var land_c = map_data.get("land_color", Color(0.35, 0.65, 0.32))
	var stone_c = map_data.get("stone_color", Color(0.48, 0.52, 0.58))
	
	# 1. 廣闊 3D 蔚藍水面與動態波紋背景
	draw_rect(Rect2(-1000, -1000, 3200, 3200), water_c, true)
	for i in range(16):
		var w_y = -800 + i * 180 + sin(anim_timer * 1.5 + i) * 16.0
		draw_line(Vector2(-900, w_y), Vector2(2300, w_y), water_c.lightened(0.15), 3.5)
		
	# 2. 繪製 4 座跨海巨大 3D 石橋 (通往西南、東北、西北、東南四方)
	for g in SPAWN_GATES:
		_draw_isometric_bridge(g["bridge_start"], g["bridge_end"], stone_c)
		
	# 3. 繪製 4 個城外島嶼 (出怪裂隙島)
	for g in SPAWN_GATES:
		_draw_isometric_island(g["pos"], Vector2(190, 130), land_c, stone_c)
		# 魔界傳送門裂隙
		var p_pulse = sin(anim_timer * 8.0) * 8.0
		draw_circle(g["pos"], 42.0 + p_pulse, Color(0.1, 0.05, 0.15, 0.9))
		draw_arc(g["pos"], 42.0 + p_pulse, 0, TAU, 32, Color(1.0, 0.2, 0.2), 4.0)
		draw_arc(g["pos"], 28.0 - p_pulse * 0.4, 0, TAU, 24, Color(1.0, 0.8, 0.2), 3.0)
		
	# 4. 繪製中央主城海島 (馬斯城 / 法蘭城 經典 2.5D Isometric 八角海島要塞)
	_draw_central_fortress_city(CENTER_POS, land_c, stone_c)
	
	# 5. 繪製中央神聖愛謝拉大聖堂 (3D 建築本體、紅色地毯與金色十字架)
	_draw_central_cathedral(CENTER_POS + Vector2(0, -70))
	
	# 6. 繪製 8 座 3D 守護石塔與防禦箭塔
	var tower_offsets = [
		Vector2(-190, -140), Vector2(190, -140),
		Vector2(-280, 0), Vector2(280, 0),
		Vector2(-190, 160), Vector2(190, 160),
		Vector2(-100, 250), Vector2(100, 250)
	]
	for off in tower_offsets:
		_draw_isometric_tower(CENTER_POS + off, stone_c)

func _draw_isometric_island(center: Vector2, size: Vector2, l_col: Color, s_col: Color) -> void:
	# 3D 浮島厚度陰影
	var pts_depth = PackedVector2Array([
		center + Vector2(-size.x, 0),
		center + Vector2(0, size.y),
		center + Vector2(size.x, 0),
		center + Vector2(size.x, 30),
		center + Vector2(0, size.y + 30),
		center + Vector2(-size.x, 30)
	])
	draw_colored_polygon(pts_depth, s_col.darkened(0.5))
	
	# 浮島綠茵表面 (Isometric Diamond)
	var pts_top = PackedVector2Array([
		center + Vector2(0, -size.y),
		center + Vector2(size.x, 0),
		center + Vector2(0, size.y),
		center + Vector2(-size.x, 0)
	])
	draw_colored_polygon(pts_top, l_col)
	draw_polyline(pts_top, l_col.lightened(0.25), 2.5)

func _draw_isometric_bridge(p1: Vector2, p2: Vector2, col: Color) -> void:
	var perp = (p2 - p1).orthogonal().normalized() * 28.0
	# 橋身立體厚度
	var b_depth = PackedVector2Array([
		p1 + perp, p2 + perp,
		p2 + perp + Vector2(0, 20), p1 + perp + Vector2(0, 20)
	])
	draw_colored_polygon(b_depth, col.darkened(0.45))
	
	# 橋面大理石地磚
	var b_top = PackedVector2Array([
		p1 - perp, p2 - perp,
		p2 + perp, p1 + perp
	])
	draw_colored_polygon(b_top, col.lightened(0.12))
	# 橋兩側金屬護欄與石雕燈柱
	draw_line(p1 - perp, p2 - perp, Color(0.9, 0.8, 0.3), 3.5)
	draw_line(p1 + perp, p2 + perp, Color(0.9, 0.8, 0.3), 3.5)
	# 橋面中線
	draw_line(p1, p2, col.lightened(0.35), 2.5)

func _draw_central_fortress_city(center: Vector2, l_col: Color, s_col: Color) -> void:
	var rx = 480.0
	var ry = 330.0
	
	# 1. 3D 海島基座厚度
	var pts_depth = PackedVector2Array([
		center + Vector2(-rx, 0),
		center + Vector2(0, ry),
		center + Vector2(rx, 0),
		center + Vector2(rx, 40),
		center + Vector2(0, ry + 40),
		center + Vector2(-rx, 40)
	])
	draw_colored_polygon(pts_depth, s_col.darkened(0.55))
	
	# 2. 主島草坪表面
	var pts_top = PackedVector2Array([
		center + Vector2(0, -ry),
		center + Vector2(rx, 0),
		center + Vector2(0, ry),
		center + Vector2(-rx, 0)
	])
	draw_colored_polygon(pts_top, l_col)
	
	# 3. 3D 十字形石板主幹大道 (寬 75px)
	var st_w = 70.0
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
		pts_plaza.append(center + Vector2(cos(a) * 125.0, sin(a) * 90.0))
	draw_colored_polygon(pts_plaza, s_col.lightened(0.22))
	draw_polyline(pts_plaza, Color(0.95, 0.85, 0.3), 3.5)

func _draw_central_cathedral(pos: Vector2) -> void:
	# 3D 宏偉愛謝拉大聖堂
	var b_w = 125.0
	var b_h = 100.0
	var wall_col = Color(0.82, 0.78, 0.74)
	var roof_col = Color(0.72, 0.22, 0.22)
	
	# 聖堂陰影
	draw_circle(pos + Vector2(0, 50), 75.0, Color(0, 0, 0, 0.4))
	
	# 聖堂紅地毯步道
	var carpet = PackedVector2Array([
		pos + Vector2(-26, 12), pos + Vector2(26, 12),
		pos + Vector2(35, 110), pos + Vector2(-35, 110)
	])
	draw_colored_polygon(carpet, Color(0.9, 0.15, 0.2))
	draw_line(pos + Vector2(-26, 12), pos + Vector2(-35, 110), Color(1.0, 0.8, 0.2), 2.5)
	draw_line(pos + Vector2(26, 12), pos + Vector2(35, 110), Color(1.0, 0.8, 0.2), 2.5)
	
	# 牆體
	var wall_pts = PackedVector2Array([
		pos + Vector2(-b_w/2, -b_h/2), pos + Vector2(b_w/2, -b_h/2),
		pos + Vector2(b_w/2, b_h/2), pos + Vector2(-b_w/2, b_h/2)
	])
	draw_colored_polygon(wall_pts, wall_col)
	
	# 3D 尖頂屋頂
	var roof_pts = PackedVector2Array([
		pos + Vector2(-b_w/2 - 10, -b_h/2),
		pos + Vector2(0, -b_h - 30),
		pos + Vector2(b_w/2 + 10, -b_h/2)
	])
	draw_colored_polygon(roof_pts, roof_col)
	
	# 頂部金色聖十字架
	var cross_p = pos + Vector2(0, -b_h - 45)
	draw_line(cross_p + Vector2(0, -18), cross_p + Vector2(0, 18), Color(1.0, 0.88, 0.2), 4.5)
	draw_line(cross_p + Vector2(-14, -5), cross_p + Vector2(14, -5), Color(1.0, 0.88, 0.2), 4.5)

func _draw_isometric_tower(pos: Vector2, col: Color) -> void:
	# 3D 圓柱防禦石塔
	var r = 20.0
	var h = 48.0
	draw_circle(pos + Vector2(0, 12), r, Color(0, 0, 0, 0.35))
	
	# 塔身
	var body_pts = PackedVector2Array([
		pos + Vector2(-r, -h), pos + Vector2(r, -h),
		pos + Vector2(r, 0), pos + Vector2(-r, 0)
	])
	draw_colored_polygon(body_pts, col)
	
	# 塔頂圓錐屋頂
	var roof_pts = PackedVector2Array([
		pos + Vector2(-r - 5, -h),
		pos + Vector2(0, -h - 26),
		pos + Vector2(r + 5, -h)
	])
	draw_colored_polygon(roof_pts, Color(0.2, 0.45, 0.85))
	draw_circle(pos + Vector2(0, -h - 28), 4.0, Color(1.0, 0.85, 0.2))
