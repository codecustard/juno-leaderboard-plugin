@tool
extends VBoxContainer

# Signals for plugin to handle
signal open_console_pressed
signal test_connection_pressed
signal insert_test_score_pressed
signal fetch_leaderboard_pressed
signal satellite_id_changed(new_id: String)
signal collection_name_changed(new_name: String)

# UI References
@onready var satellite_id_input: LineEdit = %SatelliteIdInput
@onready var collection_name_input: LineEdit = %CollectionNameInput
@onready var open_console_button: Button = %OpenConsoleButton
@onready var test_connection_button: Button = %TestConnectionButton
@onready var insert_test_button: Button = %InsertTestButton
@onready var fetch_leaderboard_button: Button = %FetchLeaderboardButton
@onready var status_label: Label = %StatusLabel
@onready var leaderboard_list: ItemList = %LeaderboardList


func _ready() -> void:
	# Connect button signals
	open_console_button.pressed.connect(_on_open_console_pressed)
	test_connection_button.pressed.connect(_on_test_connection_pressed)
	insert_test_button.pressed.connect(_on_insert_test_pressed)
	fetch_leaderboard_button.pressed.connect(_on_fetch_leaderboard_pressed)

	# Connect input signals
	satellite_id_input.text_changed.connect(_on_satellite_id_changed)
	collection_name_input.text_changed.connect(_on_collection_name_changed)


func _on_open_console_pressed() -> void:
	open_console_pressed.emit()


func _on_test_connection_pressed() -> void:
	test_connection_pressed.emit()


func _on_insert_test_pressed() -> void:
	insert_test_score_pressed.emit()


func _on_fetch_leaderboard_pressed() -> void:
	fetch_leaderboard_pressed.emit()


func _on_satellite_id_changed(new_text: String) -> void:
	satellite_id_changed.emit(new_text)


func _on_collection_name_changed(new_text: String) -> void:
	collection_name_changed.emit(new_text)


func set_satellite_id(id: String) -> void:
	if satellite_id_input:
		satellite_id_input.text = id


func set_collection_name(name: String) -> void:
	if collection_name_input:
		collection_name_input.text = name


func show_status(message: String, success: bool) -> void:
	if status_label:
		if success:
			status_label.text = "✓ " + message
			status_label.add_theme_color_override("font_color", Color.GREEN)
		else:
			status_label.text = "✗ " + message
			status_label.add_theme_color_override("font_color", Color.RED)


func display_leaderboard(scores: Array) -> void:
	if not leaderboard_list:
		return

	leaderboard_list.clear()

	if scores.is_empty():
		leaderboard_list.add_item("(No scores yet)")
		return

	for i in scores.size():
		var entry = scores[i]
		var rank = i + 1
		var text = "%d. %s - %d pts" % [rank, entry.player_name, entry.score]
		leaderboard_list.add_item(text)
