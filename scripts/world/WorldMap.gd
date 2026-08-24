extends Node2D

const MonsterDatabase = preload("res://scripts/data/MonsterDatabase.gd")
const EnemyBase = preload("res://scripts/entities/EnemyBase.gd")
var enemy_base_scene = preload("res://scenes/enemies/SlimeEnemy.tscn")

var wild_spawn_timer: float = 0.0
var anim_timer: float = 0.0

# 10 大地圖分區定義
const REGIONS = [
	{ "id": "farlan", "name": "法蘭城 王都", "rect": Rect2(0, 0, 1000, 1000), "bg_col": Color(0.38, 0.4, 0.44), "spawn": Vector2(400, 480), "races": ["特殊系", "人形系"] },
	{ "id": "freya", "name": "芙蕾雅島·東門原野", "rect": Rect2(1000, 0, 1200, 1000), "bg_col": Color(0.28, 0.58, 0.26), "spawn": Vector2(1200, 450), "races": ["昆蟲系", "特殊系"] },
	{ "id": "habaru", "name": "哈巴魯東邊洞穴", "rect": Rect2(2200, 0, 1200, 1000), "bg_col": Color(0.22, 0.18, 0.15), "spawn": Vector2(2400, 450), "races": ["野獸系", "昆蟲系"] },
	{ "id": "cemetery", "name": "靈堂·地下迷宮", "rect": Rect2(0, 1000, 1000, 1000), "bg_col": Color(0.12, 0.15, 0.25), "spawn": Vector2(300, 1300), "races": ["不死系"] },
	{ "id": "mine", "name": "國營第24號坑道", "rect": Rect2(1000, 1000, 1200, 1000), "bg_col": Color(0.25, 0.22, 0.2), "spawn": Vector2(1300, 1300), "races": ["金屬系", "人形系"] },
	{ "id": "venoa", "name": "維諾亞村與水之洞穴", "rect": Rect2(2200, 1000, 1200, 1000), "bg_col": Color(0.15, 0.35, 0.45), "spawn": Vector2(2500, 1300), "races": ["植物系", "龍系"] },
	{ "id": "ninja", "name": "烏克蘭村·忍者之里", "rect": Rect2(0, 2000, 1000, 1000), "bg_col": Color(0.12, 0.32, 0.18), "spawn": Vector2(300, 2300), "races": ["人形系", "改造寵"] },
	{ "id": "desert", "name": "索奇亞荒漠·奇利村", "rect": Rect2(1000, 2000, 1200, 1000), "bg_col": Color(0.72, 0.62, 0.35), "spawn": Vector2(1300, 2300), "races": ["野獸系", "昆蟲系", "植物系"] },
	{ "id": "snow", "name": "莎蓮娜島·雪山之巔", "rect": Rect2(2200, 2000, 1200, 1000), "bg_col": Color(0.85, 0.9, 0.98), "spawn": Vector2(2500, 2300), "races": ["野獸系", "飛行系", "金屬系"] },
	{ "id": "abyss", "name": "阿卡斯祭壇·神域深淵", "rect": Rect2(1000, 3000, 1400, 1200), "bg_col": Color(0.08, 0.05, 0.15), "spawn": Vector2(1500, 3300), "races": ["邪魔系", "龍系", "家族獸"] }
]

func _ready() -> void:
	_spawn_all_wild_zones()

func _process(delta: float) -> void:
	anim_timer += delta
	wild_spawn_timer += delta
	if wild_spawn_timer >= 5.0:
		wild_spawn_timer = 0.0
		_maintain_wild_population()
	queue_redraw()

func _spawn_all_wild_zones() -> void:
	for reg in REGIONS:
		if reg["id"] == "farlan": continue
		var races_list = reg.get("races", ["特殊系"])
		for i in range(12): # 每張地圖初始生成 12 隻原生野怪
			var pick_race = races_list[i % races_list.size()]
			var race_monsters = MonsterDatabase.get_monsters_by_race(pick_race)
			if race_monsters.size() > 0:
				var m_data = race_monsters[randi() % race_monsters.size()]
				var rand_p = Vector2(
					randf_range(reg["rect"].position.x + 80, reg["rect"].position.x + reg["rect"].size.x - 80),
					randf_range(reg["rect"].position.y + 80, reg["rect"].position.y + reg["rect"].size.y - 80)
				)
				_spawn_single_wild_monster(m_data, rand_p)

