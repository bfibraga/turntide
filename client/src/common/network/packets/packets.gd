#
# BSD 3-Clause License
#
# Copyright (c) 2018 - 2026, Oleg Malyavkin
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# DEBUG_TAB redefine this "  " if you need, example: const DEBUG_TAB = "\t"

const PROTO_VERSION = 3

const DEBUG_TAB : String = "  "

enum PB_ERR {
	NO_ERRORS = 0,
	VARINT_NOT_FOUND = -1,
	REPEATED_COUNT_NOT_FOUND = -2,
	REPEATED_COUNT_MISMATCH = -3,
	LENGTHDEL_SIZE_NOT_FOUND = -4,
	LENGTHDEL_SIZE_MISMATCH = -5,
	PACKAGE_SIZE_MISMATCH = -6,
	UNDEFINED_STATE = -7,
	PARSE_INCOMPLETE = -8,
	REQUIRED_FIELDS = -9
}

enum PB_DATA_TYPE {
	INT32 = 0,
	SINT32 = 1,
	UINT32 = 2,
	INT64 = 3,
	SINT64 = 4,
	UINT64 = 5,
	BOOL = 6,
	ENUM = 7,
	FIXED32 = 8,
	SFIXED32 = 9,
	FLOAT = 10,
	FIXED64 = 11,
	SFIXED64 = 12,
	DOUBLE = 13,
	STRING = 14,
	BYTES = 15,
	MESSAGE = 16,
	MAP = 17
}

const DEFAULT_VALUES_2 = {
	PB_DATA_TYPE.INT32: null,
	PB_DATA_TYPE.SINT32: null,
	PB_DATA_TYPE.UINT32: null,
	PB_DATA_TYPE.INT64: null,
	PB_DATA_TYPE.SINT64: null,
	PB_DATA_TYPE.UINT64: null,
	PB_DATA_TYPE.BOOL: null,
	PB_DATA_TYPE.ENUM: null,
	PB_DATA_TYPE.FIXED32: null,
	PB_DATA_TYPE.SFIXED32: null,
	PB_DATA_TYPE.FLOAT: null,
	PB_DATA_TYPE.FIXED64: null,
	PB_DATA_TYPE.SFIXED64: null,
	PB_DATA_TYPE.DOUBLE: null,
	PB_DATA_TYPE.STRING: null,
	PB_DATA_TYPE.BYTES: null,
	PB_DATA_TYPE.MESSAGE: null,
	PB_DATA_TYPE.MAP: null
}

const DEFAULT_VALUES_3 = {
	PB_DATA_TYPE.INT32: 0,
	PB_DATA_TYPE.SINT32: 0,
	PB_DATA_TYPE.UINT32: 0,
	PB_DATA_TYPE.INT64: 0,
	PB_DATA_TYPE.SINT64: 0,
	PB_DATA_TYPE.UINT64: 0,
	PB_DATA_TYPE.BOOL: false,
	PB_DATA_TYPE.ENUM: 0,
	PB_DATA_TYPE.FIXED32: 0,
	PB_DATA_TYPE.SFIXED32: 0,
	PB_DATA_TYPE.FLOAT: 0.0,
	PB_DATA_TYPE.FIXED64: 0,
	PB_DATA_TYPE.SFIXED64: 0,
	PB_DATA_TYPE.DOUBLE: 0.0,
	PB_DATA_TYPE.STRING: "",
	PB_DATA_TYPE.BYTES: [],
	PB_DATA_TYPE.MESSAGE: null,
	PB_DATA_TYPE.MAP: []
}

enum PB_TYPE {
	VARINT = 0,
	FIX64 = 1,
	LENGTHDEL = 2,
	STARTGROUP = 3,
	ENDGROUP = 4,
	FIX32 = 5,
	UNDEFINED = 8
}

enum PB_RULE {
	OPTIONAL = 0,
	REQUIRED = 1,
	REPEATED = 2,
	RESERVED = 3
}

enum PB_SERVICE_STATE {
	FILLED = 0,
	UNFILLED = 1
}

class PBField:
	func _init(a_name : String, a_type : int, a_rule : int, a_tag : int, packed : bool, a_value = null):
		name = a_name
		type = a_type
		rule = a_rule
		tag = a_tag
		option_packed = packed
		value = a_value
		
	var name : String
	var type : int
	var rule : int
	var tag : int
	var option_packed : bool
	var value
	var is_map_field : bool = false
	var option_default : bool = false

class PBTypeTag:
	var ok : bool = false
	var type : int
	var tag : int
	var offset : int

class PBServiceField:
	var field : PBField
	var func_ref = null
	var state : int = PB_SERVICE_STATE.UNFILLED

