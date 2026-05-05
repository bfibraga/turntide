extends Node

## Simple base64 obfuscation for storing credentials locally
## This is NOT encryption - only basic obfuscation to avoid plaintext storage

func encode_credentials(username: String, password: String) -> Dictionary:
	"""Encode credentials as base64 strings"""
	var encoded_username = Marshalls.utf8_to_base64(username)
	var encoded_password = Marshalls.utf8_to_base64(password)
	return {
		"username": encoded_username,
		"password": encoded_password
	}

func decode_credentials(encoded: Dictionary) -> Dictionary:
	"""Decode base64-encoded credentials"""
	var username = ""
	var password = ""
	
	if encoded.has("username"):
		username = Marshalls.base64_to_utf8(encoded["username"])
	if encoded.has("password"):
		password = Marshalls.base64_to_utf8(encoded["password"])
	
	return {
		"username": username,
		"password": password
	}

func save_credentials(username: String, password: String, path: String) -> bool:
	"""Save encoded credentials to a local file"""
	var encoded = encode_credentials(username, password)
	var config = ConfigFile.new()
	
	config.set_value("credentials", "username", encoded["username"])
	config.set_value("credentials", "password", encoded["password"])
	
	var err = config.save(path)
	return err == OK

func load_credentials(path: String) -> Dictionary:
	"""Load and decode credentials from a local file"""
	var config = ConfigFile.new()
	var err = config.load(path)
	
	if err != OK:
		return {"username": "", "password": ""}
	
	var encoded = {
		"username": config.get_value("credentials", "username", ""),
		"password": config.get_value("credentials", "password", "")
	}
	
	return decode_credentials(encoded)

func clear_credentials(path: String) -> bool:
	"""Clear saved credentials"""
	if ResourceLoader.exists(path):
		var dir = DirAccess.open(path.get_base_dir())
		if dir:
			return dir.remove(path) == OK
	return true
