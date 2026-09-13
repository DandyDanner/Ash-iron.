extends RefCounted
## Shared timings/geometry keep animation, telegraphs and damage in agreement.
const SLAM_RADIUS := 7.0
const SLAM_WARNING := 1.2
const SLAM_DAMAGE := 34
const SWIPE_WARNING := .85
const SWIPE_SWING := .24
const SWIPE_CONTACT := .12
const SWIPE_RECOVERY := 1.05
const SWIPE_COOLDOWN := 5.0
const SWIPE_DAMAGE := 18
const SWIPE_RADIUS := 7.6 # Doubled reach follows the doubled paws; telegraph uses this too.
const SWIPE_MIN_ANGLE := -10.0 * PI / 180.0
const SWIPE_MAX_ANGLE := 100.0 * PI / 180.0

static func in_swipe_arc(local_offset: Vector3, side: float) -> bool:
	var angle := atan2(local_offset.x, local_offset.z) * side
	return Vector2(local_offset.x, local_offset.z).length() <= SWIPE_RADIUS and absf(local_offset.y) < 2.5 and angle >= SWIPE_MIN_ANGLE and angle <= SWIPE_MAX_ANGLE

static func slam_lift(time: float) -> float:
	# A short planted crouch precedes the lift; the last beat accelerates into contact.
	return smoothstep(.18, .78, time) * (1.0 - smoothstep(1.02, SLAM_WARNING, time))

static func slam_brace(time: float) -> float:
	# Shift mass onto the rear pair before the front paws leave the ground.
	return smoothstep(0, .16, time) * (1.0 - smoothstep(.38, .72, time))

static func swipe_sweep(time: float) -> float:
	# Contact is the midpoint of the swing, matching SWIPE_CONTACT.
	return smoothstep(0, SWIPE_SWING, time)
