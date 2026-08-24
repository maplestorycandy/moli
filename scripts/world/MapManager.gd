extends Node

const MonsterDatabase = preload("res://scripts/data/MonsterDatabase.gd")

signal map_changed(map_id: String, map_data: Dictionary)

# 10+ 經典魔力寶貝 3D / 2.5D Isometric 戰鬥地圖資料庫
const MAPS_DATABASE = [
	{
		"id": "masu",
		"name": "艾爾巴尼亞·馬斯城",
		"level_min": 15,
		"level_max": 30,
		"theme": "ocean_fortress",
		"desc": "四周環海的宏偉十字要塞，四座巨大石橋通往四方魔界荒野島嶼",
		"water_color": Color(0.12, 0.45, 0.78),
		"land_color": Color(0.35, 0.65, 0.32),
		"stone_color": Color(0.48, 0.52, 0.58),
		"races": ["野獸系", "金屬系", "人形系"],
		"boss_id": "boss_ozunac"
	},
	{
		"id": "farlan",
		"name": "法蘭王國·法蘭城",
		"level_min": 1,
		"level_max": 15,
		"theme": "royal_city",
		"desc": "繁華的法蘭王國首都，愛謝拉女神像座落於中央大理石廣場",
		"water_color": Color(0.15, 0.35, 0.65),
		"land_color": Color(0.38, 0.62, 0.35),
		"stone_color": Color(0.55, 0.55, 0.6),
		"races": ["特殊系", "昆蟲系", "人形系"],
		"boss_id": "boss_ruby"
	},
	{
		"id": "akairufa",
		"name": "蘇國·阿凱魯法城",
		"level_min": 30,
		"level_max": 45,
		"theme": "port_city",
		"desc": "米內葛爾島的宏大港灣主城，外海魔獸頻繁侵襲",
		"water_color": Color(0.08, 0.38, 0.68),
		"land_color": Color(0.42, 0.68, 0.38),
		"stone_color": Color(0.62, 0.58, 0.52),
		"races": ["植物系", "龍系", "金屬系"],
		"boss_id": "boss_judas"
	},
	{
		"id": "golar",
		"name": "庫魯克斯·哥拉爾城",
		"level_min": 45,
		"level_max": 60,
		"theme": "imperial_city",
		"desc": "庫魯克斯島之帝國要衝，周圍盤據高階金屬怪與魔像軍團",
		"water_color": Color(0.1, 0.3, 0.55),
		"land_color": Color(0.32, 0.52, 0.35),
		"stone_color": Color(0.38, 0.42, 0.48),
		"races": ["金屬系", "不死系", "改造寵"],
		"boss_id": "boss_judas"
	},
	{
		"id": "kiri_desert",
		"name": "索奇亞·奇利荒漠城",
		"level_min": 25,
		"level_max": 40,
		"theme": "desert",
		"desc": "黃沙漫天的索奇亞沙漠綠洲要塞，毒蠍與狂暴野獸橫行",
		"water_color": Color(0.65, 0.55, 0.3),
		"land_color": Color(0.78, 0.68, 0.38),
		"stone_color": Color(0.68, 0.58, 0.42),
		"races": ["野獸系", "昆蟲系", "植物系"],
		"boss_id": "boss_ozunac"
	},
	{
		"id": "abanes_snow",
		"name": "莎蓮娜·阿巴尼斯雪鎮",
		"level_min": 40,
		"level_max": 55,
		"theme": "snow",
		"desc": "被厚重冰雪封鎖的北方雪鎮，雪狼與塞壬在此出沒",
		"water_color": Color(0.25, 0.5, 0.7),
		"land_color": Color(0.88, 0.92, 0.98),
		"stone_color": Color(0.72, 0.76, 0.85),
		"races": ["野獸系", "飛行系", "不死系"],
		"boss_id": "boss_ruby"
	},
	{
		"id": "snow_mountain",
		"name": "莎蓮娜·雪山之巔",
		"level_min": 60,
		"level_max": 80,
		"theme": "ice_peak",
		"desc": "世界頂峰的冰雪極境，古龍與極地巨獸的棲息地",
		"water_color": Color(0.3, 0.6, 0.85),
		"land_color": Color(0.92, 0.95, 1.0),
		"stone_color": Color(0.55, 0.65, 0.8),
		"races": ["龍系", "金屬系", "飛行系"],
		"boss_id": "boss_judas"
	},
	{
		"id": "god_abyss",
		"name": "阿卡斯祭壇·神域深淵",
		"level_min": 80,
		"level_max": 100,
		"theme": "abyss",
		"desc": "主神封印李貝留斯的萬丈神域深淵，極端兇殘的邪魔與墮天使軍團",
		"water_color": Color(0.05, 0.02, 0.12),
		"land_color": Color(0.18, 0.12, 0.28),
		"stone_color": Color(0.25, 0.2, 0.35),
		"races": ["邪魔系", "龍系", "家族獸"],
		"boss_id": "boss_riberius"
	}
]

var current_map_idx: int = 0
var current_map_data: Dictionary = {}

func _ready() -> void:
	_select_map(0)

func _select_map(idx: int) -> void:
	current_map_idx = clamp(idx, 0, MAPS_DATABASE.size() - 1)
	current_map_data = MAPS_DATABASE[current_map_idx]
	Global.current_map_name = current_map_data["name"]
	map_changed.emit(current_map_data["id"], current_map_data)

func switch_to_map(map_id: String) -> void:
	for i in range(MAPS_DATABASE.size()):
		if MAPS_DATABASE[i]["id"] == map_id or MAPS_DATABASE[i]["name"] == map_id:
			_select_map(i)
			return

func get_current_map() -> Dictionary:
	if current_map_data.is_empty():
		_select_map(0)
	return current_map_data

func get_all_maps() -> Array:
	return MAPS_DATABASE
