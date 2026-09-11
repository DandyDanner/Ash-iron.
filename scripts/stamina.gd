extends RefCounted
## Sprint reserve. Recovery continues while walking; callers pause it with player controls.
const MAX := 100.0
const DRAIN := 16.0
const RECOVERY := 22.0
const RECOVERY_DELAY := 0.9
const EXHAUSTION_RELEASE := 20.0
var value := MAX
var recovery_delay := 0.0
var exhausted := false

func advance(delta: float, wants_sprint: bool) -> bool:
	if wants_sprint and not exhausted and value > 0:
		value = maxf(0, value - DRAIN * delta)
		recovery_delay = RECOVERY_DELAY
		exhausted = value == 0
		return not exhausted
	var recovery_time := maxf(0, delta - recovery_delay)
	recovery_delay = maxf(0, recovery_delay - delta)
	value = minf(MAX, value + RECOVERY * recovery_time)
	if value >= EXHAUSTION_RELEASE: exhausted = false
	return false

func to_data() -> Dictionary:
	return {"value": value, "recovery_delay": recovery_delay, "exhausted": exhausted}

func restore(raw: Variant) -> void:
	var data: Dictionary = raw if raw is Dictionary else {}
	value = clampf(_number(data.get("value"), MAX), 0, MAX)
	recovery_delay = clampf(_number(data.get("recovery_delay"), 0), 0, RECOVERY_DELAY)
	exhausted = value == 0 or (data.get("exhausted", false) == true and value < EXHAUSTION_RELEASE)

static func _number(raw: Variant, fallback: float) -> float:
	return float(raw) if (raw is float or raw is int) and is_finite(float(raw)) else fallback
