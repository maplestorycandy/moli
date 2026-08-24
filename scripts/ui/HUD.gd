extends Control

@onready var hp_bar: ProgressBar = $TopLeft/VBox/HPBar
@onready var mp_bar: ProgressBar = $TopLeft/VBox/MPBar
@onready var exp_bar: ProgressBar = $TopLeft/VBox/EXPBar
@onready var hp_label: Label = $TopLeft/VBox/HPBar/Label
@onready var mp_label: Label = $TopLeft/VBox/MPBar/Label
@onready var exp_label: Label = $TopLeft/VBox/EXPBar/Label

@onready var name_label: Label = $TopLeft/NameLabel
@onready var level_label: Label = $TopLeft/LevelLabel
@onready var title_label: Label = $TopLeft/TitleLabel
@onready var crystal_label: Label = $TopLeft/CrystalLabel

@onready var wave_label: Label = $TopCenter/WaveLabel
@onready var wave_status_label: Label = $TopCenter/StatusLabel
@onready var btn_rush: Button = $TopCenter/BtnRush
@onready var goddess_bar: ProgressBar = $TopCenter/GoddessBar
@onready var goddess_label: Label = $TopCenter/GoddessBar/Label

@onready var gold_label: Label = $GoldPanel/GoldLabel
@onready var pet_tactics_btn: Button = $BottomBar/HBox/BtnPetTactic
@onready var banner: Panel = $BannerNotification
@onready var banner_title: Label = $BannerNotification/VBox/Title
@onready var banner_sub: Label = $BannerNotification/VBox/Sub

var banner_tween: Tween

func _ready() -> void:
	EventBus.player_health_changed.connect(_on_hp_changed)
	EventBus.player_mana_changed.connect(_on_mp_changed)
	EventBus.player_exp_changed.connect(_on_exp_changed)
	EventBus.gold_changed.connect(_on_gold_changed)
	EventBus.player_stats_changed.connect(_update_all_info)
	EventBus.pet_command_changed.connect(_on_pet_command_changed)
	EventBus.show_banner_notification.connect(_show_banner)
	
	btn_rush.pressed.connect(func():
		var wm = get_tree().root.find_child("WaveManager", true, false)
		if wm and wm.has_method("trigger_immediate_next_wave"):
			wm.trigger_immediate_next_wave()
	)
	
	banner.modulate.a = 0.0
	_update_all_info()

func _process(_delta: float) -> void:
	var goddess = get_tree().get_first_node_in_group("goddess")
	if goddess and is_instance_valid(goddess):
		goddess_bar.max_value = goddess.max_hp
		goddess_bar.value = goddess.current_hp
		goddess_label.text = "愛謝拉女神 HP: %d / %d" % [goddess.current_hp, goddess.max_hp]

func update_wave_info(wave_num: int, is_active: bool, time_left: float, total_spawn: int, remaining: int) -> void:
	wave_label.text = "⚔️ 第 %d / 50 波" % wave_num
	if not is_active:
		wave_status_label.text = "下一波倒數: %ds" % int(ceil(time_left))
		btn_rush.visible = true
	else:
		wave_status_label.text = "剩餘魔物: %d / %d" % [remaining, total_spawn]
		btn_rush.visible = false

func _update_all_info() -> void:
	name_label.text = Global.player_name
	level_label.text = "Lv. %d" % Global.player_level
	title_label.text = "【%s】" % Global.player_title
	crystal_label.text = "💎 " + Global.crystal_name
	gold_label.text = "💰 %d G" % Global.gold
	
	_on_hp_changed(Global.hp, Global.max_hp)
	_on_mp_changed(Global.mp, Global.max_mp)
	_on_exp_changed(Global.player_exp, Global.player_max_exp, Global.player_level)

func _on_hp_changed(cur: int, max_val: int) -> void:
	hp_bar.max_value = max_val
	hp_bar.value = cur
	hp_label.text = "%d / %d" % [cur, max_val]

func _on_mp_changed(cur: int, max_val: int) -> void:
	mp_bar.max_value = max_val
	mp_bar.value = cur
	mp_label.text = "%d / %d" % [cur, max_val]

func _on_exp_changed(cur: int, max_val: int, lvl: int) -> void:
	exp_bar.max_value = max_val
	exp_bar.value = cur
	exp_label.text = "EXP: %d / %d" % [cur, max_val]
	level_label.text = "Lv. %d" % lvl

func _on_gold_changed(total: int, _diff: int) -> void:
	gold_label.text = "💰 %d G" % total

func _on_pet_command_changed(mode: String) -> void:
	match mode:
		"GUARD": pet_tactics_btn.text = "[T] 護衛"
		"STANDBY": pet_tactics_btn.text = "[T] 待命"
		_: pet_tactics_btn.text = "[T] 進攻"

func _show_banner(title: String, subtitle: String) -> void:
	banner_title.text = title
	banner_sub.text = subtitle
	
	if banner_tween and banner_tween.is_valid():
		banner_tween.kill()
		
	banner_tween = create_tween()
	banner_tween.tween_property(banner, "modulate:a", 1.0, 0.25)
	banner_tween.tween_interval(2.5)
	banner_tween.tween_property(banner, "modulate:a", 0.0, 0.5)
