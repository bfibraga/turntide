class_name FetcherCLI
extends CLIWrapper

var _args: PackedStringArray = []

func _init() -> void:
	super._init("res://assets/bin/fetcher")

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

func card(card_data: CardData) -> FetcherCLI:
	_args.append_array([card_data.to_turntide_format()])
	return self
	
func card_list(card_data_array: Array[CardData]) -> FetcherCLI:
	return card_data_array.reduce(
		func(thiz: FetcherCLI, card_data: CardData) -> FetcherCLI: return thiz.card(card_data),
		self
	)

# === Download command options ===
	
func db_path(path: String) -> FetcherCLI:
	_args.append_array(["--db-path", ProjectSettings.globalize_path(path)])
	return self

func run() -> void:
	self.execute_async(_args)
