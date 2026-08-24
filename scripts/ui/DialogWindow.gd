extends Control

@onready var speaker_label: Label = $Panel/SpeakerLabel
@onready var content_label: Label = $Panel/ContentLabel
@onready var options_container: HBoxContainer = $Panel/OptionsContainer
@onready var panel: Panel = $Panel

var lines_to_show: Array = []
var current_line_idx: int = 0
var current_options: Array = []
var on_choice_callback: Callable
var is_active: bool = false

func _ready() -> void:
	visible = false
	EventBus.dialog_started.connect(_on_dialog_started)

func _on_dialog_started(speaker: String, lines: Array, options: Array, callback: Callable) -> void:
	speaker_label.text = speaker
	lines_to_show = lines
	current_options = options
	on_choice_callback = callback
	current_line_idx = 0
	is_active = true
	visible = true
	
	_show_current_line()

func _show_current_line() -> void:
	for c in options_container.get_children():
		c.queue_free()
		
	if current_line_idx < lines_to_show.size():
		content_label.text = lines_to_show[current_line_idx]
	
	# 如果是最後一句，生成選項按鈕
	if current_line_idx == lines_to_show.size() - 1:
		for i in range(current_options.size()):
			var opt_text = current_options[i]
			var btn = Button.new()
			btn.text = opt_text
			btn.custom_minimum_size = Vector2(100, 32)
			var idx_copy = i
			btn.pressed.connect(func():
				_on_option_selected(idx_copy)
			)
			options_container.add_child(btn)

func _on_option_selected(idx: int) -> void:
	visible = false
	is_active = false
	if on_choice_callback.is_valid():
		on_choice_callback.call(idx)
	EventBus.dialog_ended.emit()

func _input(event: InputEvent) -> void:
	if not is_active:
		return
		
	if event.is_action_just_pressed("attack") or event.is_action_just_pressed("interact"):
		if current_line_idx < lines_to_show.size() - 1:
			current_line_idx += 1
			_show_current_line()
