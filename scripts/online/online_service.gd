extends Node
## Optional Firebase REST integration. No real public score submission from the client.
## Online data is unavailable until Firebase is explicitly configured.
signal ranking_loaded(entries: Array)
signal ranking_failed(reason: String)
signal auth_success(user_id: String, email: String)
signal auth_failure(message: String)

var config: Dictionary = {}
var busy: bool = false
var auth_busy: bool = false
var user_id: String = ""
var id_token: String = ""
var user_email: String = ""
var refresh_token: String = ""
const TOKEN_PATH = "user://mystery_firebase_session.json"
const AUTH_TIMEOUT_SECONDS: float = 20.0
var _active_auth_request: HTTPRequest = null
var _auth_attempt: int = 0


func _ready() -> void:
	var path := "res://config/online_services.json"
	if FileAccess.file_exists(path):
		var result = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(result) == TYPE_DICTIONARY:
			config = result

func is_authenticated() -> bool:
	return not id_token.is_empty() and not user_id.is_empty()

func _finish_auth_request(req: HTTPRequest) -> bool:
	# A timed-out/abandoned request must not be able to update a new login.
	if req != _active_auth_request:
		if is_instance_valid(req):
			req.queue_free()
		return false
	_active_auth_request = null
	auth_busy = false
	if is_instance_valid(req):
		req.queue_free()
	return true

func _auth_timeout(req: HTTPRequest) -> void:
	if req != _active_auth_request:
		return
	_finish_auth_request(req)
	auth_failure.emit("Délai dépassé. Vérifie Internet et réessaie.")

func _request_auth(endpoint: String, payload: Dictionary) -> void:
	if auth_busy:
		auth_failure.emit("Connexion en cours : attends quelques secondes, puis réessaie.")
		return
	var key := str(config.get("firebase", {}).get("api_key", ""))
	if key.is_empty():
		auth_failure.emit("Configuration Firebase absente")
		return
	var req := HTTPRequest.new()
	req.timeout = AUTH_TIMEOUT_SECONDS
	add_child(req)
	_active_auth_request = req
	auth_busy = true
	req.request_completed.connect(_on_auth_result.bind(req))
	var url := "https://identitytoolkit.googleapis.com/v1/accounts:%s?key=%s" % [endpoint, key.uri_encode()]
	var result := req.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(payload))
	if result != OK:
		_finish_auth_request(req)
		auth_failure.emit("Connexion réseau impossible (%d)" % result)
		return
	# Safety net for platforms where HTTPRequest never invokes its completion callback.
	get_tree().create_timer(AUTH_TIMEOUT_SECONDS + 2.0).timeout.connect(_auth_timeout.bind(req))

func login_anonymous() -> void:
	_request_auth("signUp", {"returnSecureToken":true})

func login_email(email: String, password: String) -> void:
	_request_auth("signInWithPassword", {"email":email.strip_edges(),"password":password,"returnSecureToken":true})

func register_email(email: String, password: String) -> void:
	if password.length() < 6:
		auth_failure.emit("Le mot de passe doit contenir au moins 6 caractères")
		return
	_request_auth("signUp", {"email":email.strip_edges(),"password":password,"returnSecureToken":true})

func _on_auth_result(result: int, http_code: int, _headers: PackedStringArray, body: PackedByteArray, req: HTTPRequest) -> void:
	if not _finish_auth_request(req):
		return
	if result != HTTPRequest.RESULT_SUCCESS:
		auth_failure.emit("Erreur réseau Firebase (%d). Réessaie." % result)
		return
	var response = JSON.parse_string(body.get_string_from_utf8())
	if typeof(response) != TYPE_DICTIONARY:
		auth_failure.emit("Réponse Firebase invalide (HTTP %d)" % http_code)
		return
	if http_code < 200 or http_code >= 300:
		var failure = response.get("error", {})
		var message: String = "HTTP %d" % http_code
		if typeof(failure) == TYPE_DICTIONARY:
			message = str(failure.get("message", message))
		match message:
			"EMAIL_EXISTS": message = "Cette adresse possède déjà un compte. Utilise Se connecter."
			"INVALID_LOGIN_CREDENTIALS", "EMAIL_NOT_FOUND", "INVALID_PASSWORD": message = "E-mail ou mot de passe incorrect."
			"OPERATION_NOT_ALLOWED": message = "Cette méthode de connexion est désactivée sur Firebase."
			"TOO_MANY_ATTEMPTS_TRY_LATER": message = "Trop de tentatives. Réessaie plus tard."
			"WEAK_PASSWORD : Password should be at least 6 characters": message = "Mot de passe trop court."
			_: message = "Firebase : " + message.substr(0,90)
		auth_failure.emit(message)
		return
	id_token = str(response.get("idToken", ""))
	user_id = str(response.get("localId", ""))
	user_email = str(response.get("email", ""))
	refresh_token = str(response.get("refreshToken", ""))
	if not is_authenticated():
		auth_failure.emit("Compte Firebase incomplet")
		return
	auth_success.emit(user_id, user_email)

