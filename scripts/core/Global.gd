extends Node

# 玩家全域實例參照
var player: CharacterBody2D = null
var current_map_name: String = "法蘭城 東門"

# 玩家基礎數據 (經典五大配點)
var player_name: String = "辛 (Shin)"
var player_job: String = "見習劍士"
var player_title: String = "初心之冒險者"
var player_level: int = 1
var player_exp: int = 0
var player_max_exp: int = 100
var free_stat_points: int = 0
var free_skill_points: int = 1

# 五大基本配點
var stat_vit: int = 25 # 體力 (HP/回復)
var stat_str: int = 30 # 力量 (物攻)
var stat_tgh: int = 20 # 強度 (防禦)
var stat_agi: int = 20 # 速度 (敏捷/攻速/移速/迴避)
var stat_mag: int = 25 # 魔法 (MP/精神/魔攻)

# 動態衍生戰鬥數值
var hp: int = 800
var max_hp: int = 800
var mp: int = 600
var max_mp: int = 600
var atk: int = 120
var def: int = 45
var move_speed: float = 240.0
var agi_speed: float = 240.0
var spirit: int = 120
var recovery: int = 120
var crit_rate: float = 0.15
var dodge_rate: float = 0.10

# 玩家水晶屬性分佈 (純地/水/火/風 或 雙屬性，總和 10 點)
var player_crystal = {
	CombatMath.ElementType.WIND: 5,
	CombatMath.ElementType.EARTH: 5
}
var crystal_name: String = "風地水晶 (5:5)"

# 經濟與金幣
var gold: int = 2000

# 背包物品資料結構
var inventory: Array[Dictionary] = [
	{ "id": "potion_hp_small", "name": "生命之藥(200)", "type": "consumable", "count": 8, "desc": "瞬間恢復 200 點生命值", "price": 40, "color": Color(0.2, 0.9, 0.3) },
	{ "id": "potion_mp_small", "name": "魔力之藥(100)", "type": "consumable", "count": 5, "desc": "瞬間恢復 100 點魔力值", "price": 60, "color": Color(0.2, 0.5, 1.0) },
	{ "id": "seal_card_normal", "name": "普卡封印卡", "type": "seal_card", "tier": CombatMath.SealCardTier.NORMAL, "count": 10, "desc": "可封印普通野生怪物的卡片", "price": 100, "color": Color(0.8, 0.8, 0.8) },
	{ "id": "seal_card_silver", "name": "銀卡封印卡", "type": "seal_card", "tier": CombatMath.SealCardTier.SILVER, "count": 3, "desc": "可封印較稀有銀卡怪物的卡片，捕捉率更高", "price": 350, "color": Color(0.9, 0.9, 1.0) },
	{ "id": "crystal_wind_earth", "name": "風地水晶(5:5)", "type": "crystal", "count": 1, "desc": "裝備後獲得風5地5屬性", "price": 500, "color": Color(0.4, 0.9, 0.5) }
]

# 寵物隊伍系統 (最多攜帶 5 隻，可出戰 1 隻)
var pets: Array[Dictionary] = [
	{
		"id": "pet_goblin_01",
		"name": "哥布林",
		"title": "忠實守衛",
		"level": 1,
		"exp": 0,
		"max_exp": 60,
		"race": "人形系",
		"element": { CombatMath.ElementType.EARTH: 7, CombatMath.ElementType.WIND: 3 },
		"element_desc": "地7風3",
		"hp": 280,
		"max_hp": 280,
		"mp": 120,
		"max_mp": 120,
		"atk": 56,
		"def": 28,
		"agi": 32,
		"spirit": 95,
		"loyalty": 100,
		"grade_loss": 2,
		"active_skill": "連擊",
		"drawer_type": "humanoid",
		"color_main": Color(0.25, 0.75, 0.35),
		"color_sub": Color(0.5, 0.35, 0.15),
		"scale": 0.95,
		"num": "001"
	}
]
var active_pet_index: int = 0
var pet_command_mode: String = "FOLLOW_ATTACK"

var mp_regen_timer: float = 0.0

func _ready() -> void:
	recalculate_stats()

func _process(delta: float) -> void:
	mp_regen_timer += delta
	if mp_regen_timer >= 0.25:
		mp_regen_timer = 0.0
		if mp < max_mp:
			mp = min(max_mp, mp + 12)
			EventBus.player_mana_changed.emit(mp, max_mp)

