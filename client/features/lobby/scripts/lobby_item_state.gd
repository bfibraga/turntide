class_name LobbyItemState extends Reactive

var lobby_name : ReactiveValue = ReactiveValue.String("", self)
var format_name : ReactiveValue = ReactiveValue.String("", self)
var is_public : ReactiveValue = ReactiveValue.Boolean(false, self)
var capacity : ReactiveValue = ReactiveValue.Int(0, self)
