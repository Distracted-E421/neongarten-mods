# Steam API Stub for Non-Steam Builds
# Place in autoloads or require this instead of GodotSteam
#
# This provides stub implementations of all Steam API calls used by Neongarten
# allowing the game to run natively on Linux without Steam.

extends Node

# Constants matching GodotSteam
const STEAM_API_INIT_RESULT_OK = 0
const RESULT_OK = 1

# Signals (stubbed)
signal current_stats_received(game_id: int, result: int, user_id: int)

# ═══════════════════════════════════════════════════════════════════════════════
# INITIALIZATION
# ═══════════════════════════════════════════════════════════════════════════════

func steamInitEx(_run_callbacks: bool, _app_id: int) -> Dictionary:
	print("[Steam Stub] steamInitEx called - returning success (stub mode)")
	return {
		"status": STEAM_API_INIT_RESULT_OK,
		"verbal": "Steam API stub initialized (no actual Steam connection)"
	}

# ═══════════════════════════════════════════════════════════════════════════════
# APP INFO
# ═══════════════════════════════════════════════════════════════════════════════

func getInstalledDepots(_app_id: int) -> Array:
	return []

func getAvailableGameLanguages() -> String:
	return "english"

func getAppOwner() -> int:
	return 0

func getAppBuildId() -> int:
	return 1  # Local build

func getCurrentGameLanguage() -> String:
	return "english"

func getAppInstallDir(_app_id: int) -> Dictionary:
	return {"directory": "", "install_size": 0}

func isSteamRunningOnSteamDeck() -> bool:
	return false

func isSteamRunningInVR() -> bool:
	return false

func loggedOn() -> bool:
	return false  # Not logged into Steam

func isSubscribed() -> bool:
	return true  # Assume user owns the game (they're running it!)

func getLaunchCommandLine() -> String:
	return ""

func getSteamID() -> int:
	return 0

func getPersonaName() -> String:
	return "Linux Player"

func getSteamUILanguage() -> String:
	return "english"

# ═══════════════════════════════════════════════════════════════════════════════
# ACHIEVEMENTS & STATS
# ═══════════════════════════════════════════════════════════════════════════════

var _local_achievements: Dictionary = {}
var _local_stats: Dictionary = {}

func getAchievement(achievement_name: String) -> Dictionary:
	return {
		"ret": _local_achievements.has(achievement_name),
		"achieved": _local_achievements.get(achievement_name, false)
	}

func setAchievement(achievement_name: String) -> bool:
	print("[Steam Stub] Achievement unlocked (local only): %s" % achievement_name)
	_local_achievements[achievement_name] = true
	return true

func clearAchievement(achievement_name: String) -> bool:
	print("[Steam Stub] Achievement cleared (local only): %s" % achievement_name)
	_local_achievements[achievement_name] = false
	return true

func getStatInt(stat_name: String) -> int:
	return _local_stats.get(stat_name, 0)

func setStatInt(stat_name: String, value: int) -> bool:
	print("[Steam Stub] Stat set (local only): %s = %d" % [stat_name, value])
	_local_stats[stat_name] = value
	return true

func storeStats() -> bool:
	print("[Steam Stub] Stats stored locally (no Steam cloud)")
	return true

# ═══════════════════════════════════════════════════════════════════════════════
# SAVE/LOAD LOCAL PROGRESS
# ═══════════════════════════════════════════════════════════════════════════════

func _ready():
	_load_local_progress()

func _load_local_progress():
	var config = ConfigFile.new()
	var err = config.load("user://steam_stub_progress.cfg")
	if err == OK:
		for key in config.get_section_keys("achievements"):
			_local_achievements[key] = config.get_value("achievements", key, false)
		for key in config.get_section_keys("stats"):
			_local_stats[key] = config.get_value("stats", key, 0)
		print("[Steam Stub] Loaded local progress")

func save_local_progress():
	var config = ConfigFile.new()
	for key in _local_achievements.keys():
		config.set_value("achievements", key, _local_achievements[key])
	for key in _local_stats.keys():
		config.set_value("stats", key, _local_stats[key])
	config.save("user://steam_stub_progress.cfg")
	print("[Steam Stub] Saved local progress")

