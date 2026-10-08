extends Node

signal time_updated(seconds_remaining: int)
signal sudden_death_started
signal match_ended

const MATCH_DURATION = 300.0   # 5 minutes, per your design doc
const SUDDEN_DEATH_DURATION = 120.0  # adjust to your actual sudden-death length

var time_remaining: float = MATCH_DURATION
var in_sudden_death: bool = false
var match_active: bool = false

func start_match():
	if not multiplayer.is_server():
		return
	time_remaining = MATCH_DURATION
	in_sudden_death = false
	match_active = true
	sync_timer_state.rpc(time_remaining, in_sudden_death, match_active)

func _process(delta):
	if not multiplayer.is_server() or not match_active:
		return

	time_remaining -= delta

	if time_remaining <= 0:
		if not in_sudden_death:
			_enter_sudden_death()
		else:
			_end_match()
		return

	# only push updates roughly once a second, not every frame
	if int(time_remaining) != int(time_remaining + delta):
		sync_timer_state.rpc(time_remaining, in_sudden_death, match_active)

func _enter_sudden_death():
	in_sudden_death = true
	time_remaining = SUDDEN_DEATH_DURATION
	sync_timer_state.rpc(time_remaining, in_sudden_death, match_active)
	notify_sudden_death.rpc()

func _end_match():
	match_active = false
	sync_timer_state.rpc(time_remaining, in_sudden_death, match_active)
	notify_match_ended.rpc()

@rpc("authority", "call_local", "reliable")
func sync_timer_state(new_time: float, sudden_death: bool, active: bool):
	time_remaining = new_time
	in_sudden_death = sudden_death
	match_active = active
	time_updated.emit(int(ceil(time_remaining)))

@rpc("authority", "call_local", "reliable")
func notify_sudden_death():
	sudden_death_started.emit()

@rpc("authority", "call_local", "reliable")
func notify_match_ended():
	match_ended.emit()
