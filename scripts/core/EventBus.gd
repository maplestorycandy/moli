extends Node

# 戰鬥與飄字訊號
signal damage_spawned(pos: Vector2, text: String, color: Color, is_crit: bool, is_effective: bool)
signal screen_shake_requested(intensity: float, duration: float)
signal character_attack_triggered(attacker: Node, target_pos: Vector2, skill_name: String)

# 玩家相關訊號
signal player_stats_changed()
signal player_health_changed(current: int, max_hp: int)
signal player_mana_changed(current: int, max_mp: int)
signal player_exp_changed(current: int, max_exp: int, level: int)
signal player_died()

# 寵物與封印訊號
signal pet_summoned(pet_data: Dictionary)
signal pet_recalled()
signal pet_stats_changed()
signal pet_health_changed(current: int, max_hp: int)
signal pet_command_changed(command_name: String)
signal seal_attempt_result(success: bool, monster_name: String, card_name: String)
signal combo_dual_attack_triggered(pos: Vector2)

# 物品與經濟訊號
signal gold_changed(total_gold: int, diff: int)
signal inventory_updated()
signal item_obtained(item_name: String, count: int, icon_color: Color)

# UI 與地圖劇情訊號
signal dialog_started(speaker_name: String, text_lines: Array, options: Array, callback: Callable)
signal dialog_ended()
signal map_transition_requested(target_map: String, spawn_point: String)
signal show_banner_notification(title: String, subtitle: String)
signal buff_selection_requested()
