@icon("res://addons/icodot/ui/office/icon-text-t-ui.svg")
class_name CardTooltip extends Panel

const ICON_MAP: Dictionary = {
	"{W/P}": "[img=14x14]res://assets/mana_symbols/white/white_phyrexian_mana_symbol.png[/img]",
	"{U/P}": "[img=14x14]res://assets/mana_symbols/blue/blue_phyrexian_mana_symbol.png[/img]",
	"{B/P}": "[img=14x14]res://assets/mana_symbols/black/black_phyrexian_mana_symbol.png[/img]",
	"{R/P}": "[img=14x14]res://assets/mana_symbols/red/red_phyrexian_mana_symbol.png[/img]",
	"{G/P}": "[img=14x14]res://assets/mana_symbols/green/green_phyrexian_mana_symbol.png[/img]",
	"{T}"  : "[img=14x14]res://assets/action_symbols/tap/tap.svg[/img]",
	"{W}"  : "[img=14x14]res://assets/mana_symbols/white/white_mana_symbol.png[/img]",
	"{U}"  : "[img=14x14]res://assets/mana_symbols/blue/blue_mana_symbol.png[/img]",
	"{B}"  : "[img=14x14]res://assets/mana_symbols/black/black_mana_symbol.png[/img]",
	"{R}"  : "[img=14x14]res://assets/mana_symbols/red/red_mana_symbol.png[/img]",
	"{G}"  : "[img=14x14]res://assets/mana_symbols/green/green_mana_symbol.png[/img]",
	"{C}"  : "[img=14x14]res://assets/mana_symbols/colorless/colorless_mana_symbol.svg[/img]",
}

class Keyword extends Reactive:
	#var title: ReactiveValue = ReactiveValue.String("Placeholder Keyword", self)
	#var description: ReactiveValue = ReactiveValue.String("Lorem ipsum dolor sit amet, consectetur adipiscing elit.", self)

	var title: String = "Placeholder Keyword"
	var description: String = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."

class Data extends Reactive:
	var keywords: ReactiveSet = ReactiveSet.new(Set.new(), self)

@export var initial_position: Vector2 = Vector2(Card.DEFAULT_SIZE.x + 10, 0)
@export var keywords_container: VBoxContainer

var data: Data = Data.new()

func _init(p_keywords: Array[Keyword] = []) -> void:
	data.keywords.value = Set.new(p_keywords)

func _ready() -> void:
	position = initial_position
	
	data.reactive_changed.connect(func(reactive: Data) -> void:
		clear_keywords()
		reactive.keywords.values().map(add_keyword)
	)
	
	data.manually_emit()

static func _parse_icons(text: String) -> String:
	var result: String = text
	
	for token: String in ICON_MAP:
		result = result.replace(token, ICON_MAP[token])
	return result

func add_description(description: String) -> void:
	var description_label: RichTextLabel = RichTextLabel.new()
	description_label.bbcode_enabled = true
	description_label.push_font_size(14)
	description_label.append_text(_parse_icons(description))
	description_label.pop_all()

func add_keyword(keyword: Keyword) -> void:
	var title_label: RichTextLabel = RichTextLabel.new()
	title_label.bbcode_enabled = true
	title_label.fit_content = true
	title_label.push_font_size(16)
	title_label.push_bold()
	title_label.append_text(keyword.title)
	title_label.pop_all()

	var description_label: RichTextLabel = RichTextLabel.new()
	description_label.bbcode_enabled = true
	description_label.fit_content = true
	description_label.push_font_size(14)
	description_label.push_italics()
	description_label.append_text(_parse_icons(keyword.description))
	description_label.pop_all()
	
	var keyword_container: VBoxContainer = VBoxContainer.new()
	keywords_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	keywords_container.grow_vertical = Control.GROW_DIRECTION_BOTH
	keyword_container.add_child(title_label)
	#keyword_container.add_spacer(true)
	keyword_container.add_child(description_label)
	
	keywords_container.add_child(keyword_container)

func clear_keywords() -> void:
	keywords_container.get_children().map(func(child: Node) -> void: child.queue_free())
