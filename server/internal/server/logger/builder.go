package logger

import (
	"io"
	"log/slog"
	"os"
	"time"

	"github.com/lmittmann/tint"
	"github.com/mattn/go-colorable"
	"github.com/mattn/go-isatty"
)

type LogFormat int

const (
	FormatText LogFormat = iota // Tinted/Colorized text
	FormatJSON                  // Structured JSON
)

// Builder coordinates the configuration of the slog logger.
type Builder struct {
	writer      io.Writer
	level       slog.Level
	timeFormat  string
	format      LogFormat
	noColor     *bool
	replaceAttr func(groups []string, a slog.Attr) slog.Attr
}

// NewBuilder initializes a Builder with default text/tint settings.
func NewBuilder() *Builder {
	return &Builder{
		writer:     os.Stdout,
		level:      slog.LevelInfo,
		timeFormat: time.Kitchen,
		format:     FormatText, // defaults to your tinted terminal format
		replaceAttr: func(groups []string, attr slog.Attr) slog.Attr {
			if attr.Key == "error" {
				return tint.Attr(13, slog.String(attr.Key, attr.Value.String()))
			}
			return attr
		},
	}
}

// AsJSON switches the output format to JSON.
func (b *Builder) AsJSON() *Builder {
	b.format = FormatJSON
	return b
}

// AsText switches the output format to Tinted Text (Default).
func (b *Builder) AsText() *Builder {
	b.format = FormatText
	return b
}

// WithWriter overrides the output destination.
func (b *Builder) WithWriter(w io.Writer) *Builder {
	b.writer = w
	return b
}

// WithLevel sets the minimum logging level.
func (b *Builder) WithLevel(level slog.Level) *Builder {
	b.level = level
	return b
}

// WithTimeFormat sets the format string for timestamps (Text mode only).
func (b *Builder) WithTimeFormat(format string) *Builder {
	b.timeFormat = format
	return b
}

// WithColor explicitly enables or disables ANSI colors (Text mode only).
func (b *Builder) WithColor(enable bool) *Builder {
	noColor := !enable
	b.noColor = &noColor
	return b
}

// WithReplaceAttr overrides the default attribute replacement logic.
func (b *Builder) WithReplaceAttr(f func([]string, slog.Attr) slog.Attr) *Builder {
	b.replaceAttr = f
	return b
}

// Build constructs the slog.Logger handler, wraps it, and sets global default.
func (b *Builder) Build() *slog.Logger {
	var handler slog.Handler

	switch b.format {
	case FormatJSON:
		// Build standard JSON handler
		handler = slog.NewJSONHandler(b.writer, &slog.HandlerOptions{
			Level:       b.level,
			ReplaceAttr: b.replaceAttr,
			AddSource:   true,
		})

	case FormatText:
		// Evaluate color auto-detection for text mode
		var noColor bool
		if b.noColor != nil {
			noColor = *b.noColor
		} else {
			if file, ok := b.writer.(*os.File); ok {
				noColor = !isatty.IsTerminal(file.Fd())
			} else {
				noColor = true
			}
		}

		options := &tint.Options{
			Level:       b.level,
			TimeFormat:  b.timeFormat,
			NoColor:     noColor,
			ReplaceAttr: b.replaceAttr,
			AddSource:   true,
		}

		// Wrap with colorable for cross-platform/Windows terminal support
		handler = tint.NewHandler(colorable.NewColorable(b.writer.(*os.File)), options)
	}

	logger := slog.New(handler)

	return logger
}
