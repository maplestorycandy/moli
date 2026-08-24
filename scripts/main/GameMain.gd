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
@onready var settings_win: Control = $CanvasLayer/SettingsWindow

const MagicSpell = preload("res://scripts/combat/MagicSpell.gd")
var damage_number_scene = preload("res://scenes/combat/DamageNumber.tscn")

var shake_intensity: float = 0.0
var shake_timer: float = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_O:
			settings_win.toggle_window()
		elif event.keycode == KEY_M:
			map_win.visible = not map_win.visible
			if map_win.visible and map_win.has_method("open_window"):
				map_win.open_window()
		elif event.keycode == KEY_K:
			skin_win.visible = not skin_win.visible
			if skin_win.visible and skin_win.has_method("open_window"):
				skin_win.open_window()
		elif event.keycode == KEY_I:
			inv_win.toggle_window()
		elif event.keycode == KEY_C:
			char_win.toggle_window()
		elif event.keycode == KEY_P:
			pet_win.toggle_window()

func _ready() -> void:
	EventBus.damage_spawned.connect(_on_damage_spawned)
	EventBus.screen_shake_requested.connect(_on_screen_shake)
	EventBus.combo_dual_attack_triggered.connect(_on_dual_combo)
	EventBus.buff_selection_requested.connect(func(): buff_win.open_selection())
	
	if wave_manager:
		wave_manager.wave_timer_updated.connect(_on_wave_timer_updated)
	
	# 連接 HUD 底部雙排快捷欄按鈕
	_connect_hud_buttons()
	
	EventBus.show_banner_notification.emit("歡迎來到法蘭王國！", "【魔力神技已解鎖】1~0 施放單體/強力魔法，Q/E/R/F 施放超強全螢幕魔法！")

func _connect_hud_buttons() -> void:
	if not hud:
		return
		
	# Row 1 (基礎與強力技能)
	var r1 = hud.get_node_or_null("BottomBar/VBox/Row1")
	if r1:
		if r1.has_node("BtnAttack"): r1.get_node("BtnAttack").pressed.connect(func(): if player: player._start_attack())
		if r1.has_node("BtnSkill1"): r1.get_node("BtnSkill1").pressed.connect(func(): if player: player._start_skill_combo())
		if r1.has_node("BtnSkill2"): r1.get_node("BtnSkill2").pressed.connect(func(): if player: player._start_skill_force_strike())
		if r1.has_node("BtnSkill3"): r1.get_node("BtnSkill3").pressed.connect(func(): if player: player._start_skill_kiblast())
		if r1.has_node("BtnSkill4"): r1.get_node("BtnSkill4").pressed.connect(func(): if player: player._cast_rapid_fire())
		if r1.has_node("BtnSkill5"): r1.get_node("BtnSkill5").pressed.connect(func(): if player: player._cast_magic(MagicSpell.SpellType.DRAIN, MagicSpell.SpellTier.SINGLE, 6.0, 20))
		if r1.has_node("BtnSkill6"): r1.get_node("BtnSkill6").pressed.connect(func(): if player: player._cast_magic(MagicSpell.SpellType.MIND_WAVE, MagicSpell.SpellTier.STRONG, 9.5, 30))
		if r1.has_node("BtnSkill7"): r1.get_node("BtnSkill7").pressed.connect(func(): if player: player._cast_magic(MagicSpell.SpellType.METEOR, MagicSpell.SpellTier.STRONG, 8.5, 25))
		if r1.has_node("BtnSkill8"): r1.get_node("BtnSkill8").pressed.connect(func(): if player: player._cast_magic(MagicSpell.SpellType.ICE, MagicSpell.SpellTier.STRONG, 8.5, 25))
		if r1.has_node("BtnSkill9"): r1.get_node("BtnSkill9").pressed.connect(func(): if player: player._cast_magic(MagicSpell.SpellType.FIRE, MagicSpell.SpellTier.STRONG, 8.5, 25))
		if r1.has_node("BtnSkill0"): r1.get_node("BtnSkill0").pressed.connect(func(): if player: player._cast_magic(MagicSpell.SpellType.WIND, MagicSpell.SpellTier.STRONG, 8.5, 25))

	# Row 2 (超強全螢幕魔法與系統功能)
	var r2 = hud.get_node_or_null("BottomBar/VBox/Row2")
	if r2:
		if r2.has_node("BtnMegaMeteor"): r2.get_node("BtnMegaMeteor").pressed.connect(func(): if player: player._cast_magic(MagicSpell.SpellType.METEOR, MagicSpell.SpellTier.MEGA, 20.0, 50))
		if r2.has_node("BtnMegaIce"): r2.get_node("BtnMegaIce").pressed.connect(func(): if player: player._cast_magic(MagicSpell.SpellType.ICE, MagicSpell.SpellTier.MEGA, 20.0, 50))
		if r2.has_node("BtnMegaFire"): r2.get_node("BtnMegaFire").pressed.connect(func(): if player: player._cast_magic(MagicSpell.SpellType.FIRE, MagicSpell.SpellTier.MEGA, 20.0, 50))
		if r2.has_node("BtnMegaWind"): r2.get_node("BtnMegaWind").pressed.connect(func(): if player: player._cast_magic(MagicSpell.SpellType.WIND, MagicSpell.SpellTier.MEGA, 20.0, 50))
		if r2.has_node("BtnSeal"): r2.get_node("BtnSeal").pressed.connect(func(): if player: player._use_seal_card())
		if r2.has_node("BtnDodge"): r2.get_node("BtnDodge").pressed.connect(func(): if player: player._start_dodge())
		if r2.has_node("BtnPetTactic"): r2.get_node("BtnPetTactic").pressed.connect(func(): if player: player._cycle_pet_command())
		if r2.has_node("BtnMap"): r2.get_node("BtnMap").pressed.connect(func():
			map_win.visible = not map_win.visible
			if map_win.visible and map_win.has_method("open_window"): map_win.open_window()
		)
		if r2.has_node("BtnSkin"): r2.get_node("BtnSkin").pressed.connect(func():
			skin_win.visible = not skin_win.visible
			if skin_win.visible and skin_win.has_method("open_window"): skin_win.open_window()
		)
		if r2.has_node("BtnBag"): r2.get_node("BtnBag").pressed.connect(func(): inv_win.toggle_window())
		if r2.has_node("BtnChar"): r2.get_node("BtnChar").pressed.connect(func(): char_win.toggle_window())
		if r2.has_node("BtnPet"): r2.get_node("BtnPet").pressed.connect(func(): pet_win.toggle_window())
		if r2.has_node("BtnSettings"): r2.get_node("BtnSettings").pressed.connect(func(): settings_win.toggle_window())

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
