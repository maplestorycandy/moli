extends Control

@onready var points_label: Label = $Panel/PointsLabel
@onready var stat_vit_val: Label = $Panel/GridStats/VitVal
@onready var stat_str_val: Label = $Panel/GridStats/StrVal
@onready var stat_tgh_val: Label = $Panel/GridStats/TghVal
@onready var stat_agi_val: Label = $Panel/GridStats/AgiVal
@onready var stat_mag_val: Label = $Panel/GridStats/MagVal

@onready var btn_vit: Button = $Panel/GridStats/BtnVit
@onready var btn_str: Button = $Panel/GridStats/BtnStr
@onready var btn_tgh: Button = $Panel/GridStats/BtnTgh
@onready var btn_agi: Button = $Panel/GridStats/BtnAgi
@onready var btn_mag: Button = $Panel/GridStats/BtnMag

@onready var derived_label: Label = $Panel/DerivedLabel

func _ready() -> void:
	visible = false
	btn_vit.pressed.connect(func(): _add_stat("vit"))
	btn_str.pressed.connect(func(): _add_stat("str"))
	btn_tgh.pressed.connect(func(): _add_stat("tgh"))
	btn_agi.pressed.connect(func(): _add_stat("agi"))
	btn_mag.pressed.connect(func(): _add_stat("mag"))
	
	$Panel/CloseBtn.pressed.connect(func(): visible = false)
	EventBus.player_stats_changed.connect(refresh_data)

func toggle_window() -> void:
	visible = !visible
	if visible:
		refresh_data()

func refresh_data() -> void:
	points_label.text = "剩餘可用點數: %d" % Global.free_stat_points
	stat_vit_val.text = "%d" % Global.stat_vit
	stat_str_val.text = "%d" % Global.stat_str
	stat_tgh_val.text = "%d" % Global.stat_tgh
	stat_agi_val.text = "%d" % Global.stat_agi
	stat_mag_val.text = "%d" % Global.stat_mag
	
	var can_add = Global.free_stat_points > 0
	btn_vit.disabled = !can_add
	btn_str.disabled = !can_add
	btn_tgh.disabled = !can_add
	btn_agi.disabled = !can_add
	btn_mag.disabled = !can_add
	
	var derived_text = """【戰鬥能力數值】
生命值 (HP): %d / %d
魔力值 (MP): %d / %d
物理攻擊: %d
物理防禦: %d
精神 (魔攻/魔抗): %d
回復力: %d
移動/出手敏捷: %d
暴擊率: %.1f%%
閃避率: %.1f%%
裝備水晶: %s""" % [
		Global.hp, Global.max_hp,
		Global.mp, Global.max_mp,
		Global.atk,
		Global.def,
		Global.spirit,
		Global.recovery,
		int(Global.agi_speed),
		Global.crit_rate * 100.0,
		Global.dodge_rate * 100.0,
		Global.crystal_name
	]
	derived_label.text = derived_text

func _add_stat(type: String) -> void:
	if Global.free_stat_points <= 0:
		return
	Global.free_stat_points -= 1
	match type:
		"vit": Global.stat_vit += 1
		"str": Global.stat_str += 1
		"tgh": Global.stat_tgh += 1
		"agi": Global.stat_agi += 1
		"mag": Global.stat_mag += 1
	Global.recalculate_stats()
	SoundManager.play_gold()
	refresh_data()

func _input(event: InputEvent) -> void:
	if event.is_action_just_pressed("character_sheet"):
		toggle_window()
