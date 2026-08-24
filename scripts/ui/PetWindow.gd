extends Control

@onready var pet_list: ItemList = $Panel/PetList
@onready var pet_name_label: Label = $Panel/Details/NameLabel
@onready var pet_grade_label: Label = $Panel/Details/GradeLabel
@onready var pet_stats_label: Label = $Panel/Details/StatsLabel
@onready var summon_btn: Button = $Panel/Details/SummonBtn

var selected_index: int = -1

func _ready() -> void:
	visible = false
	pet_list.item_selected.connect(_on_pet_selected)
	summon_btn.pressed.connect(_on_summon_pressed)
	$Panel/CloseBtn.pressed.connect(func(): visible = false)
	EventBus.pet_stats_changed.connect(refresh_list)

func toggle_window() -> void:
	visible = !visible
	if visible:
		refresh_list()

func refresh_list() -> void:
	pet_list.clear()
	for i in range(Global.pets.size()):
		var p = Global.pets[i]
		var tag = "【出戰中】" if i == Global.active_pet_index else ""
		pet_list.add_item("%s %s (Lv.%d)" % [p["name"], tag, p["level"]])
		
	if selected_index >= 0 and selected_index < Global.pets.size():
		_on_pet_selected(selected_index)
	elif Global.pets.size() > 0:
		_on_pet_selected(0)
	else:
		_clear_details()

func _on_pet_selected(index: int) -> void:
	selected_index = index
	if index < 0 or index >= Global.pets.size():
		_clear_details()
		return
		
	var p = Global.pets[index]
	pet_name_label.text = "%s  Lv.%d" % [p["name"], p["level"]]
	
	var grade_txt = "掉檔: %d 檔 (資質評價: %s)" % [
		p.get("grade_loss", 0),
		"★極品滿檔★" if p.get("grade_loss", 0) == 0 else ("極佳" if p.get("grade_loss", 0) <= 2 else "良好")
	]
	pet_grade_label.text = grade_txt
	
	var info = """種族: %s
屬性: %s
生命值: %d / %d
魔力值: %d / %d
攻擊力: %d
防禦力: %d
敏捷: %d
精神: %d
忠誠度: %d / 100
當前技能: %s""" % [
		p.get("race", "野獸系"),
		p.get("element_desc", "無"),
		p.get("hp", 100), p.get("max_hp", 100),
		p.get("mp", 50), p.get("max_mp", 50),
		p.get("atk", 20),
		p.get("def", 10),
		p.get("agi", 15),
		p.get("spirit", 90),
		p.get("loyalty", 100),
		p.get("active_skill", "普通攻擊")
	]
	pet_stats_label.text = info
	
	if index == Global.active_pet_index:
		summon_btn.text = "收回休息"
	else:
		summon_btn.text = "召喚出戰"

func _clear_details() -> void:
	pet_name_label.text = "無寵物"
	pet_grade_label.text = ""
	pet_stats_label.text = ""
	summon_btn.disabled = true

func _on_summon_pressed() -> void:
	if selected_index >= 0 and selected_index < Global.pets.size():
		if selected_index == Global.active_pet_index:
			Global.active_pet_index = -1
			EventBus.show_banner_notification.emit("寵物休息", "寵物已收回休息。")
		else:
			Global.active_pet_index = selected_index
			var p = Global.pets[selected_index]
			EventBus.show_banner_notification.emit("寵物出戰！", "【%s】已出戰並肩作戰！" % p["name"])
		refresh_list()
		EventBus.pet_stats_changed.emit()

func _input(event: InputEvent) -> void:
	if event.is_action_just_pressed("pet_panel"):
		toggle_window()
