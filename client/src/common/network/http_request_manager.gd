extends Node

func request(
	decorator_callable: Callable,
	request_complete_callable: Callable,
	url: String,
	) -> HTTPRequest:
	var http: HTTPRequest = HTTPRequest.new()
	decorator_callable.call(http)
	add_child(http)

	http.request_completed.connect(
		_on_request_completed.bind(http, request_complete_callable)
	)
	http.request(url)
	return http

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, 
	http: HTTPRequest, request_complete_callable: Callable) -> void:
	http.queue_free()

	request_complete_callable.callv([result, response_code, headers, body])
