extends Control
## Example script showing how to use the Juno Leaderboard plugin
##
## This demonstrates:
## - Submitting scores
## - Fetching and displaying leaderboards
## - Handling authentication

@onready var player_name_input: LineEdit = $VBoxContainer/InputSection/PlayerNameInput
@onready var score_input: SpinBox = $VBoxContainer/InputSection/ScoreInput
@onready var submit_button: Button = $VBoxContainer/InputSection/SubmitButton
@onready var login_button: Button = $VBoxContainer/AuthSection/LoginButton
@onready var fetch_button: Button = $VBoxContainer/LeaderboardSection/FetchButton
@onready var leaderboard_list: ItemList = $VBoxContainer/LeaderboardSection/LeaderboardList
@onready var status_label: Label = $VBoxContainer/StatusLabel

var is_authenticated: bool = false


func _ready() -> void:
	# Connect UI signals
	login_button.pressed.connect(_on_login_pressed)
	submit_button.pressed.connect(_on_submit_pressed)
	fetch_button.pressed.connect(_on_fetch_pressed)

	# Connect Juno signals
	Juno.login_initiated.connect(_on_login_initiated)
	Juno.login_completed.connect(_on_login_completed)
	Juno.score_submitted.connect(_on_score_submitted)
	Juno.scores_fetched.connect(_on_scores_fetched)

	# Initialize plugin (satellite ID should be set in ProjectSettings via editor plugin)
	# But you can also initialize manually:
	# Juno.initialize("your-satellite-id-here", "highscores")

	update_ui_state()


func _on_login_pressed() -> void:
	update_status("Opening Internet Identity login...", Color.BLUE)
	Juno.login()


func _on_submit_pressed() -> void:
	var player_name = player_name_input.text.strip_edges()
	var score = int(score_input.value)

	if player_name.is_empty():
		update_status("Please enter a player name", Color.ORANGE)
		return

	if not is_authenticated:
		update_status("Submitting with anonymous agent (requires Write: Public permissions)...", Color.ORANGE)
	else:
		update_status("Submitting score...", Color.BLUE)

	Juno.submit_score(player_name, score)


func _on_fetch_pressed() -> void:
	update_status("Fetching leaderboard...", Color.BLUE)
	Juno.get_top_scores(10)


# Signal handlers
func _on_login_initiated() -> void:
	update_status("Login window opened. Complete authentication in browser.", Color.BLUE)
	login_button.disabled = true


func _on_login_completed(success: bool) -> void:
	if success:
		is_authenticated = true
		update_status("Login successful! You can now submit scores.", Color.GREEN)
	else:
		update_status("Login failed. Please try again.", Color.RED)
		login_button.disabled = false

	update_ui_state()


func _on_score_submitted(success: bool) -> void:
	if success:
		update_status("Score submitted successfully!", Color.GREEN)
		# Automatically refresh leaderboard
		Juno.get_top_scores(10)
	else:
		update_status("Failed to submit score. Check authentication.", Color.RED)


func _on_scores_fetched(scores: Array) -> void:
	leaderboard_list.clear()

	if scores.is_empty():
		leaderboard_list.add_item("No scores yet - be the first!")
		update_status("Leaderboard is empty", Color.ORANGE)
		return

	for i in scores.size():
		var entry = scores[i]
		var rank = i + 1
		var text = "%d. %s - %d pts" % [rank, entry.player_name, entry.score]

		# Add medal emoji for top 3
		if rank == 1:
			text = "🥇 " + text
		elif rank == 2:
			text = "🥈 " + text
		elif rank == 3:
			text = "🥉 " + text
		else:
			text = "   " + text

		leaderboard_list.add_item(text)

	update_status("Loaded %d scores" % scores.size(), Color.GREEN)


func update_status(message: String, color: Color) -> void:
	status_label.text = message
	status_label.add_theme_color_override("font_color", color)


func update_ui_state() -> void:
	# Allow submissions even without auth (for Write: Public collections)
	submit_button.disabled = false
	login_button.text = "Login with Internet Identity" if not is_authenticated else "✓ Logged In"
