class_name CLIWrapper
extends RefCounted

signal task_finished(output: Array[String], exit_code: int)

var _thread: Thread = null

@export var executable_path: String

func _init(path: String) -> void:
	executable_path = ProjectSettings.globalize_path(path)
	
	if !FileAccess.file_exists(executable_path):
		push_error("Executable command not found!")

func execute_async(arguments: PackedStringArray) -> void:
	_thread = Thread.new()
	_thread.start(_run_command.bind(arguments))

func _run_command(arguments: PackedStringArray) -> void:
	var output: PackedStringArray = []
	var exit_code: int = OS.execute(executable_path, arguments, output, true)
	
	call_deferred("_on_command_completed", output, exit_code)

func _on_command_completed(output: PackedStringArray, exit_code: int) -> void:
	task_finished.emit(output, exit_code)
	if _thread:
		_thread.wait_to_finish()
		_thread = null