class PBPacker:
	static func convert_signed(n : int) -> int:
		if n < -2147483648:
			return (n << 1) ^ (n >> 63)
		else:
			return (n << 1) ^ (n >> 31)

	static func deconvert_signed(n : int) -> int:
		if n & 0x01:
			return ~(n >> 1)
		else:
			return (n >> 1)

	static func pack_varint(value) -> PackedByteArray:
		var varint : PackedByteArray = PackedByteArray()
		if typeof(value) == TYPE_BOOL:
			if value:
				value = 1
			else:
				value = 0
		for _i in range(9):
			var b = value & 0x7F
			value >>= 7
			if value:
				varint.append(b | 0x80)
			else:
				varint.append(b)
				break
		if varint.size() == 9 && (varint[8] & 0x80 != 0):
			varint.append(0x01)
		return varint

	static func pack_bytes(value, count : int, data_type : int) -> PackedByteArray:
		var bytes : PackedByteArray = PackedByteArray()
		if data_type == PB_DATA_TYPE.FLOAT:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			spb.put_float(value)
			bytes = spb.get_data_array()
		elif data_type == PB_DATA_TYPE.DOUBLE:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			spb.put_double(value)
			bytes = spb.get_data_array()
		else:
			for _i in range(count):
				bytes.append(value & 0xFF)
				value >>= 8
		return bytes

	static func unpack_bytes(bytes : PackedByteArray, index : int, count : int, data_type : int):
		if data_type == PB_DATA_TYPE.FLOAT:
			return bytes.decode_float(index)
		elif data_type == PB_DATA_TYPE.DOUBLE:
			return bytes.decode_double(index)
		elif data_type == PB_DATA_TYPE.FIXED32:
			return bytes.decode_u32(index)
		elif data_type == PB_DATA_TYPE.SFIXED32:
			return bytes.decode_s32(index)
		elif data_type == PB_DATA_TYPE.FIXED64:
			return bytes.decode_u64(index)
		elif data_type == PB_DATA_TYPE.SFIXED64:
			return bytes.decode_s64(index)
		else:
			var value : int = 0
			for i in range(count):
				value |= bytes[index + i] << (8 * i)
			return value

	static func unpack_varint(varint_bytes) -> int:
		var value : int = 0
		var i: int = varint_bytes.size() - 1
		while i > -1:
			value = (value << 7) | (varint_bytes[i] & 0x7F)
			i -= 1
		return value

	static func pack_type_tag(type : int, tag : int) -> PackedByteArray:
		return pack_varint((tag << 3) | type)

	static func isolate_varint(bytes : PackedByteArray, index : int) -> PackedByteArray:
		var i: int = index
		while i <= index + 10 && i < bytes.size(): # Protobuf varint max size is 10 bytes
			if !(bytes[i] & 0x80):
				return bytes.slice(index, i + 1)
			i += 1
		return [] # Unreachable

	static func unpack_type_tag(bytes : PackedByteArray, index : int) -> PBTypeTag:
		var varint_bytes : PackedByteArray = isolate_varint(bytes, index)
		var result : PBTypeTag = PBTypeTag.new()
		if varint_bytes.size() != 0:
			result.ok = true
			result.offset = varint_bytes.size()
			var unpacked : int = unpack_varint(varint_bytes)
			result.type = unpacked & 0x07
			result.tag = unpacked >> 3
		return result

	static func pack_length_delimeted(type : int, tag : int, bytes : PackedByteArray) -> PackedByteArray:
		var result : PackedByteArray = pack_type_tag(type, tag)
		result.append_array(pack_varint(bytes.size()))
		result.append_array(bytes)
		return result

	static func pb_type_from_data_type(data_type : int) -> int:
		if data_type == PB_DATA_TYPE.INT32 || data_type == PB_DATA_TYPE.SINT32 || data_type == PB_DATA_TYPE.UINT32 || data_type == PB_DATA_TYPE.INT64 || data_type == PB_DATA_TYPE.SINT64 || data_type == PB_DATA_TYPE.UINT64 || data_type == PB_DATA_TYPE.BOOL || data_type == PB_DATA_TYPE.ENUM:
			return PB_TYPE.VARINT
		elif data_type == PB_DATA_TYPE.FIXED32 || data_type == PB_DATA_TYPE.SFIXED32 || data_type == PB_DATA_TYPE.FLOAT:
			return PB_TYPE.FIX32
		elif data_type == PB_DATA_TYPE.FIXED64 || data_type == PB_DATA_TYPE.SFIXED64 || data_type == PB_DATA_TYPE.DOUBLE:
			return PB_TYPE.FIX64
		elif data_type == PB_DATA_TYPE.STRING || data_type == PB_DATA_TYPE.BYTES || data_type == PB_DATA_TYPE.MESSAGE || data_type == PB_DATA_TYPE.MAP:
			return PB_TYPE.LENGTHDEL
		else:
			return PB_TYPE.UNDEFINED

	static func pack_field(field : PBField) -> PackedByteArray:
		var type : int = pb_type_from_data_type(field.type)
		var type_copy : int = type
		if field.rule == PB_RULE.REPEATED && field.option_packed:
			type = PB_TYPE.LENGTHDEL
		var head : PackedByteArray = pack_type_tag(type, field.tag)
		var data : PackedByteArray = PackedByteArray()
		if type == PB_TYPE.VARINT:
			var value
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						value = convert_signed(v)
					else:
						value = v
					data.append_array(pack_varint(value))
				return data
			else:
				if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
					value = convert_signed(field.value)
				else:
					value = field.value
				data = pack_varint(value)
		elif type == PB_TYPE.FIX32:
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					data.append_array(pack_bytes(v, 4, field.type))
				return data
			else:
				data.append_array(pack_bytes(field.value, 4, field.type))
		elif type == PB_TYPE.FIX64:
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					data.append_array(pack_bytes(v, 8, field.type))
				return data
			else:
				data.append_array(pack_bytes(field.value, 8, field.type))
		elif type == PB_TYPE.LENGTHDEL:
			if field.rule == PB_RULE.REPEATED:
				if type_copy == PB_TYPE.VARINT:
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						var signed_value : int
						for v in field.value:
							signed_value = convert_signed(v)
							data.append_array(pack_varint(signed_value))
					else:
						for v in field.value:
							data.append_array(pack_varint(v))
					return pack_length_delimeted(type, field.tag, data)
				elif type_copy == PB_TYPE.FIX32:
					for v in field.value:
						data.append_array(pack_bytes(v, 4, field.type))
					return pack_length_delimeted(type, field.tag, data)
				elif type_copy == PB_TYPE.FIX64:
					for v in field.value:
						data.append_array(pack_bytes(v, 8, field.type))
					return pack_length_delimeted(type, field.tag, data)
				elif field.type == PB_DATA_TYPE.STRING:
					for v in field.value:
						var obj = v.to_utf8_buffer()
						data.append_array(pack_length_delimeted(type, field.tag, obj))
					return data
				elif field.type == PB_DATA_TYPE.BYTES:
					for v in field.value:
						data.append_array(pack_length_delimeted(type, field.tag, v))
					return data
				elif typeof(field.value[0]) == TYPE_OBJECT:
					for v in field.value:
						var obj : PackedByteArray = v.to_bytes()
						data.append_array(pack_length_delimeted(type, field.tag, obj))
					return data
			else:
				if field.type == PB_DATA_TYPE.STRING:
					var str_bytes : PackedByteArray = field.value.to_utf8_buffer()
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && str_bytes.size() > 0):
						data.append_array(str_bytes)
						return pack_length_delimeted(type, field.tag, data)
				if field.type == PB_DATA_TYPE.BYTES:
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && field.value.size() > 0):
						data.append_array(field.value)
						return pack_length_delimeted(type, field.tag, data)
				elif typeof(field.value) == TYPE_OBJECT:
					var obj : PackedByteArray = field.value.to_bytes()
					if obj.size() > 0:
						data.append_array(obj)
					return pack_length_delimeted(type, field.tag, data)
				else:
					pass
		if data.size() > 0:
			head.append_array(data)
			return head
		else:
			return data

	static func skip_unknown_field(bytes : PackedByteArray, offset : int, type : int) -> int:
		if type == PB_TYPE.VARINT:
			return offset + isolate_varint(bytes, offset).size()
		if type == PB_TYPE.FIX64:
			return offset + 8
		if type == PB_TYPE.LENGTHDEL:
			var length_bytes : PackedByteArray = isolate_varint(bytes, offset)
			var length : int = unpack_varint(length_bytes)
			return offset + length_bytes.size() + length
		if type == PB_TYPE.FIX32:
			return offset + 4
		return PB_ERR.UNDEFINED_STATE

	static func unpack_field(bytes : PackedByteArray, offset : int, field : PBField, type : int, message_func_ref) -> int:
		if field.rule == PB_RULE.REPEATED && type != PB_TYPE.LENGTHDEL && field.option_packed:
			var count = isolate_varint(bytes, offset)
			if count.size() > 0:
				offset += count.size()
				count = unpack_varint(count)
				if type == PB_TYPE.VARINT:
					var val
					var counter = offset + count
					while offset < counter:
						val = isolate_varint(bytes, offset)
						if val.size() > 0:
							offset += val.size()
							val = unpack_varint(val)
							if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
								val = deconvert_signed(val)
							elif field.type == PB_DATA_TYPE.BOOL:
								if val:
									val = true
								else:
									val = false
							field.value.append(val)
						else:
							return PB_ERR.REPEATED_COUNT_MISMATCH
					return offset
				elif type == PB_TYPE.FIX32 || type == PB_TYPE.FIX64:
					var type_size
					if type == PB_TYPE.FIX32:
						type_size = 4
					else:
						type_size = 8
					var val
					var counter = offset + count
					while offset < counter:
						if (offset + type_size) > bytes.size():
							return PB_ERR.REPEATED_COUNT_MISMATCH
						val = unpack_bytes(bytes, offset, type_size, field.type)
						offset += type_size
						field.value.append(val)
					return offset
			else:
				return PB_ERR.REPEATED_COUNT_NOT_FOUND
		else:
			if type == PB_TYPE.VARINT:
				var val = isolate_varint(bytes, offset)
				if val.size() > 0:
					offset += val.size()
					val = unpack_varint(val)
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						val = deconvert_signed(val)
					elif field.type == PB_DATA_TYPE.BOOL:
						if val:
							val = true
						else:
							val = false
					if field.rule == PB_RULE.REPEATED:
						field.value.append(val)
					else:
						field.value = val
				else:
					return PB_ERR.VARINT_NOT_FOUND
				return offset
			elif type == PB_TYPE.FIX32 || type == PB_TYPE.FIX64:
				var type_size
				if type == PB_TYPE.FIX32:
					type_size = 4
				else:
					type_size = 8
				var val
				if (offset + type_size) > bytes.size():
					return PB_ERR.REPEATED_COUNT_MISMATCH
				val = unpack_bytes(bytes, offset, type_size, field.type)
				offset += type_size
				if field.rule == PB_RULE.REPEATED:
					field.value.append(val)
				else:
					field.value = val
				return offset
			elif type == PB_TYPE.LENGTHDEL:
				var inner_size = isolate_varint(bytes, offset)
				if inner_size.size() > 0:
					offset += inner_size.size()
					inner_size = unpack_varint(inner_size)
					if inner_size >= 0:
						if inner_size + offset > bytes.size():
							return PB_ERR.LENGTHDEL_SIZE_MISMATCH
						if message_func_ref != null:
							var message = message_func_ref.call()
							if inner_size > 0:
								var sub_offset = message.from_bytes(bytes, offset, inner_size + offset)
								if sub_offset > 0:
									if sub_offset - offset >= inner_size:
										offset = sub_offset
										return offset
									else:
										return PB_ERR.LENGTHDEL_SIZE_MISMATCH
								return sub_offset
							else:
								return offset
						elif field.type == PB_DATA_TYPE.STRING:
							var str_bytes : PackedByteArray = bytes.slice(offset, inner_size + offset)
							if field.rule == PB_RULE.REPEATED:
								field.value.append(str_bytes.get_string_from_utf8())
							else:
								field.value = str_bytes.get_string_from_utf8()
							return offset + inner_size
						elif field.type == PB_DATA_TYPE.BYTES:
							var val_bytes : PackedByteArray = bytes.slice(offset, inner_size + offset)
							if field.rule == PB_RULE.REPEATED:
								field.value.append(val_bytes)
							else:
								field.value = val_bytes
							return offset + inner_size
					else:
						return PB_ERR.LENGTHDEL_SIZE_NOT_FOUND
				else:
					return PB_ERR.LENGTHDEL_SIZE_NOT_FOUND
		return PB_ERR.UNDEFINED_STATE

	static func unpack_message(data, bytes : PackedByteArray, offset : int, limit : int) -> int:
		while true:
			var tt : PBTypeTag = unpack_type_tag(bytes, offset)
			if tt.ok:
				offset += tt.offset
				if data.has(tt.tag):
					var service : PBServiceField = data[tt.tag]
					var type : int = pb_type_from_data_type(service.field.type)
					if type == tt.type || (tt.type == PB_TYPE.LENGTHDEL && service.field.rule == PB_RULE.REPEATED && service.field.option_packed):
						var res : int = unpack_field(bytes, offset, service.field, type, service.func_ref)
						if res > 0:
							service.state = PB_SERVICE_STATE.FILLED
							offset = res
							if offset == limit:
								return offset
							elif offset > limit:
								return PB_ERR.PACKAGE_SIZE_MISMATCH
						elif res < 0:
							return res
						else:
							break
				else:
					var res : int = skip_unknown_field(bytes, offset, tt.type)
					if res > 0:
						offset = res
						if offset == limit:
							return offset
						elif offset > limit:
							return PB_ERR.PACKAGE_SIZE_MISMATCH
					elif res < 0:
						return res
					else:
						break							
			else:
				return offset
		return PB_ERR.UNDEFINED_STATE

	static func pack_message(data) -> PackedByteArray:
		var DEFAULT_VALUES
		if PROTO_VERSION == 2:
			DEFAULT_VALUES = DEFAULT_VALUES_2
		elif PROTO_VERSION == 3:
			DEFAULT_VALUES = DEFAULT_VALUES_3
		var result : PackedByteArray = PackedByteArray()
		var keys : Array = data.keys()
		keys.sort()
		for i in keys:
			if data[i].field.value != null:
				if data[i].state == PB_SERVICE_STATE.UNFILLED \
				&& !data[i].field.is_map_field \
				&& typeof(data[i].field.value) == typeof(DEFAULT_VALUES[data[i].field.type]) \
				&& data[i].field.value == DEFAULT_VALUES[data[i].field.type]:
					continue
				elif data[i].field.rule == PB_RULE.REPEATED && data[i].field.value.size() == 0:
					continue
				result.append_array(pack_field(data[i].field))
			elif data[i].field.rule == PB_RULE.REQUIRED:
				print("Error: required field is not filled: Tag:", data[i].field.tag)
				return PackedByteArray()
		return result

	static func check_required(data) -> bool:
		var keys : Array = data.keys()
		for i in keys:
			if data[i].field.rule == PB_RULE.REQUIRED && data[i].state == PB_SERVICE_STATE.UNFILLED:
				return false
		return true

	static func construct_map(key_values):
		var result = {}
		for kv in key_values:
			result[kv.get_key()] = kv.get_value()
		return result
	
	static func tabulate(text : String, nesting : int) -> String:
		var tab : String = ""
		for _i in range(nesting):
			tab += DEBUG_TAB
		return tab + text
	
	static func value_to_string(value, field : PBField, nesting : int) -> String:
		var result : String = ""
		var text : String
		if field.type == PB_DATA_TYPE.MESSAGE:
			result += "{"
			nesting += 1
			text = message_to_string(value.data, nesting)
			if text != "":
				result += "\n" + text
				nesting -= 1
				result += tabulate("}", nesting)
			else:
				nesting -= 1
				result += "}"
		elif field.type == PB_DATA_TYPE.BYTES:
			result += "<"
			for i in range(value.size()):
				result += str(value[i])
				if i != (value.size() - 1):
					result += ", "
			result += ">"
		elif field.type == PB_DATA_TYPE.STRING:
			result += "\"" + value + "\""
		elif field.type == PB_DATA_TYPE.ENUM:
			result += "ENUM::" + str(value)
		else:
			result += str(value)
		return result
	
	static func field_to_string(field : PBField, nesting : int) -> String:
		var result : String = tabulate(field.name + ": ", nesting)
		if field.type == PB_DATA_TYPE.MAP:
			if field.value.size() > 0:
				result += "(\n"
				nesting += 1
				for i in range(field.value.size()):
					var local_key_value = field.value[i].data[1].field
					result += tabulate(value_to_string(local_key_value.value, local_key_value, nesting), nesting) + ": "
					local_key_value = field.value[i].data[2].field
					result += value_to_string(local_key_value.value, local_key_value, nesting)
					if i != (field.value.size() - 1):
						result += ","
					result += "\n"
				nesting -= 1
				result += tabulate(")", nesting)
			else:
				result += "()"
		elif field.rule == PB_RULE.REPEATED:
			if field.value.size() > 0:
				result += "[\n"
				nesting += 1
				for i in range(field.value.size()):
					result += tabulate(str(i) + ": ", nesting)
					result += value_to_string(field.value[i], field, nesting)
					if i != (field.value.size() - 1):
						result += ","
					result += "\n"
				nesting -= 1
				result += tabulate("]", nesting)
			else:
				result += "[]"
		else:
			result += value_to_string(field.value, field, nesting)
		result += ";\n"
		return result
		
	static func message_to_string(data, nesting : int = 0) -> String:
		var DEFAULT_VALUES
		if PROTO_VERSION == 2:
			DEFAULT_VALUES = DEFAULT_VALUES_2
		elif PROTO_VERSION == 3:
			DEFAULT_VALUES = DEFAULT_VALUES_3
		var result : String = ""
		var keys : Array = data.keys()
		keys.sort()
		for i in keys:
			if data[i].field.value != null:
				if data[i].state == PB_SERVICE_STATE.UNFILLED \
				&& !data[i].field.is_map_field \
				&& typeof(data[i].field.value) == typeof(DEFAULT_VALUES[data[i].field.type]) \
				&& data[i].field.value == DEFAULT_VALUES[data[i].field.type]:
					continue
				elif data[i].field.rule == PB_RULE.REPEATED && data[i].field.value.size() == 0:
					continue
				result += field_to_string(data[i].field, nesting)
			elif data[i].field.rule == PB_RULE.REQUIRED:
				result += data[i].field.name + ": " + "error"
		return result



