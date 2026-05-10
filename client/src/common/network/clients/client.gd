@abstract class_name ClientInterfacer extends Node 

@abstract func connect_to_url(url: String, tls_options: TLSOptions = null) -> Error
@abstract func send(packet: Variant) -> Error
@abstract func close(code: int = 1000, reason: String = "") -> void

@abstract func clear() -> void
@abstract func poll() -> void

func _process(_delta: float) -> void:
	poll()
