extends RefCounted
class_name DebugLog

# One switch for all gameplay logging. print() is slow and floods the output,
# so it is off by default. Set ENABLED = true while debugging.
static var ENABLED: bool = false

static func log(...args: Array) -> void:
	if ENABLED:
		print("".join(args.map(func(a): return str(a))))
