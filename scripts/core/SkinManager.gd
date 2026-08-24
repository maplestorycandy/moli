extends Node

signal skin_changed(skin_data: Dictionary)

const MonsterDatabase = preload("res://scripts/data/MonsterDatabase.gd")

var HERO_SKINS: Array[Dictionary] = [
	{
		"id": "shin_classic",
		"name": "辛 (Shin) - 經典勇者",
		"title": "初心者之光",
		"desc": "《魔力寶貝》代表性主角，金髮藍斗篷的少年劍士",
		"num": "001",
		"is_custom_draw": true,
		"scale": 1.0
	},
	{
		"id": "seth_fighter",
		"name": "謝堤 (Seth) - 熱血鬥士",
		"title": "無雙格鬥家",
		"desc": "赤髮短打的近戰武道達人，出拳迅猛凌厲",
		"num": "027",
		"is_custom_draw": false,
		"scale": 1.0
	},
	{
		"id": "fait_knight",
		"name": "菲特 (Fait) - 貴族劍聖",
		"title": "銀光神劍手",
		"desc": "優雅的銀髮劍術名門傳人，劍光如流星劃破長空",
		"num": "140",
		"is_custom_draw": false,
		"scale": 1.0
	},
	{
		"id": "burke_berserker",
		"name": "伯克 (Burke) - 狂暴重戰士",
		"title": "撼地巨斧",
		"desc": "披甲握斧的豪邁壯漢，乾坤一擲威震四方",
		"num": "146",
		"is_custom_draw": false,
		"scale": 1.05
	},
	{
		"id": "sarah_ranger",
		"name": "莎拉 (Sarah) - 精靈遊俠",
		"title": "百步穿楊",
		"desc": "穿梭於芙蕾雅森林的綠衣弓箭手少女",
		"num": "081",
		"is_custom_draw": false,
		"scale": 0.95
	},
	{
		"id": "amy_mage",
		"name": "艾咪 (Amy) - 天才魔術師",
		"title": "元素賢者",
		"desc": "手持法杖精通四系超強魔法的活潑少女",
		"num": "140020",
		"is_custom_draw": false,
		"scale": 0.95
	},
	{
		"id": "rei_priest",
		"name": "麗 (Rei) - 聖潔大祭司",
		"title": "神聖恩典",
		"desc": "身著白金法袍的女神侍女，具備超強治癒之力",
		"num": "140050",
		"is_custom_draw": false,
		"scale": 0.95
	},
	{
		"id": "ruby_boss",
		"name": "露比 (Ruby) - 邪魔少女",
		"title": "夜之主宰",
		"desc": "手持紅傘的神秘邪魔蘿莉，魔力滔天",
		"num": "081",
		"is_custom_draw": false,
		"scale": 1.0
	},
	{
		"id": "ozunac_warrior",
		"name": "熱砂之歐茲那克 - 熊男領主",
		"title": "哈巴魯霸主",
		"desc": "帶領九隻殺手雄雄霸洞穴的狂野壯漢",
		"num": "007",
		"is_custom_draw": false,
		"scale": 1.15
	},
	{
		"id": "judas_lord",
		"name": "猶大 (Judas) - 墮落巫王",
		"title": "神域審判者",
		"desc": "身披紫黑魔袍的阿卡斯神使，掌控神諭之劍",
		"num": "082",
		"is_custom_draw": false,
		"scale": 1.1
	},
	{
		"id": "riberius_god",
		"name": "軍神 李貝留斯",
		"title": "滅世戰神",
		"desc": "魔力寶貝世界的神明，無可匹敵的威壓與神格",
		"num": "140100",
		"is_custom_draw": false,
		"scale": 1.25
	},
	{
		"id": "ninja_shadow",
		"name": "烏克蘭暗影忍者",
		"title": "一擊必殺",
		"desc": "隱匿於烏克蘭村的暗殺之王，步法詭譎無影",
		"num": "148",
		"is_custom_draw": false,
		"scale": 1.0
	}
]

var current_skin_id: String = "shin_classic"
var current_skin_data: Dictionary = {}

func _ready() -> void:
	current_skin_data = HERO_SKINS[0]
	var human_monsters = MonsterDatabase.get_monsters_by_race("人形系")
	for m in human_monsters:
		var s_id = "skin_" + m.get("id", "")
		var exists = false
		for h in HERO_SKINS:
			if h["id"] == s_id or h["num"] == m.get("num", ""):
				exists = true
				break
		if not exists:
			HERO_SKINS.append({
				"id": s_id,
				"name": m.get("name", "英雄人物"),
				"title": "人形系 傳奇角色",
				"desc": "源自《魔力寶貝》%s 的專屬戰鬥英姿" % m.get("name", "人形系"),
				"num": m.get("num", "001"),
				"is_custom_draw": false,
				"scale": m.get("scale", 1.0)
			})

func select_skin(skin_id: String) -> void:
	for s in HERO_SKINS:
		if s["id"] == skin_id:
			current_skin_id = skin_id
			current_skin_data = s
			Global.player_title = s.get("title", "冒險者")
			skin_changed.emit(s)
			return

func get_current_skin() -> Dictionary:
	if current_skin_data.is_empty():
		current_skin_data = HERO_SKINS[0]
	return current_skin_data

func get_all_skins() -> Array[Dictionary]:
	return HERO_SKINS
