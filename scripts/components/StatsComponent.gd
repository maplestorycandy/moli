extends Node
class_name StatsComponent

@export var character_name: String = "未命名"
@export var level: int = 1
@export var max_hp: int = 100
@export var max_mp: int = 50
@export var atk: int = 20
@export var def: int = 10
@export var matk: int = 15
@export var mdef: int = 8
@export var spirit: int = 100
@export var recovery: int = 100
@export var move_speed: float = 120.0
@export var crit_rate: float = 0.05
@export var dodge_rate: float = 0.05

# 種族定義 (經典十大人形/野獸/不死/植物/昆蟲/飛行/特殊/金屬/龍/魔族)
@export var race: String = "野獸系"

# 元素屬性分佈 (例如: { EARTH: 10 })
@export var element_dist: Dictionary = {
	CombatMath.ElementType.EARTH: 10
}

# 卡片封印階級 (NORMAL, SILVER, GOLD)
@export var seal_tier: CombatMath.SealCardTier = CombatMath.SealCardTier.NORMAL

# 掉落經驗值與金幣
@export var exp_reward: int = 25
@export var gold_reward_min: int = 10
@export var gold_reward_max: int = 35

# 掉落物清單: [ { "id": "magic_stone", "name": "魔石", "chance": 0.5, "price": 80 } ]
@export var drop_table: Array[Dictionary] = []