func logout() -> void:
	user_id = ""
	id_token = ""
	refresh_token = ""
	user_email = ""

func is_online_enabled() -> bool:
	var fb: Dictionary = config.get("firebase", {})
	var board: Dictionary = config.get("leaderboards", {})
	return bool(fb.get("enabled",false)) and bool(board.get("enabled",false)) and str(fb.get("project_id", "")) != ""

func fetch_public_ranking(board_id: String = "global") -> void:
	if busy:
		ranking_failed.emit("Requête déjà en cours")
		return
	if not is_online_enabled():
		ranking_failed.emit("Classement mondial en attente de configuration Firebase")
		return
	# Query is restricted to publicly-readable, server-written score documents.
	var resolved_board: String = board_id
	if board_id == "weekly":
		# ISO-style Monday 00:00 UTC: identical to backend/functions/scoring.js.
		resolved_board = "weekly_%d" % int(floor((Time.get_unix_time_from_system() + 259200.0) / 604800.0))
	elif board_id == "monthly":
		var utc = Time.get_datetime_dict_from_system(true)
		resolved_board = "monthly_%04d-%02d" % [int(utc["year"]), int(utc["month"])]
	var static_boards = ["global", "expert", "impossible", "daily", "marathon"]
	var ok_board = resolved_board in static_boards or resolved_board.begins_with("weekly_") or resolved_board.begins_with("monthly_") or resolved_board.begins_with("country_") or resolved_board.begins_with("case_")
	if not ok_board:
		ranking_failed.emit("Classement inconnu")
		return
	var fb: Dictionary = config.get("firebase", {})
	var project_id: String = str(fb.get("project_id", ""))
	var collection: String = str(config.get("leaderboards",{}).get("collection","public_leaderboards"))
	var url := "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/%s/%s/entries?pageSize=20" % [project_id.uri_encode(),collection.uri_encode(),resolved_board.uri_encode()]
	var req := HTTPRequest.new()
	add_child(req)
	busy = true
	req.request_completed.connect(_on_ranking_result.bind(req))
	var code := req.request(url)
	if code != OK:
		busy = false
		req.queue_free()
		ranking_failed.emit("Réseau indisponible (code %d)" % code)

func _on_ranking_result(_result: int, http_code: int, _headers: PackedStringArray, body: PackedByteArray, req: HTTPRequest) -> void:
	busy = false
	req.queue_free()
	if http_code != 200:
		ranking_failed.emit("Classement indisponible (HTTP %d)" % http_code)
		return
	var obj = JSON.parse_string(body.get_string_from_utf8())
	if typeof(obj) != TYPE_DICTIONARY:
		ranking_failed.emit("Réponse serveur invalide")
		return
	var entries: Array = []
	for doc in obj.get("documents", []):
		if typeof(doc) != TYPE_DICTIONARY:
			continue
		var f: Dictionary = doc.get("fields", {})
		var name_text := str(f.get("display_name", {}).get("stringValue", "Détective")).substr(0, 20)
		var score: int = maxi(0, int(f.get("score", {}).get("integerValue", "0")))
		entries.append({"name": name_text, "score":score})
	entries.sort_custom(func(a,b): return a["score"] > b["score"])
	ranking_loaded.emit(entries)