func recalculate_stats() -> void:
	max_hp = 300 + (stat_vit * 15) + (stat_str * 5)
	max_mp = 200 + (stat_mag * 16) + (stat_vit * 4)
	atk = 40 + int(stat_str * 3.2) + int(stat_vit * 0.5)
	def = 25 + int(stat_tgh * 2.8) + int(stat_vit * 0.5)
	move_speed = 220.0 + (stat_agi * 2.0)
	agi_speed = move_speed
	spirit = 100 + int(stat_mag * 2.5)
	recovery = 100 + int(stat_vit * 2.0)
	crit_rate = clamp(0.10 + (stat_str * 0.003) + (stat_agi * 0.003), 0.10, 0.60)
	dodge_rate = clamp(0.08 + (stat_agi * 0.004), 0.08, 0.50)
	
	hp = clamp(hp, 1, max_hp)
	mp = clamp(mp, 0, max_mp)
	
	EventBus.player_stats_changed.emit()

func consume_mp(amount: int) -> bool:
	if mp >= amount:
		mp -= amount
		EventBus.player_mana_changed.emit(mp, max_mp)
		return true
	return false

func heal(amount: int) -> void:
	hp = min(max_hp, hp + amount)
	EventBus.player_health_changed.emit(hp, max_hp)

func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	EventBus.player_health_changed.emit(hp, max_hp)

func add_exp(amount: int) -> void:
	player_exp += amount
	EventBus.show_banner_notification.emit("獲得經驗值", "+%d EXP" % amount)
	while player_exp >= player_max_exp:
		player_exp -= player_max_exp
		level_up()
	EventBus.player_exp_changed.emit(player_exp, player_max_exp, player_level)

func level_up() -> void:
	player_level += 1
	player_max_exp = int(player_max_exp * 1.45)
	free_stat_points += 4
	free_skill_points += 1
	
	stat_vit += 2
	stat_str += 2
	stat_tgh += 2
	stat_agi += 2
	stat_mag += 2
	recalculate_stats()
	hp = max_hp
	mp = max_mp
	
	EventBus.player_health_changed.emit(hp, max_hp)
	EventBus.player_mana_changed.emit(mp, max_mp)
	EventBus.show_banner_notification.emit("等級提升！", "恭喜升至 Lv.%d！" % player_level)
	SoundManager.play_level_up()
	
	if player_level % 5 == 0:
		EventBus.buff_selection_requested.emit()

func add_gold(amount: int) -> void:
	gold += amount
	EventBus.gold_changed.emit(gold, amount)
	if amount > 0:
		SoundManager.play_gold()

func consume_item(item_id: String) -> bool:
	for i in range(inventory.size()):
		if inventory[i]["id"] == item_id and inventory[i]["count"] > 0:
			inventory[i]["count"] -= 1
			if inventory[i]["id"] == "potion_hp_small":
				heal(200)
				EventBus.damage_spawned.emit(player.global_position if player else Vector2.ZERO, "+200 HP", Color(0.2, 1.0, 0.4), false, false)
				SoundManager.play_heal()
			elif inventory[i]["id"] == "potion_mp_small":
				mp = min(max_mp, mp + 100)
				EventBus.player_mana_changed.emit(mp, max_mp)
				EventBus.damage_spawned.emit(player.global_position if player else Vector2.ZERO, "+100 MP", Color(0.2, 0.6, 1.0), false, false)
				SoundManager.play_magic()
			
			if inventory[i]["count"] <= 0:
				inventory.remove_at(i)
			EventBus.inventory_updated.emit()
			return true
	return false

func add_item(item_dict: Dictionary) -> void:
	for existing in inventory:
		if existing["id"] == item_dict["id"]:
			existing["count"] += item_dict.get("count", 1)
			EventBus.inventory_updated.emit()
			EventBus.item_obtained.emit(item_dict["name"], item_dict.get("count", 1), item_dict.get("color", Color.WHITE))
			return
	inventory.append(item_dict)
	EventBus.inventory_updated.emit()
	EventBus.item_obtained.emit(item_dict["name"], item_dict.get("count", 1), item_dict.get("color", Color.WHITE))

func add_pet(pet_data: Dictionary) -> void:
	pets.append(pet_data)
	EventBus.show_banner_notification.emit("獲得新寵物！", "【%s】已加入你的寵物隊伍！" % pet_data["name"])
	EventBus.pet_stats_changed.emit()

func get_active_pet() -> Dictionary:
	if active_pet_index >= 0 and active_pet_index < pets.size():
		return pets[active_pet_index]
	return {}
