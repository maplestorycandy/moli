extends Panel

const SkinManager = preload("res://scripts/core/SkinManager.gd")

@onready var skin_list_container: VBoxContainer = $ScrollContainer/SkinListContainer
@onready var close_btn: Button = $CloseBtn

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(func(): visible = false)
	_populate_skins()

func open_window() -> void:
	visible = true
	_populate_skins()

func toggle_window() -> void:
	visible = not visible
	if visible:
		open_window()

func _populate_skins() -> void:
	for c in skin_list_container.get_children():
		c.queue_free()
		
	var sm = get_node("/root/SkinManager")
	var skins = sm.get_all_skins()
	var cur_skin = sm.get_current_skin()
	
	for s in skins:
		var btn = Button.new()
		var is_cur = (s["id"] == cur_skin["id"])
		var prefix = "✨ [穿戴中] " if is_cur else "👤 "
		btn.text = "%s%s\n【%s】 %s" % [prefix, s["name"], s.get("title", ""), s.get("desc", "")]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 56)
		
		if is_cur:
			btn.modulate = Color(0.3, 1.0, 0.4)
		else:
			btn.modulate = Color(1.0, 1.0, 1.0)
			
		var skin_id = s["id"]
		btn.pressed.connect(func():
			sm.select_skin(skin_id)
			EventBus.show_banner_notification.emit("已裝備英雄造型", "【%s】" % s["name"])
			SoundManager.play_level_up()
			visible = false
		)
		skin_list_container.add_child(btn)
