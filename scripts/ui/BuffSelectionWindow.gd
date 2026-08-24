extends Control

@onready var card_1: Panel = $CenterContainer/HBox/Card1
@onready var card_2: Panel = $CenterContainer/HBox/Card2
@onready var card_3: Panel = $CenterContainer/HBox/Card3

var current_options: Array[Dictionary] = []

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func open_selection() -> void:
	current_options = BuffManager.get_3_random_buffs()
	_setup_card(card_1, current_options[0], 0)
	_setup_card(card_2, current_options[1], 1)
	_setup_card(card_3, current_options[2], 2)
	
	visible = true
	get_tree().paused = true

func _setup_card(card_panel: Panel, buff_data: Dictionary, idx: int) -> void:
	var icon_lbl = card_panel.get_node("VBox/IconLabel") as Label
	var name_lbl = card_panel.get_node("VBox/NameLabel") as Label
	var tier_lbl = card_panel.get_node("VBox/TierLabel") as Label
	var desc_lbl = card_panel.get_node("VBox/DescLabel") as Label
	var select_btn = card_panel.get_node("VBox/SelectBtn") as Button
	
	icon_lbl.text = buff_data["icon"]
	name_lbl.text = buff_data["name"]
	tier_lbl.text = "【%s】" % buff_data["tier"]
	tier_lbl.modulate = buff_data.get("color", Color.WHITE)
	desc_lbl.text = buff_data["desc"]
	
	# 斷開舊連接並重新綁定
	if select_btn.pressed.is_connected(_on_select_pressed):
		select_btn.pressed.disconnect(_on_select_pressed)
	select_btn.pressed.connect(func(): _on_select_pressed(idx))

func _on_select_pressed(idx: int) -> void:
	if idx >= 0 and idx < current_options.size():
		var chosen = current_options[idx]
		BuffManager.add_buff(chosen["id"])
		visible = false
		get_tree().paused = false
