extends Node
## Global singleton for Juno Leaderboard functionality
##
## Provides easy-to-use methods for submitting scores and fetching leaderboards
## from Juno.build datastores on the Internet Computer.
##
## Example usage:
## [codeblock]
## # Initialize with your satellite ID
## JunoLeaderboard.initialize("your-satellite-id", "highscores")
##
## # For writes, login first
## JunoLeaderboard.login()
## # ... after authentication ...
##
## # Submit a score
## await JunoLeaderboard.submit_score("PlayerName", 1000)
##
## # Fetch top scores
## var scores = await JunoLeaderboard.get_top_scores(10)
## for entry in scores:
##     print("%s: %d" % [entry.player_name, entry.score])
## [/codeblock]

## Emitted when login process is initiated
signal login_initiated

## Emitted when login is completed
## @param success: Whether login was successful
signal login_completed(success: bool)

## Emitted when a score submission completes
## @param success: Whether submission was successful
signal score_submitted(success: bool)

## Emitted when leaderboard scores are fetched
## @param scores: Array of score dictionaries with keys: player_name, score, timestamp
signal scores_fetched(scores: Array)

# Internal reference to the Rust GDExtension node
var _juno_native: Node = null

# Cached settings
var _satellite_id: String = ""
var _collection_name: String = "highscores"


func _ready() -> void:
	# Create the native JunoLeaderboard node
	_juno_native = JunoLeaderboard.new()
	add_child(_juno_native)

	# Connect signals from native implementation
	_juno_native.login_initiated.connect(_on_login_initiated)
	_juno_native.login_completed.connect(_on_login_completed)
	_juno_native.score_submitted.connect(_on_score_submitted)
	_juno_native.scores_fetched.connect(_on_scores_fetched)

	# Auto-initialize from ProjectSettings if available
	if ProjectSettings.has_setting("juno_leaderboard/satellite_id"):
		_satellite_id = ProjectSettings.get_setting("juno_leaderboard/satellite_id", "")
		_collection_name = ProjectSettings.get_setting("juno_leaderboard/collection_name", "highscores")

		if _satellite_id != "":
			initialize(_satellite_id, _collection_name)


## Initialize the Juno Leaderboard with your satellite configuration
## @param satellite_id: Your Juno satellite ID (Principal)
## @param collection_name: Name of the datastore collection (default: "highscores")
func initialize(satellite_id: String, collection_name: String = "highscores") -> void:
	_satellite_id = satellite_id
	_collection_name = collection_name

	if _juno_native:
		_juno_native.initialize(satellite_id, collection_name)
		print("JunoLeaderboard initialized with satellite: ", satellite_id)
	else:
		push_error("JunoLeaderboard native extension not loaded")


## Open browser for Internet Identity authentication
## Required before submitting scores. After login completes in browser,
## call set_delegation() with the delegation string.
func login() -> void:
	if _juno_native:
		_juno_native.login()
	else:
		push_error("JunoLeaderboard not initialized")


## Set the delegation identity after Internet Identity login
## @param delegation_base64: Base64-encoded delegation chain from Internet Identity
## @return: True if delegation was set successfully
func set_delegation(delegation_base64: String) -> bool:
	if _juno_native:
		return _juno_native.set_delegation(delegation_base64)
	else:
		push_error("JunoLeaderboard not initialized")
		return false


## Submit a score to the leaderboard
## Requires prior authentication via login() and set_delegation()
## @param player_name: Name of the player
## @param score: Score value (higher is better)
func submit_score(player_name: String, score: int) -> void:
	if _juno_native:
		_juno_native.submit_score(player_name, score)
	else:
		push_error("JunoLeaderboard not initialized")
		score_submitted.emit(false)


## Fetch top scores from the leaderboard
## Uses anonymous query, no authentication required
## @param limit: Maximum number of scores to return (default: 10)
func get_top_scores(limit: int = 10) -> void:
	if _juno_native:
		_juno_native.get_top_scores(limit)
	else:
		push_error("JunoLeaderboard not initialized")
		scores_fetched.emit([])


## Test connection to the satellite (blocking)
## Useful for debugging and editor tools
## @return: True if connection successful
func test_connection() -> bool:
	if _juno_native:
		return _juno_native.test_connection()
	else:
		push_error("JunoLeaderboard not initialized")
		return false


## Insert a test score (for development/testing)
## @return: True if successful
func insert_test_score() -> bool:
	if _juno_native:
		return _juno_native.insert_test_score()
	else:
		push_error("JunoLeaderboard not initialized")
		return false


## Get current satellite ID
func get_satellite_id() -> String:
	if _juno_native:
		return _juno_native.get_satellite_id()
	return _satellite_id


## Get current collection name
func get_collection_name() -> String:
	if _juno_native:
		return _juno_native.get_collection_name()
	return _collection_name


# Signal handlers
func _on_login_initiated() -> void:
	login_initiated.emit()


func _on_login_completed(success: bool) -> void:
	login_completed.emit(success)


func _on_score_submitted(success: bool) -> void:
	score_submitted.emit(success)


func _on_scores_fetched(scores: Array) -> void:
	scores_fetched.emit(scores)
