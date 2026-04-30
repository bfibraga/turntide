package objects

type Player struct {
	Name   string
	MouseX float64
	MouseY float64

	//TODO: Add library
}

func NewPlayer(name string, mouse_x, mouse_y float64) *Player {
	return &Player{
		Name:   name,
		MouseX: mouse_x,
		MouseY: mouse_y,
	}
}
