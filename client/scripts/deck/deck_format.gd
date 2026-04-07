/*
Copyright © 2026 Bruno Braga bf.braga@campus.fct.unl.pt

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
class_name DeckFormat
extends RefCounted

enum Format {
	COMMANDER = 0,
	STANDARD = 1,
	MODERN = 2,
	PIONEER = 3,
	LEGACY = 4,
	VINTAGE = 5,
	PAUPER = 6,
	CASUAL = 7,
	CUSTOM = 8,
}

static func get_display_name(format: Format) -> String:
	match format:
		Format.COMMANDER: return "Commander"
		Format.STANDARD: return "Standard"
		Format.MODERN: return "Modern"
		Format.PIONEER: return "Pioneer"
		Format.LEGACY: return "Legacy"
		Format.VINTAGE: return "Vintage"
		Format.PAUPER: return "Pauper"
		Format.CASUAL: return "Casual"
		Format.CUSTOM: return "Custom"
		_: return "Unknown"

static func get_all_display_names() -> Array[String]:
	var names: Array[String] = []
	for format in Format.keys():
		names.append(get_display_name(Format[format]))
	return names

static func from_string(str: String) -> Format:
	var upper: String = str.to_upper().replace(" ", "_")
	for format in Format.keys():
		if format == upper:
			return Format[format]
	return Format.CUSTOM