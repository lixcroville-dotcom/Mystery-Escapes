extends Node
# V8 ranked sidecar. Completely optional, never changes local gameplay or save files.
# Production remains off while Cloud Functions/App Check are not deployed.
signal rank_status(message: String)
var settings: Dictionary = {}
var current_run_id: String = ""
var starting: bool = false
var posting: bool = false
var queue: Array = []
var eligible: bool = false
const REGION: String = "europe-west3"

func _ready() -> void:
	var cfg = JSON.parse_string(FileAccess.get_file_as_string("res://config/online_services.json"))
	if typeof(cfg) == TYPE_DICTIONARY:
		settings = cfg.get("leaderboards", {})

func can_submit() -> bool:
	return bool(settings.get("server_validation_deployed", false)) and OnlineService.is_authenticated()

func _endpoint(action: String) -> String:
	return "https://%s-mystery-escapes.cloudfunctions.net/%s" % [REGION, action]

func _call(action: String, payload: Dictionary, callback: Callable) -> void:
	var req := HTTPRequest.new()
	req.timeout = 18.0
	add_child(req)
	req.request_completed.connect(func(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray):
		var response = JSON.parse_string(body.get_string_from_utf8())
		req.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS or code < 200 or code >= 300 or typeof(response) != TYPE_DICTIONARY:
			callback.call({"error": "Serveur classé indisponible (%d)" % code})
			return
		callback.call(response.get("result", {}))
	)
	var headers: PackedStringArray = ["Content-Type: application/json", "Authorization: Bearer " + OnlineService.id_token]
	var start_code = req.request(_endpoint(action), headers, HTTPClient.METHOD_POST, JSON.stringify({"data":payload}))
	if start_code != OK:
		req.queue_free()
		callback.call({"error":"Réseau classé indisponible"})

func start_for_case(level_id: int, mode: String) -> void:
	current_run_id = ""
	starting = false
	posting = false
	queue.clear()
	eligible = can_submit() and mode in ["classic", "expert", "daily", "marathon"]
	if not eligible:
		return
	starting = true
	_call("startRankedRun", {"level_id":level_id,"mode":mode}, func(result: Dictionary):
		starting = false
		if result.has("error"):
			eligible = false
			rank_status.emit(str(result["error"]))
			return
		current_run_id = str(result.get("run_id", ""))
		_drain_queue()
	)

func solved_stage(stage: Dictionary, mistakes: int, hints: int, language: String) -> void:
	if not eligible:
		return
	# Server can't verify whether an offline paid hint was used. Do not place
	# those runs into the competitive table until a server hint event exists.
	if mistakes > 0 or hints > 0:
		eligible = false
		queue.clear()
		rank_status.emit("Partie locale conservée : classement non admissible avec erreur/indice")
		return
	var answer = stage.get("answer", stage.get("answer_en" if language == "en" else "answer_fr", ""))
	queue.append({"answer":answer,"language":language})
	_drain_queue()

func _drain_queue() -> void:
	if not eligible or posting or starting or current_run_id.is_empty() or queue.is_empty():
		return
	posting = true
	var payload: Dictionary = queue.pop_front()
	payload["run_id"] = current_run_id
	_call("submitRankedStage", payload, func(response: Dictionary):
		posting = false
		if response.has("error") or not bool(response.get("ok",false)):
			eligible = false
			queue.clear()
			rank_status.emit(str(response.get("error","Réponse classée rejetée")))
			return
		if bool(response.get("finished",false)):
			rank_status.emit("Score vérifié par le serveur : %d" % int(response.get("score",0)))
			current_run_id = ""
			eligible = false
			return
		_drain_queue()
	)

func sync_profile(display_name: String, country: String, visible: bool) -> void:
	if not can_submit():
		return
	_call("setPublicRankProfile", {"display_name":display_name, "country":country, "visible":visible}, func(response: Dictionary):
		if response.has("error"):
			rank_status.emit(str(response["error"]))
	)
