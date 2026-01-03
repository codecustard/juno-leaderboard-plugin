@tool
extends EditorPlugin

var dock: Control
var juno_instance: Node

const SETTING_SATELLITE_ID = "juno_leaderboard/satellite_id"
const SETTING_COLLECTION_NAME = "juno_leaderboard/collection_name"

func _enter_tree() -> void:
	# Create dock UI
	dock = preload("res://addons/juno_leaderboard/dock_ui/juno_dock.tscn").instantiate()

	# Connect dock signals
	dock.connect("open_console_pressed", _on_open_console)
	dock.connect("test_connection_pressed", _on_test_connection)
	dock.connect("insert_test_score_pressed", _on_insert_test_score)
	dock.connect("fetch_leaderboard_pressed", _on_fetch_leaderboard)
	dock.connect("satellite_id_changed", _on_satellite_id_changed)
	dock.connect("collection_name_changed", _on_collection_name_changed)

	# Add dock to editor
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)

	# Load settings
	_load_settings()

	# Add autoload singleton
	add_autoload_singleton("Juno", "res://addons/juno_leaderboard/JunoLeaderboard.gd")

	print("Juno Leaderboard plugin enabled")


func _exit_tree() -> void:
	# Remove dock
	if dock:
		remove_control_from_docks(dock)
		dock.queue_free()

	# Clean up juno instance
	if juno_instance:
		juno_instance.queue_free()
		juno_instance = null

	# Remove autoload
	remove_autoload_singleton("Juno")

	print("Juno Leaderboard plugin disabled")


func _load_settings() -> void:
	# Initialize settings if they don't exist
	if not ProjectSettings.has_setting(SETTING_SATELLITE_ID):
		ProjectSettings.set_setting(SETTING_SATELLITE_ID, "")
		ProjectSettings.set_initial_value(SETTING_SATELLITE_ID, "")

	if not ProjectSettings.has_setting(SETTING_COLLECTION_NAME):
		ProjectSettings.set_setting(SETTING_COLLECTION_NAME, "highscores")
		ProjectSettings.set_initial_value(SETTING_COLLECTION_NAME, "highscores")

	# Save settings
	ProjectSettings.save()

	# Update dock UI
	if dock:
		dock.set_satellite_id(ProjectSettings.get_setting(SETTING_SATELLITE_ID))
		dock.set_collection_name(ProjectSettings.get_setting(SETTING_COLLECTION_NAME))


func _on_open_console() -> void:
	OS.shell_open("https://console.juno.build")


func _on_test_connection() -> void:
	var juno = _get_juno_instance()
	if not juno:
		dock.show_status("Failed to get JunoLeaderboard instance", false)
		return

	dock.show_status("Testing connection...", true)

	var success = juno.test_connection()

	if success:
		dock.show_status("Connection successful!", true)
	else:
		dock.show_status("Connection failed. Check satellite ID.", false)


func _on_insert_test_score() -> void:
	var juno = _get_juno_instance()
	if not juno:
		dock.show_status("Failed to get JunoLeaderboard instance", false)
		return

	dock.show_status("Inserting test score...", true)

	var success = juno.insert_test_score()

	if success:
		dock.show_status("Test score inserted!", true)
	else:
		dock.show_status("Failed to insert test score", false)


func _on_fetch_leaderboard() -> void:
	var juno = _get_juno_instance()
	if not juno:
		dock.show_status("Failed to get JunoLeaderboard instance", false)
		return

	dock.show_status("Fetching leaderboard from Juno...", true)

	# Use blocking version for editor (synchronous, returns immediately)
	var scores = juno.get_top_scores_blocking(10)

	if scores.is_empty():
		dock.display_leaderboard([])
		dock.show_status("Leaderboard is empty - no scores yet!", true)
	else:
		dock.display_leaderboard(scores)
		dock.show_status("Fetched %d scores from Juno" % scores.size(), true)


func _on_satellite_id_changed(new_id: String) -> void:
	ProjectSettings.set_setting(SETTING_SATELLITE_ID, new_id)
	ProjectSettings.save()

	# Reinitialize JunoLeaderboard
	var juno = _get_juno_instance()
	if juno:
		juno.initialize(new_id, ProjectSettings.get_setting(SETTING_COLLECTION_NAME))


func _on_collection_name_changed(new_name: String) -> void:
	ProjectSettings.set_setting(SETTING_COLLECTION_NAME, new_name)
	ProjectSettings.save()

	# Reinitialize JunoLeaderboard
	var juno = _get_juno_instance()
	if juno:
		juno.initialize(
			ProjectSettings.get_setting(SETTING_SATELLITE_ID),
			new_name
		)


func _get_juno_instance() -> Node:
	# In editor, we need to create a temporary instance of the native class
	# since autoload singletons don't work in editor tools
	if not juno_instance:
		# Create the native JunoLeaderboard class directly (from Rust GDExtension)
		juno_instance = JunoLeaderboard.new()

		# Initialize it with current settings
		var sat_id = ProjectSettings.get_setting(SETTING_SATELLITE_ID, "")
		var coll_name = ProjectSettings.get_setting(SETTING_COLLECTION_NAME, "highscores")
		if sat_id != "":
			juno_instance.initialize(sat_id, coll_name)

	return juno_instance
