extends Node

# Persistent game data
var score: int = 0
var high_score: int = 0
var player_name: String = ""
var scores: Array = []
var game_id: String = "aim_blast_game" # unique game id - change if needed

signal score_changed(new_score: int)
signal high_score_changed(new_high: int)

func _ready():
	# Initialize displays to 0 as required (other scenes will set labels immediately too)
	score = 0
	high_score = 0
	player_name = ""
	# Request load via Applaa API
	_init_message_listener()
	_load_game_data()

func add_score(points: int):
	score += points
	emit_signal("score_changed", score)
	_update_high_score_if_needed()

func reset_score():
	score = 0
	emit_signal("score_changed", score)

func _update_high_score_if_needed():
	if score > high_score:
		high_score = score
		emit_signal("high_score_changed", high_score)

# Save score and player name via JavaScriptBridge (Godot HTML exports)
func save_score_to_storage(name: String, final_score: int):
	player_name = name
	# Use JavaScriptBridge.eval if available (HTML export), otherwise send no-op
	if Engine.has_singleton("JavaScriptBridge"):
		var js = "window.parent.postMessage({ type: 'applaa-game-save-score', gameId: '%s', playerName: '%s', score: %d }, '*');" % [game_id, name, final_score]
		JavaScriptBridge.eval(js)
	else:
		# Desktop fallback: nothing (or write to file in a fuller implementation)
		pass

func _load_game_data():
	if Engine.has_singleton("JavaScriptBridge"):
		var js = "window.parent.postMessage({ type: 'applaa-game-load-data', gameId: '%s' }, '*');" % game_id
		JavaScriptBridge.eval(js)
	# No immediate return; data will be handled by message listener

# Setup a postMessage listener for when running in HTML wrapper via JavaScriptBridge
func _init_message_listener():
	if Engine.has_singleton("JavaScriptBridge"):
		# Install a small JS listener that forwards applaa-game-data-loaded to Godot via global call
		var setup = """
		(function(){
			if(window._godot_applaa_listener_installed) return;
			window._godot_applaa_listener_installed = true;
			window.addEventListener('message', function(event){
				try {
					if(!event.data) return;
					if(event.data.type === 'applaa-game-data-loaded'){
						// Forward as a global function call recognized by Godot HTML export
						if(typeof App !== 'undefined' && App.call_native) {
							App.call_native('applaa_game_data_loaded', JSON.stringify(event.data.data));
						} else if(typeof Godot !== 'undefined' && Godot.nativeCall) {
							Godot.nativeCall('applaa_game_data_loaded', JSON.stringify(event.data.data));
						} else {
							// fallback: create global var for polling
							window.__APPLAA_GAME_DATA = event.data.data;
						}
					}
				} catch(e){}
			}, false);
		})();
		"""
		JavaScriptBridge.eval(setup)

# This function can be called via JavaScriptBridge from the HTML wrapper when data arrives.
# The HTML wrapper must call Godot's callable 'applaa_game_data_loaded' if JavaScriptBridge forwarding isn't available.
func applaa_game_data_loaded(json_str: String) -> void:
	var data = {}
	if json_str != "":
		data = JSON.parse(json_str).result
	if typeof(data) == TYPE_DICTIONARY:
		high_score = int(data.get("highScore", 0))
		player_name = str(data.get("lastPlayerName", ""))
		scores = data.get("scores", [])
		emit_signal("high_score_changed", high_score)
		# No need to emit score_changed here