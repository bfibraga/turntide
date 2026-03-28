package shared

import "fmt"

func Todo(msg string) error {
	content := "todo"
	if len(msg) > 0 {
		content += ": " + msg
	}

	return fmt.Errorf(content)
}
