extends Node2D

@onready var camera: Camera2D = $Camera2D
@onready var player = $Player
@onready var pet = $Pet
@onready var wave_manager: Node = $WaveManager
@onready var hud: Control = $CanvasLayer/HUD
@onready var char_win: Control = $CanvasLayer/CharacterWindow
@onready var inv_win: Control = $CanvasLayer/InventoryWindow
@onready var pet_win: Control = $CanvasLayer/PetWindow
@onready var buff_win: Control = $CanvasLayer/BuffSelectionWindow
@onready var map_win: Control = $CanvasLayer/MapSwitchWindow
@onready var skin_win: Control = $CanvasLayer/SkinSelectionWindow

var damage_number_scene = preload("res://scenes/combat/DamageNumber.tscn")

var shake_intensity: float = 0.0
var shake_timer: float = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			map_win.visible = not map_win.visible
			if map_win.visible and map_win.has_method("open_window"):
				map_win.open_window()
		elif event.keycode == KEY_K:
			skin_win.visible = not skin_win.visible
			if skin_win.visible and skin_win.has_method("open_window"):
				skin_win.open_window()

func _ready() -> void:
	EventBus.damage_spawned.connect(_on_damage_spawned)
	EventBus.screen_shake_requested.connect(_on_screen_shake)
	EventBus.combo_dual_attack_triggered.connect(_on_dual_combo)
	EventBus.buff_selection_requested.connect(func(): buff_win.open_selection())
	
	if wave_manager:
		wave_manager.wave_timer_updated.connect(_on_wave_timer_updated)
	
	# 連接 HUD 底部按鈕
	if hud and hud.has_node("BottomBar/HBox"):
		var hbox = hud.get_node("BottomBar/HBox")
		if hbox.has_node("BtnChar"): hbox.get_node("BtnChar").pressed.connect(func(): char_win.toggle_window())
		if hbox.has_node("BtnBag"): hbox.get_node("BtnBag").pressed.connect(func(): inv_win.toggle_window())
		if hbox.has_node("BtnPet"): hbox.get_node("BtnPet").pressed.connect(func(): pet_win.toggle_window())
		if hbox.has_node("BtnPetTactic"): hbox.get_node("BtnPetTactic").pressed.connect(func(): if player and player.has_method("_cycle_pet_command"): player._cycle_pet_command())
		if hbox.has_node("BtnMap"): hbox.get_node("BtnMap").pressed.connect(func():
			map_win.visible = not map_win.visible
			if map_win.visible and map_win.has_method("open_window"):
				map_win.open_window()
		)
		if hbox.has_node("BtnSkin"): hbox.get_node("BtnSkin").pressed.connect(func():
			skin_win.visible = not skin_win.visible
			if skin_win.visible and skin_win.has_method("open_window"):
				skin_win.open_window()
		)
	
	EventBus.show_banner_notification.emit("歡迎來到法蘭王國！", "【女神防守戰】已啟動！擊退 50 波入侵魔物！")

func _process(delta: float) -> void:
	if is_instance_valid(player):
		camera.global_position = camera.global_position.lerp(player.global_position, 8.0 * delta)
		_track_player_location(player.global_position)
		
	if shake_timer > 0.0:
		shake_timer -= delta
		var offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
		camera.offset = offset
	else:
		camera.offset = Vector2.ZERO

func _on_wave_timer_updated(time_left: float, total_spawn: int, remaining: int) -> void:
	if hud and is_instance_valid(hud):
		var w_num = wave_manager.current_wave if wave_manager else 1
		var is_active = wave_manager.is_wave_active if wave_manager else false
		hud.update_wave_info(w_num, is_active, time_left, total_spawn, remaining)

func _track_player_location(pos: Vector2) -> void:
	var old_loc = Global.current_map_name
	var wm = get_node_or_null("WorldMap")
	if wm and wm.has_method("get_region_at_position"):
		Global.current_map_name = wm.get_region_at_position(pos)
	else:
		Global.current_map_name = "法蘭城 王都"
		
	if old_loc != Global.current_map_name:
		EventBus.player_stats_changed.emit()
		EventBus.show_banner_notification.emit("進入區域", "【%s】" % Global.current_map_name)

func _on_damage_spawned(pos: Vector2, text: String, color: Color, is_crit: bool, is_effective: bool) -> void:
	var dmg_node = damage_number_scene.instantiate() as DamageNumber
	dmg_node.global_position = pos
	add_child(dmg_node)
	dmg_node.setup(text, color, is_crit, is_effective)

func _on_screen_shake(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_timer = duration

func _on_dual_combo(pos: Vector2) -> void:
	EventBus.damage_spawned.emit(pos + Vector2(0, -40), "✨【合擊!!】✨", Color(1.0, 0.85, 0.1), true, true)
	EventBus.screen_shake_requested.emit(10.0, 0.25)
