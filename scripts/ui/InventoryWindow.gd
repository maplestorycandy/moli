extends Control

@onready var item_list: ItemList = $Panel/ItemList
@onready var item_name_label: Label = $Panel/Details/NameLabel
@onready var item_desc_label: Label = $Panel/Details/DescLabel
@onready var item_price_label: Label = $Panel/Details/PriceLabel
@onready var use_btn: Button = $Panel/Details/UseBtn

var selected_index: int = -1

func _ready() -> void:
	visible = false
	item_list.item_selected.connect(_on_item_selected)
	use_btn.pressed.connect(_on_use_pressed)
	$Panel/CloseBtn.pressed.connect(func(): visible = false)
	EventBus.inventory_updated.connect(refresh_list)

func toggle_window() -> void:
	visible = !visible
	if visible:
		refresh_list()

func refresh_list() -> void:
	item_list.clear()
	for item in Global.inventory:
		var txt = "%s  x%d" % [item["name"], item["count"]]
		item_list.add_item(txt)
		
	if selected_index >= 0 and selected_index < Global.inventory.size():
		_on_item_selected(selected_index)
	else:
		_clear_details()

func _on_item_selected(index: int) -> void:
	selected_index = index
	if index < 0 or index >= Global.inventory.size():
		_clear_details()
		return
		
	var item = Global.inventory[index]
	item_name_label.text = item["name"]
	item_desc_label.text = item.get("desc", "無說明")
	item_price_label.text = "單價: %d G" % item.get("price", 10)
	
	if item.get("type") == "consumable":
		use_btn.disabled = false
		use_btn.text = "使用道具"
	else:
		use_btn.disabled = true
		use_btn.text = "無法直接使用"

func _clear_details() -> void:
	item_name_label.text = "請選擇道具"
	item_desc_label.text = ""
	item_price_label.text = ""
	use_btn.disabled = true

func _on_use_pressed() -> void:
	if selected_index >= 0 and selected_index < Global.inventory.size():
		var item = Global.inventory[selected_index]
		Global.consume_item(item["id"])

func _input(event: InputEvent) -> void:
	if event.is_action_just_pressed("inventory"):
		toggle_window()