func _spawn_single_wild_monster(m_data: Dictionary, pos: Vector2) -> void:
	var enemy = enemy_base_scene.instantiate() as EnemyBase
	enemy.global_position = pos
	enemy.is_wave_attacker = false
	add_child(enemy)
	enemy.setup_from_monster_data(m_data, 1)

func _maintain_wild_population() -> void:
	var cur_enemies = get_tree().get_nodes_in_group("enemies").size()
	if cur_enemies < 75: # 維持全地圖充足的野怪數量
		var valid_regions = []
		for r in REGIONS:
			if r["id"] != "farlan": valid_regions.append(r)
		var reg = valid_regions[randi() % valid_regions.size()]
		var races_list = reg.get("races", ["特殊系"])
		var pick_race = races_list[randi() % races_list.size()]
		var race_monsters = MonsterDatabase.get_monsters_by_race(pick_race)
		if race_monsters.size() > 0:
			var rand_m = race_monsters[randi() % race_monsters.size()]
			var rand_p = Vector2(
				randf_range(reg["rect"].position.x + 80, reg["rect"].position.x + reg["rect"].size.x - 80),
				randf_range(reg["rect"].position.y + 80, reg["rect"].position.y + reg["rect"].size.y - 80)
			)
			_spawn_single_wild_monster(rand_m, rand_p)

func _get_region_by_id(id: String) -> Dictionary:
	for r in REGIONS:
		if r["id"] == id: return r
	return REGIONS[0]

func get_region_at_position(pos: Vector2) -> String:
	for r in REGIONS:
		if r["rect"].has_point(pos):
			return r["name"]
	return "未知之境"

func _draw() -> void:
	# 繪製 10 大地圖地貌
	for r in REGIONS:
		draw_rect(r["rect"], r["bg_col"], true)
		draw_rect(r["rect"], Color(0.1, 0.1, 0.15, 0.7), false, 4.0)
		
	# 1. 法蘭城 王都 (0 ~ 1000, 0 ~ 1000) 地磚與城牆
	for x in range(0, 1000, 40):
		draw_line(Vector2(x, 0), Vector2(x, 1000), Color(0.32, 0.34, 0.38), 1.0)
	for y in range(0, 1000, 40):
		draw_line(Vector2(0, y), Vector2(1000, y), Color(0.32, 0.34, 0.38), 1.0)
		
	# 法蘭城東門護城河與石橋
	draw_rect(Rect2(800, 0, 120, 1000), Color(0.12, 0.35, 0.65), true)
	draw_rect(Rect2(780, 420, 160, 140), Color(0.5, 0.48, 0.45), true)
	draw_rect(Rect2(780, 420, 160, 140), Color(0.9, 0.8, 0.2), false, 2.0)
	
	# 2. 城外魔界出怪傳送門 (X: 1300, Y: 500)
	var portal_p = Vector2(1300, 500)
	var p_pulse = sin(anim_timer * 8.0) * 8.0
	draw_circle(portal_p, 48.0 + p_pulse, Color(0.1, 0.05, 0.15, 0.9))
	draw_arc(portal_p, 48.0 + p_pulse, 0, TAU, 32, Color(1.0, 0.15, 0.15), 4.0)
	draw_arc(portal_p, 32.0 - p_pulse * 0.5, 0, TAU, 24, Color(1.0, 0.75, 0.2), 2.5)
	for i in range(6):
		var a = (TAU / 6.0) * i + anim_timer * 4.0
		draw_line(portal_p, portal_p + Vector2.from_angle(a) * (45.0 + p_pulse), Color(1.0, 0.3, 0.1, 0.7), 2.0)
		
	# 3. 傳送石矩陣 (法蘭城中央傳送廣場 X: 400, Y: 580)
	var tp_pos = Vector2(400, 580)
	draw_circle(tp_pos, 28.0, Color(0.2, 0.4, 0.8, 0.6))
	draw_arc(tp_pos, 28.0, 0, TAU, 24, Color(0.3, 0.9, 1.0), 3.0)
	draw_circle(tp_pos, 8.0, Color(0.6, 1.0, 1.0))
