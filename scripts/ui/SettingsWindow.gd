extends Control

@onready var bgm_slider: HSlider = $Panel/VBox/BGMSection/HBox/BGMSlider
@onready var bgm_label: Label = $Panel/VBox/BGMSection/HBox/BGMLabel
@onready var bgm_mute_check: CheckBox = $Panel/VBox/BGMSection/BGMMuteCheck

@onready var sfx_slider: HSlider = $Panel/VBox/SFXSection/HBox/SFXSlider
@onready var sfx_label: Label = $Panel/VBox/SFXSection/HBox/SFXLabel
@onready var sfx_mute_check: CheckBox = $Panel/VBox/SFXSection/SFXMuteCheck

@onready var btn_next_bgm: Button = $Panel/VBox/ActionHBox/BtnNextBGM
@onready var btn_close: Button = $Panel/VBox/ActionHBox/BtnClose

func _ready() -> void:
	visible = false
	focus_mode = FOCUS_NONE
	
	bgm_slider.value = SoundManager.bgm_volume * 100.0
	bgm_label.text = "%d%%" % int(bgm_slider.value)
	bgm_mute_check.button_pressed = SoundManager.is_bgm_muted
	
	sfx_slider.value = SoundManager.sfx_volume * 100.0
	sfx_label.text = "%d%%" % int(sfx_slider.value)
	sfx_mute_check.button_pressed = SoundManager.is_sfx_muted
	
	bgm_slider.value_changed.connect(_on_bgm_slider_changed)
	bgm_mute_check.toggled.connect(_on_bgm_mute_toggled)
	
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	sfx_mute_check.toggled.connect(_on_sfx_mute_toggled)
	
	btn_next_bgm.pressed.connect(func():
		SoundManager.next_playlist_track()
	)
	
	btn_close.pressed.connect(func():
		visible = false
	)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_O:
			toggle_window()
		elif event.keycode == KEY_ESCAPE and visible:
			visible = false

func toggle_window() -> void:
	visible = not visible
	if visible:
		bgm_slider.value = SoundManager.bgm_volume * 100.0
		bgm_label.text = "%d%%" % int(bgm_slider.value)
		bgm_mute_check.button_pressed = SoundManager.is_bgm_muted
		
		sfx_slider.value = SoundManager.sfx_volume * 100.0
		sfx_label.text = "%d%%" % int(sfx_slider.value)
		sfx_mute_check.button_pressed = SoundManager.is_sfx_muted

func _on_bgm_slider_changed(val: float) -> void:
	bgm_label.text = "%d%%" % int(val)
	SoundManager.set_bgm_volume(val / 100.0)

func _on_bgm_mute_toggled(toggled: bool) -> void:
	SoundManager.set_bgm_muted(toggled)

func _on_sfx_slider_changed(val: float) -> void:
	sfx_label.text = "%d%%" % int(val)
	SoundManager.set_sfx_volume(val / 100.0)

func _on_sfx_mute_toggled(toggled: bool) -> void:
	SoundManager.set_sfx_muted(toggled)
