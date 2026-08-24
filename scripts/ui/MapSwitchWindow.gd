extends Panel

const MapManager = preload("res://scripts/world/MapManager.gd")

@onready var map_list_container: VBoxContainer = $ScrollContainer/MapListContainer
@onready var close_btn: Button = $CloseBtn

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(func(): visible = false)
	_populate_maps()

func open_window() -> void:
	visible = true
	_populate_maps()

func _populate_maps() -> void:
	for c in map_list_container.get_children():
		c.queue_free()
		
	var maps = get_node("/root/MapManager").get_all_maps()
	var cur_map = get_node("/root/MapManager").get_current_map()
	
	for m in maps:
		var btn = Button.new()
		var is_cur = (m["id"] == cur_map["id"])
		var prefix = "📍 [目前] " if is_cur else "🚀 "
		btn.text = "%s%s (Lv. %d ~ %d)\n%s" % [prefix, m["name"], m["level_min"], m["level_max"], m["desc"]]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 56)
		
		if is_cur:
			btn.modulate = Color(0.3, 1.0, 0.4)
		else:
			btn.modulate = Color(1.0, 1.0, 1.0)
			
		var map_id = m["id"]
		btn.pressed.connect(func():
			get_node("/root/MapManager").switch_to_map(map_id)
			EventBus.show_banner_notification.emit("已傳送至【%s】" % m["name"], "地圖等級: Lv. %d ~ %d | 4 方防禦要塞啟動！" % [m["level_min"], m["level_max"]])
			visible = false
		)
		map_list_container.add_child(btn)
