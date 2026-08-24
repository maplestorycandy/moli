extends Node

# 經典魔力寶貝四大元素定義
enum ElementType {
	NONE = 0,
	EARTH = 1, # 地
	WATER = 2, # 水
	FIRE = 3,  # 火
	WIND = 4   # 風
}

const ELEMENT_NAMES = {
	ElementType.NONE: "無",
	ElementType.EARTH: "地",
	ElementType.WATER: "水",
	ElementType.FIRE: "火",
	ElementType.WIND: "風"
}

const ELEMENT_COLORS = {
	ElementType.NONE: Color(0.8, 0.8, 0.8),
	ElementType.EARTH: Color(0.8, 0.6, 0.2), # 琥珀金/地黃
	ElementType.WATER: Color(0.2, 0.6, 1.0), # 湛藍/水藍
	ElementType.FIRE: Color(1.0, 0.3, 0.2),  # 熾紅/火焰
	ElementType.WIND: Color(0.3, 0.9, 0.4)   # 翠綠/風綠
}

# 封印卡種類
enum SealCardTier {
	NORMAL = 1, # 普卡 (史萊姆、哥布林等普卡怪)
	SILVER = 2, # 銀卡 (黃蜂、水龍蜥、樹精等銀卡怪)
	GOLD = 3    # 金卡 (稀有/BOSS級/純白嚇人箱等金卡怪)
}

# 計算單一元素對剋倍率: 地剋水、水剋火、火剋風、風剋地 (純屬性全剋 1.3 倍，被剋 0.7 倍)
static func get_single_element_modifier(atk_elem: ElementType, def_elem: ElementType) -> float:
	if atk_elem == ElementType.NONE or def_elem == ElementType.NONE:
		return 1.0
	
	if atk_elem == ElementType.EARTH:
		if def_elem == ElementType.WATER: return 1.3
		if def_elem == ElementType.WIND: return 0.7
	elif atk_elem == ElementType.WATER:
		if def_elem == ElementType.FIRE: return 1.3
		if def_elem == ElementType.EARTH: return 0.7
	elif atk_elem == ElementType.FIRE:
		if def_elem == ElementType.WIND: return 1.3
		if def_elem == ElementType.WATER: return 0.7
	elif atk_elem == ElementType.WIND:
		if def_elem == ElementType.EARTH: return 1.3
		if def_elem == ElementType.FIRE: return 0.7
		
	return 1.0

# 複合屬性相剋計算 (各屬性 0~10 點)
# attacker_elem_distribution: Dictionary { ElementType: points } (例如: { EARTH: 5, WATER: 5 })
# defender_elem_distribution: Dictionary
static func calculate_element_advantage(atk_dist: Dictionary, def_dist: Dictionary) -> float:
	var total_atk_pts: float = 0.0
	var total_def_pts: float = 0.0
	for p in atk_dist.values(): total_atk_pts += float(p)
	for p in def_dist.values(): total_def_pts += float(p)
	
	if total_atk_pts <= 0.0 or total_def_pts <= 0.0:
		return 1.0
		
	var weighted_mod: float = 0.0
	for a_elem in atk_dist.keys():
		var a_ratio = float(atk_dist[a_elem]) / total_atk_pts
		for d_elem in def_dist.keys():
			var d_ratio = float(def_dist[d_elem]) / total_def_pts
			var single_mod = get_single_element_modifier(a_elem, d_elem)
			weighted_mod += a_ratio * d_ratio * single_mod
			
	return weighted_mod

# 物理傷害計算公式 (經典還原 + ARPG 動作微調)
static func calculate_physical_damage(attacker_atk: float, defender_def: float, skill_multiplier: float, elem_mod: float, crit_rate: float) -> Dictionary:
	var is_crit = randf() < crit_rate
	var crit_mult = 2.0 if is_crit else 1.0
	
	var base_dmg = max(1.0, (attacker_atk * skill_multiplier * 1.5) - (defender_def * 0.7))
	var variance = randf_range(0.92, 1.08)
	var final_damage = int(round(base_dmg * elem_mod * crit_mult * variance))
	final_damage = max(1, final_damage)
	
	return {
		"damage": final_damage,
		"is_crit": is_crit,
		"elem_mod": elem_mod,
		"is_effective": elem_mod > 1.1,
		"is_resisted": elem_mod < 0.9
	}

# 魔法傷害計算公式 (精神壓制與屬性相剋)
static func calculate_magic_damage(attacker_matk: float, attacker_spirit: float, defender_mdef: float, defender_spirit: float, spell_base_dmg: float, elem_mod: float) -> Dictionary:
	var spirit_ratio = clamp(attacker_spirit / max(1.0, defender_spirit), 0.5, 1.8)
	var base_dmg = (spell_base_dmg + attacker_matk * 1.2) * spirit_ratio - (defender_mdef * 0.5)
	base_dmg = max(5.0, base_dmg)
	var variance = randf_range(0.95, 1.05)
	var final_damage = int(round(base_dmg * elem_mod * variance))
	
	return {
		"damage": final_damage,
		"is_crit": false,
		"elem_mod": elem_mod,
		"is_effective": elem_mod > 1.1,
		"is_resisted": elem_mod < 0.9
	}

# 封印成功率計算 (經典殘血 + 卡片階級 + 等級差判定)
static func calculate_seal_success_rate(card_tier: SealCardTier, monster_tier: SealCardTier, player_lvl: int, monster_lvl: int, monster_hp_ratio: float) -> float:
	# 若卡片階級低於怪物階級 (例如用普卡封印銀卡怪)，成功率大幅懲罰
	var tier_penalty = 1.0
	if int(card_tier) < int(monster_tier):
		tier_penalty = 0.2
	elif int(card_tier) > int(monster_tier):
		tier_penalty = 1.4
		
	# 殘血加成: 血量越低成功率越高 (0% 血量得 1.0，100% 血量得 0.1)
	var hp_factor = (1.0 - monster_hp_ratio) * 0.8 + 0.1
	
	# 等級差距因素
	var lvl_diff = clamp((player_lvl - monster_lvl) * 0.03, -0.2, 0.25)
	
	# 卡片基礎係數
	var card_base = 0.4
	if card_tier == SealCardTier.SILVER: card_base = 0.6
	elif card_tier == SealCardTier.GOLD: card_base = 0.85
	
	var final_rate = (card_base * hp_factor + lvl_diff) * tier_penalty
	return clamp(final_rate, 0.05, 0.95)
