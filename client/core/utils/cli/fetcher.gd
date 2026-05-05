class_name FetcherCLI
extends CLIWrapper

var _args: PackedStringArray = []

func _init() -> void:
	super._init("res://resources/bin/fetcher")

func images() -> FetcherCLI:
	_args.clear()
	_args.append("images")
	return self

func download() -> FetcherCLI:
	_args.clear()
	_args.append("download")
	return self

# === Image command options ===

func decklist(path: String) -> FetcherCLI:
	_args.append_array(["--decklist", ProjectSettings.globalize_path(path)])
	return self

func format(type: String) -> FetcherCLI:
	_args.append_array(["--format", type])
	return self

func output_dir(path: String) -> FetcherCLI:
	_args.append_array(["--output", ProjectSettings.globalize_path(path)])
	return self

func card(card_metadata: CardMetadata) -> FetcherCLI:
	_args.append_array([card_metadata.to_turntide_format()])
	return self
	
func card_list(card_metadata_array: Array[CardMetadata]) -> FetcherCLI:
	return card_metadata_array.reduce(
		func(_self: FetcherCLI, card_metadata: CardMetadata) -> FetcherCLI: return _self.card(card_metadata),
		self
	)

# === Download command options ===
	
func db_path(path: String) -> FetcherCLI:
	_args.append_array(["--db-path", ProjectSettings.globalize_path(path)])
	return self

func run() -> void:
	self.execute_async(_args)
