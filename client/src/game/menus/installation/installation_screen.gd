class_name InstallationScreen extends Control

signal retry_pressed

@onready var progress_bar: ProgressBar = %ProgressBar
@onready var status_label: Label = %StatusLabel
@onready var retry_button: Button = %RetryButton
@onready var error_container: Control = %ErrorContainer

func _ready() -> void:
	retry_button.pressed.connect(_on_retry_pressed)

func set_progress(value: float) -> void:
	if value < 0.0:
		progress_bar.indeterminate = true
	else:
		progress_bar.indeterminate = false
		progress_bar.value = value * 100.0

func set_status(text: String) -> void:
	status_label.text = text

func show_error(message: String) -> void:
	status_label.text = message
	progress_bar.hide()
	retry_button.show()

func show_downloading() -> void:
	progress_bar.show()
	retry_button.hide()

func _on_retry_pressed() -> void:
	retry_pressed.emit()