############### USER DATA BEGIN ################


class PingMessage:
	func _init():
		var service
		
		__timestamp = PBField.new("timestamp", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __timestamp
		data[__timestamp.tag] = service
		
	var data = {}
	
	var __timestamp: PBField
	func has_timestamp() -> bool:
		if __timestamp.value != null:
			return true
		return false
	func get_timestamp() -> int:
		return __timestamp.value
	func clear_timestamp() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__timestamp.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_timestamp(value : int) -> void:
		__timestamp.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class ChatMessage:
	func _init():
		var service
		
		__msg = PBField.new("msg", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __msg
		data[__msg.tag] = service
		
	var data = {}
	
	var __msg: PBField
	func has_msg() -> bool:
		if __msg.value != null:
			return true
		return false
	func get_msg() -> String:
		return __msg.value
	func clear_msg() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__msg.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_msg(value : String) -> void:
		__msg.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class IdMessage:
	func _init():
		var service
		
		__id = PBField.new("id", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __id
		data[__id.tag] = service
		
	var data = {}
	
	var __id: PBField
	func has_id() -> bool:
		if __id.value != null:
			return true
		return false
	func get_id() -> int:
		return __id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_id(value : int) -> void:
		__id.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class LoginRequestMessage:
	func _init():
		var service
		
		__username = PBField.new("username", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __username
		data[__username.tag] = service
		
		__password = PBField.new("password", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __password
		data[__password.tag] = service
		
	var data = {}
	
	var __username: PBField
	func has_username() -> bool:
		if __username.value != null:
			return true
		return false
	func get_username() -> String:
		return __username.value
	func clear_username() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__username.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_username(value : String) -> void:
		__username.value = value
	
	var __password: PBField
	func has_password() -> bool:
		if __password.value != null:
			return true
		return false
	func get_password() -> String:
		return __password.value
	func clear_password() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__password.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_password(value : String) -> void:
		__password.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class RegisterRequestMessage:
	func _init():
		var service
		
		__username = PBField.new("username", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __username
		data[__username.tag] = service
		
		__password = PBField.new("password", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __password
		data[__password.tag] = service
		
	var data = {}
	
	var __username: PBField
	func has_username() -> bool:
		if __username.value != null:
			return true
		return false
	func get_username() -> String:
		return __username.value
	func clear_username() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__username.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_username(value : String) -> void:
		__username.value = value
	
	var __password: PBField
	func has_password() -> bool:
		if __password.value != null:
			return true
		return false
	func get_password() -> String:
		return __password.value
	func clear_password() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__password.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_password(value : String) -> void:
		__password.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class OkResponseMessage:
	func _init():
		var service
		
	var data = {}
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class DenyResponseMessage:
	func _init():
		var service
		
		__reason = PBField.new("reason", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __reason
		data[__reason.tag] = service
		
	var data = {}
	
	var __reason: PBField
	func has_reason() -> bool:
		if __reason.value != null:
			return true
		return false
	func get_reason() -> String:
		return __reason.value
	func clear_reason() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__reason.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_reason(value : String) -> void:
		__reason.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class LobbyPlayerData:
	func _init():
		var service
		
		__client_id = PBField.new("client_id", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __client_id
		data[__client_id.tag] = service
		
		__username = PBField.new("username", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __username
		data[__username.tag] = service
		
		__is_ready = PBField.new("is_ready", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = __is_ready
		data[__is_ready.tag] = service
		
	var data = {}
	
	var __client_id: PBField
	func has_client_id() -> bool:
		if __client_id.value != null:
			return true
		return false
	func get_client_id() -> int:
		return __client_id.value
	func clear_client_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__client_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_client_id(value : int) -> void:
		__client_id.value = value
	
	var __username: PBField
	func has_username() -> bool:
		if __username.value != null:
			return true
		return false
	func get_username() -> String:
		return __username.value
	func clear_username() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__username.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_username(value : String) -> void:
		__username.value = value
	
	var __is_ready: PBField
	func has_is_ready() -> bool:
		if __is_ready.value != null:
			return true
		return false
	func get_is_ready() -> bool:
		return __is_ready.value
	func clear_is_ready() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__is_ready.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_is_ready(value : bool) -> void:
		__is_ready.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class LobbyData:
	func _init():
		var service
		
		__id = PBField.new("id", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __id
		data[__id.tag] = service
		
		__name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __name
		data[__name.tag] = service
		
		__current_players = PBField.new("current_players", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __current_players
		data[__current_players.tag] = service
		
		__max_players = PBField.new("max_players", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __max_players
		data[__max_players.tag] = service
		
	var data = {}
	
	var __id: PBField
	func has_id() -> bool:
		if __id.value != null:
			return true
		return false
	func get_id() -> int:
		return __id.value
	func clear_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_id(value : int) -> void:
		__id.value = value
	
	var __name: PBField
	func has_name() -> bool:
		if __name.value != null:
			return true
		return false
	func get_name() -> String:
		return __name.value
	func clear_name() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		__name.value = value
	
	var __current_players: PBField
	func has_current_players() -> bool:
		if __current_players.value != null:
			return true
		return false
	func get_current_players() -> int:
		return __current_players.value
	func clear_current_players() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__current_players.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_current_players(value : int) -> void:
		__current_players.value = value
	
	var __max_players: PBField
	func has_max_players() -> bool:
		if __max_players.value != null:
			return true
		return false
	func get_max_players() -> int:
		return __max_players.value
	func clear_max_players() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__max_players.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_max_players(value : int) -> void:
		__max_players.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class ListLobbiesRequest:
	func _init():
		var service
		
		__page = PBField.new("page", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __page
		data[__page.tag] = service
		
		__page_size = PBField.new("page_size", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __page_size
		data[__page_size.tag] = service
		
		__name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __name
		data[__name.tag] = service
		
		__format = PBField.new("format", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __format
		data[__format.tag] = service
		
		__state = PBField.new("state", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __state
		data[__state.tag] = service
		
	var data = {}
	
	var __page: PBField
	func has_page() -> bool:
		if __page.value != null:
			return true
		return false
	func get_page() -> int:
		return __page.value
	func clear_page() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__page.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_page(value : int) -> void:
		__page.value = value
	
	var __page_size: PBField
	func has_page_size() -> bool:
		if __page_size.value != null:
			return true
		return false
	func get_page_size() -> int:
		return __page_size.value
	func clear_page_size() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__page_size.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_page_size(value : int) -> void:
		__page_size.value = value
	
	var __name: PBField
	func has_name() -> bool:
		if __name.value != null:
			return true
		return false
	func get_name() -> String:
		return __name.value
	func clear_name() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		__name.value = value
	
	var __format: PBField
	func has_format() -> bool:
		if __format.value != null:
			return true
		return false
	func get_format() -> String:
		return __format.value
	func clear_format() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__format.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_format(value : String) -> void:
		__format.value = value
	
	var __state: PBField
	func has_state() -> bool:
		if __state.value != null:
			return true
		return false
	func get_state() -> int:
		return __state.value
	func clear_state() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__state.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_state(value : int) -> void:
		__state.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class ListLobbiesResponse:
	func _init():
		var service
		
		__count = PBField.new("count", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __count
		data[__count.tag] = service
		
		var __lobbies_default: Array[LobbyData] = []
		__lobbies = PBField.new("lobbies", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 2, true, __lobbies_default)
		service = PBServiceField.new()
		service.field = __lobbies
		service.func_ref = Callable(self, "add_lobbies")
		data[__lobbies.tag] = service
		
	var data = {}
	
	var __count: PBField
	func has_count() -> bool:
		if __count.value != null:
			return true
		return false
	func get_count() -> int:
		return __count.value
	func clear_count() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__count.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_count(value : int) -> void:
		__count.value = value
	
	var __lobbies: PBField
	func get_lobbies() -> Array[LobbyData]:
		return __lobbies.value
	func clear_lobbies() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__lobbies.value.clear()
	func add_lobbies() -> LobbyData:
		var element = LobbyData.new()
		__lobbies.value.append(element)
		return element
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class CreateLobbyRequest:
	func _init():
		var service
		
		__name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __name
		data[__name.tag] = service
		
		__format = PBField.new("format", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __format
		data[__format.tag] = service
		
		__max_players = PBField.new("max_players", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = __max_players
		data[__max_players.tag] = service
		
		__is_private = PBField.new("is_private", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = __is_private
		data[__is_private.tag] = service
		
		__password = PBField.new("password", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __password
		data[__password.tag] = service
		
	var data = {}
	
	var __name: PBField
	func has_name() -> bool:
		if __name.value != null:
			return true
		return false
	func get_name() -> String:
		return __name.value
	func clear_name() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		__name.value = value
	
	var __format: PBField
	func has_format() -> bool:
		if __format.value != null:
			return true
		return false
	func get_format() -> String:
		return __format.value
	func clear_format() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__format.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_format(value : String) -> void:
		__format.value = value
	
	var __max_players: PBField
	func has_max_players() -> bool:
		if __max_players.value != null:
			return true
		return false
	func get_max_players() -> int:
		return __max_players.value
	func clear_max_players() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__max_players.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_max_players(value : int) -> void:
		__max_players.value = value
	
	var __is_private: PBField
	func has_is_private() -> bool:
		if __is_private.value != null:
			return true
		return false
	func get_is_private() -> bool:
		return __is_private.value
	func clear_is_private() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__is_private.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_is_private(value : bool) -> void:
		__is_private.value = value
	
	var __password: PBField
	func has_password() -> bool:
		if __password.value != null:
			return true
		return false
	func get_password() -> String:
		return __password.value
	func clear_password() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__password.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_password(value : String) -> void:
		__password.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class CreateLobbyResponse:
	func _init():
		var service
		
	var data = {}
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class JoinLobbyRequest:
	func _init():
		var service
		
		__lobby_id = PBField.new("lobby_id", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __lobby_id
		data[__lobby_id.tag] = service
		
		__password = PBField.new("password", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __password
		data[__password.tag] = service
		
	var data = {}
	
	var __lobby_id: PBField
	func has_lobby_id() -> bool:
		if __lobby_id.value != null:
			return true
		return false
	func get_lobby_id() -> int:
		return __lobby_id.value
	func clear_lobby_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__lobby_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_lobby_id(value : int) -> void:
		__lobby_id.value = value
	
	var __password: PBField
	func has_password() -> bool:
		if __password.value != null:
			return true
		return false
	func get_password() -> String:
		return __password.value
	func clear_password() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__password.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_password(value : String) -> void:
		__password.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class JoinedLobbyResponse:
	func _init():
		var service
		
		__lobby_id = PBField.new("lobby_id", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __lobby_id
		data[__lobby_id.tag] = service
		
		__lobby_name = PBField.new("lobby_name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __lobby_name
		data[__lobby_name.tag] = service
		
		__host_username = PBField.new("host_username", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = __host_username
		data[__host_username.tag] = service
		
		var __players_default: Array[LobbyPlayerData] = []
		__players = PBField.new("players", PB_DATA_TYPE.MESSAGE, PB_RULE.REPEATED, 4, true, __players_default)
		service = PBServiceField.new()
		service.field = __players
		service.func_ref = Callable(self, "add_players")
		data[__players.tag] = service
		
	var data = {}
	
	var __lobby_id: PBField
	func has_lobby_id() -> bool:
		if __lobby_id.value != null:
			return true
		return false
	func get_lobby_id() -> int:
		return __lobby_id.value
	func clear_lobby_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__lobby_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_lobby_id(value : int) -> void:
		__lobby_id.value = value
	
	var __lobby_name: PBField
	func has_lobby_name() -> bool:
		if __lobby_name.value != null:
			return true
		return false
	func get_lobby_name() -> String:
		return __lobby_name.value
	func clear_lobby_name() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__lobby_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_lobby_name(value : String) -> void:
		__lobby_name.value = value
	
	var __host_username: PBField
	func has_host_username() -> bool:
		if __host_username.value != null:
			return true
		return false
	func get_host_username() -> String:
		return __host_username.value
	func clear_host_username() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__host_username.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_host_username(value : String) -> void:
		__host_username.value = value
	
	var __players: PBField
	func get_players() -> Array[LobbyPlayerData]:
		return __players.value
	func clear_players() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__players.value.clear()
	func add_players() -> LobbyPlayerData:
		var element = LobbyPlayerData.new()
		__players.value.append(element)
		return element
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class LeaveLobbyRequest:
	func _init():
		var service
		
	var data = {}
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class LeftLobbyResponse:
	func _init():
		var service
		
		__client_id = PBField.new("client_id", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __client_id
		data[__client_id.tag] = service
		
	var data = {}
	
	var __client_id: PBField
	func has_client_id() -> bool:
		if __client_id.value != null:
			return true
		return false
	func get_client_id() -> int:
		return __client_id.value
	func clear_client_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__client_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_client_id(value : int) -> void:
		__client_id.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class Packet:
	func _init():
		var service
		
		__sender_id = PBField.new("sender_id", PB_DATA_TYPE.UINT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64])
		service = PBServiceField.new()
		service.field = __sender_id
		data[__sender_id.tag] = service
		
		__ping = PBField.new("ping", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __ping
		service.func_ref = Callable(self, "new_ping")
		data[__ping.tag] = service
		
		__chat = PBField.new("chat", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __chat
		service.func_ref = Callable(self, "new_chat")
		data[__chat.tag] = service
		
		__id = PBField.new("id", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __id
		service.func_ref = Callable(self, "new_id")
		data[__id.tag] = service
		
		__login_request = PBField.new("login_request", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __login_request
		service.func_ref = Callable(self, "new_login_request")
		data[__login_request.tag] = service
		
		__register_request = PBField.new("register_request", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __register_request
		service.func_ref = Callable(self, "new_register_request")
		data[__register_request.tag] = service
		
		__ok_response = PBField.new("ok_response", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __ok_response
		service.func_ref = Callable(self, "new_ok_response")
		data[__ok_response.tag] = service
		
		__deny_response = PBField.new("deny_response", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __deny_response
		service.func_ref = Callable(self, "new_deny_response")
		data[__deny_response.tag] = service
		
		__list_lobbies_request = PBField.new("list_lobbies_request", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __list_lobbies_request
		service.func_ref = Callable(self, "new_list_lobbies_request")
		data[__list_lobbies_request.tag] = service
		
		__list_lobbies_response = PBField.new("list_lobbies_response", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __list_lobbies_response
		service.func_ref = Callable(self, "new_list_lobbies_response")
		data[__list_lobbies_response.tag] = service
		
		__create_lobby_request = PBField.new("create_lobby_request", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 11, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __create_lobby_request
		service.func_ref = Callable(self, "new_create_lobby_request")
		data[__create_lobby_request.tag] = service
		
		__create_lobby_response = PBField.new("create_lobby_response", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 12, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __create_lobby_response
		service.func_ref = Callable(self, "new_create_lobby_response")
		data[__create_lobby_response.tag] = service
		
		__join_lobby_request = PBField.new("join_lobby_request", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 13, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __join_lobby_request
		service.func_ref = Callable(self, "new_join_lobby_request")
		data[__join_lobby_request.tag] = service
		
		__joined_lobby_response = PBField.new("joined_lobby_response", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 14, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __joined_lobby_response
		service.func_ref = Callable(self, "new_joined_lobby_response")
		data[__joined_lobby_response.tag] = service
		
		__leave_lobby_request = PBField.new("leave_lobby_request", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 15, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __leave_lobby_request
		service.func_ref = Callable(self, "new_leave_lobby_request")
		data[__leave_lobby_request.tag] = service
		
		__left_lobby_response = PBField.new("left_lobby_response", PB_DATA_TYPE.MESSAGE, PB_RULE.OPTIONAL, 16, true, DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE])
		service = PBServiceField.new()
		service.field = __left_lobby_response
		service.func_ref = Callable(self, "new_left_lobby_response")
		data[__left_lobby_response.tag] = service
		
	var data = {}
	
	enum MsgCase {
		MSG_NOT_SET = 0,
		PING = 2,
		CHAT = 3,
		ID = 4,
		LOGIN_REQUEST = 5,
		REGISTER_REQUEST = 6,
		OK_RESPONSE = 7,
		DENY_RESPONSE = 8,
		LIST_LOBBIES_REQUEST = 9,
		LIST_LOBBIES_RESPONSE = 10,
		CREATE_LOBBY_REQUEST = 11,
		CREATE_LOBBY_RESPONSE = 12,
		JOIN_LOBBY_REQUEST = 13,
		JOINED_LOBBY_RESPONSE = 14,
		LEAVE_LOBBY_REQUEST = 15,
		LEFT_LOBBY_RESPONSE = 16,
	}
	var _msg_case: int = 0

	var __sender_id: PBField
	func has_sender_id() -> bool:
		if __sender_id.value != null:
			return true
		return false
	func get_sender_id() -> int:
		return __sender_id.value
	func clear_sender_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		__sender_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.UINT64]
	func set_sender_id(value : int) -> void:
		__sender_id.value = value
	
	var __ping: PBField
	func has_ping() -> bool:
		return data[2].state == PB_SERVICE_STATE.FILLED
	func get_ping() -> PingMessage:
		return __ping.value
	func clear_ping() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__ping.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_ping() -> PingMessage:
		data[2].state = PB_SERVICE_STATE.FILLED
		_msg_case = 2
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__list_lobbies_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__list_lobbies_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__create_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__create_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__join_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__joined_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__leave_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__left_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__ping.value = PingMessage.new()
		return __ping.value
	
	var __chat: PBField
	func has_chat() -> bool:
		return data[3].state == PB_SERVICE_STATE.FILLED
	func get_chat() -> ChatMessage:
		return __chat.value
	func clear_chat() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_chat() -> ChatMessage:
		__ping.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		data[3].state = PB_SERVICE_STATE.FILLED
		_msg_case = 3
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__list_lobbies_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__list_lobbies_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__create_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__create_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__join_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__joined_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__leave_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__left_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = ChatMessage.new()
		return __chat.value
	
	var __id: PBField
	func has_id() -> bool:
		return data[4].state == PB_SERVICE_STATE.FILLED
	func get_id() -> IdMessage:
		return __id.value
	func clear_id() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_id() -> IdMessage:
		__ping.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		data[4].state = PB_SERVICE_STATE.FILLED
		_msg_case = 4
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__list_lobbies_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__list_lobbies_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__create_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__create_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__join_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__joined_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__leave_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__left_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__id.value = IdMessage.new()
		return __id.value
	
	var __login_request: PBField
	func has_login_request() -> bool:
		return data[5].state == PB_SERVICE_STATE.FILLED
	func get_login_request() -> LoginRequestMessage:
		return __login_request.value
	func clear_login_request() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_login_request() -> LoginRequestMessage:
		__ping.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		data[5].state = PB_SERVICE_STATE.FILLED
		_msg_case = 5
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__list_lobbies_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__list_lobbies_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__create_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__create_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__join_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__joined_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__leave_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__left_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__login_request.value = LoginRequestMessage.new()
		return __login_request.value
	
	var __register_request: PBField
	func has_register_request() -> bool:
		return data[6].state == PB_SERVICE_STATE.FILLED
	func get_register_request() -> RegisterRequestMessage:
		return __register_request.value
	func clear_register_request() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_register_request() -> RegisterRequestMessage:
		__ping.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		data[6].state = PB_SERVICE_STATE.FILLED
		_msg_case = 6
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__list_lobbies_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__list_lobbies_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__create_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__create_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__join_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__joined_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__leave_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__left_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = RegisterRequestMessage.new()
		return __register_request.value
	
	var __ok_response: PBField
	func has_ok_response() -> bool:
		return data[7].state == PB_SERVICE_STATE.FILLED
	func get_ok_response() -> OkResponseMessage:
		return __ok_response.value
	func clear_ok_response() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_ok_response() -> OkResponseMessage:
		__ping.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		data[7].state = PB_SERVICE_STATE.FILLED
		_msg_case = 7
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__list_lobbies_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__list_lobbies_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__create_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__create_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__join_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__joined_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__leave_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__left_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = OkResponseMessage.new()
		return __ok_response.value
	
	var __deny_response: PBField
	func has_deny_response() -> bool:
		return data[8].state == PB_SERVICE_STATE.FILLED
	func get_deny_response() -> DenyResponseMessage:
		return __deny_response.value
	func clear_deny_response() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_deny_response() -> DenyResponseMessage:
		__ping.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		data[8].state = PB_SERVICE_STATE.FILLED
		_msg_case = 8
		__list_lobbies_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__list_lobbies_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__create_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__create_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__join_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__joined_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__leave_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__left_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DenyResponseMessage.new()
		return __deny_response.value
	
	var __list_lobbies_request: PBField
	func has_list_lobbies_request() -> bool:
		return data[9].state == PB_SERVICE_STATE.FILLED
	func get_list_lobbies_request() -> ListLobbiesRequest:
		return __list_lobbies_request.value
	func clear_list_lobbies_request() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__list_lobbies_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_list_lobbies_request() -> ListLobbiesRequest:
		__ping.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		data[9].state = PB_SERVICE_STATE.FILLED
		_msg_case = 9
		__list_lobbies_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__create_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__create_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__join_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__joined_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__leave_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__left_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__list_lobbies_request.value = ListLobbiesRequest.new()
		return __list_lobbies_request.value
	
	var __list_lobbies_response: PBField
	func has_list_lobbies_response() -> bool:
		return data[10].state == PB_SERVICE_STATE.FILLED
	func get_list_lobbies_response() -> ListLobbiesResponse:
		return __list_lobbies_response.value
	func clear_list_lobbies_response() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__list_lobbies_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_list_lobbies_response() -> ListLobbiesResponse:
		__ping.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__list_lobbies_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		data[10].state = PB_SERVICE_STATE.FILLED
		_msg_case = 10
		__create_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__create_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__join_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__joined_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__leave_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__left_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__list_lobbies_response.value = ListLobbiesResponse.new()
		return __list_lobbies_response.value
	
	var __create_lobby_request: PBField
	func has_create_lobby_request() -> bool:
		return data[11].state == PB_SERVICE_STATE.FILLED
	func get_create_lobby_request() -> CreateLobbyRequest:
		return __create_lobby_request.value
	func clear_create_lobby_request() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__create_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_create_lobby_request() -> CreateLobbyRequest:
		__ping.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__list_lobbies_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__list_lobbies_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		data[11].state = PB_SERVICE_STATE.FILLED
		_msg_case = 11
		__create_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__join_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__joined_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__leave_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__left_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__create_lobby_request.value = CreateLobbyRequest.new()
		return __create_lobby_request.value
	
	var __create_lobby_response: PBField
	func has_create_lobby_response() -> bool:
		return data[12].state == PB_SERVICE_STATE.FILLED
	func get_create_lobby_response() -> CreateLobbyResponse:
		return __create_lobby_response.value
	func clear_create_lobby_response() -> void:
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__create_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_create_lobby_response() -> CreateLobbyResponse:
		__ping.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__list_lobbies_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__list_lobbies_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__create_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		data[12].state = PB_SERVICE_STATE.FILLED
		_msg_case = 12
		__join_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__joined_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__leave_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__left_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__create_lobby_response.value = CreateLobbyResponse.new()
		return __create_lobby_response.value
	
	var __join_lobby_request: PBField
	func has_join_lobby_request() -> bool:
		return data[13].state == PB_SERVICE_STATE.FILLED
	func get_join_lobby_request() -> JoinLobbyRequest:
		return __join_lobby_request.value
	func clear_join_lobby_request() -> void:
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__join_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_join_lobby_request() -> JoinLobbyRequest:
		__ping.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__list_lobbies_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__list_lobbies_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__create_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__create_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		data[13].state = PB_SERVICE_STATE.FILLED
		_msg_case = 13
		__joined_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__leave_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__left_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__join_lobby_request.value = JoinLobbyRequest.new()
		return __join_lobby_request.value
	
	var __joined_lobby_response: PBField
	func has_joined_lobby_response() -> bool:
		return data[14].state == PB_SERVICE_STATE.FILLED
	func get_joined_lobby_response() -> JoinedLobbyResponse:
		return __joined_lobby_response.value
	func clear_joined_lobby_response() -> void:
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__joined_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_joined_lobby_response() -> JoinedLobbyResponse:
		__ping.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__list_lobbies_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__list_lobbies_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__create_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__create_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__join_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		data[14].state = PB_SERVICE_STATE.FILLED
		_msg_case = 14
		__leave_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__left_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__joined_lobby_response.value = JoinedLobbyResponse.new()
		return __joined_lobby_response.value
	
	var __leave_lobby_request: PBField
	func has_leave_lobby_request() -> bool:
		return data[15].state == PB_SERVICE_STATE.FILLED
	func get_leave_lobby_request() -> LeaveLobbyRequest:
		return __leave_lobby_request.value
	func clear_leave_lobby_request() -> void:
		data[15].state = PB_SERVICE_STATE.UNFILLED
		__leave_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_leave_lobby_request() -> LeaveLobbyRequest:
		__ping.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__list_lobbies_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__list_lobbies_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__create_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__create_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__join_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__joined_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		data[15].state = PB_SERVICE_STATE.FILLED
		_msg_case = 15
		__left_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__leave_lobby_request.value = LeaveLobbyRequest.new()
		return __leave_lobby_request.value
	
	var __left_lobby_response: PBField
	func has_left_lobby_response() -> bool:
		return data[16].state == PB_SERVICE_STATE.FILLED
	func get_left_lobby_response() -> LeftLobbyResponse:
		return __left_lobby_response.value
	func clear_left_lobby_response() -> void:
		data[16].state = PB_SERVICE_STATE.UNFILLED
		__left_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
	func new_left_lobby_response() -> LeftLobbyResponse:
		__ping.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[2].state = PB_SERVICE_STATE.UNFILLED
		__chat.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[3].state = PB_SERVICE_STATE.UNFILLED
		__id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[4].state = PB_SERVICE_STATE.UNFILLED
		__login_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[5].state = PB_SERVICE_STATE.UNFILLED
		__register_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[6].state = PB_SERVICE_STATE.UNFILLED
		__ok_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[7].state = PB_SERVICE_STATE.UNFILLED
		__deny_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[8].state = PB_SERVICE_STATE.UNFILLED
		__list_lobbies_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[9].state = PB_SERVICE_STATE.UNFILLED
		__list_lobbies_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[10].state = PB_SERVICE_STATE.UNFILLED
		__create_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[11].state = PB_SERVICE_STATE.UNFILLED
		__create_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[12].state = PB_SERVICE_STATE.UNFILLED
		__join_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[13].state = PB_SERVICE_STATE.UNFILLED
		__joined_lobby_response.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[14].state = PB_SERVICE_STATE.UNFILLED
		__leave_lobby_request.value = DEFAULT_VALUES_3[PB_DATA_TYPE.MESSAGE]
		data[15].state = PB_SERVICE_STATE.UNFILLED
		data[16].state = PB_SERVICE_STATE.FILLED
		_msg_case = 16
		__left_lobby_response.value = LeftLobbyResponse.new()
		return __left_lobby_response.value
	
	func get_msg_case() -> int:
		return _msg_case
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
################ USER DATA END #################
