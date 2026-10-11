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

func _ready() -> void:
	var path := "res://config/online_services.json"
	if FileAccess.file_exists(path):
		var result = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(result) == TYPE_DICTIONARY:
			config = result

func is_authenticated() -> bool:
	return not id_token.is_empty() and not user_id.is_empty()

func _request_auth(endpoint: String, payload: Dictionary) -> void:
	if auth_busy:
		auth_failure.emit("Connexion déjà en cours")
		return
	var key := str(config.get("firebase", {}).get("api_key", ""))
	if key.is_empty():
		auth_failure.emit("Configuration Firebase absente")
		return
	auth_busy = true
	var req := HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(_on_auth_result.bind(req))
	var url := "https://identitytoolkit.googleapis.com/v1/accounts:%s?key=%s" % [endpoint, key.uri_encode()]
	var result := req.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(payload))
	if result != OK:
		auth_busy = false
		req.queue_free()
		auth_failure.emit("Connexion réseau impossible (%d)" % result)

func login_anonymous() -> void:
	_request_auth("signUp", {"returnSecureToken":true})

func login_email(email: String, password: String) -> void:
	_request_auth("signInWithPassword", {"email":email.strip_edges(),"password":password,"returnSecureToken":true})

func register_email(email: String, password: String) -> void:
	if password.length() < 6:
		auth_failure.emit("Le mot de passe doit contenir au moins 6 caractères")
		return
	_request_auth("signUp", {"email":email.strip_edges(),"password":password,"returnSecureToken":true})

func _on_auth_result(_result: int, http_code: int, _headers: PackedStringArray, body: PackedByteArray, req: HTTPRequest) -> void:
	auth_busy = false
	req.queue_free()
	var response = JSON.parse_string(body.get_string_from_utf8())
	if typeof(response) != TYPE_DICTIONARY:
		auth_failure.emit("Réponse Firebase invalide")
		return
	if http_code < 200 or http_code >= 300:
		var failure: Dictionary = response.get("error", {})
		var message := str(failure.get("message", "HTTP %d" % http_code))
		# Do not display untrusted server internals or sensitive details.
		if message in ["EMAIL_EXISTS", "INVALID_LOGIN_CREDENTIALS", "EMAIL_NOT_FOUND", "INVALID_PASSWORD"]:
			message = "Compte existant ou identifiants incorrects"
		auth_failure.emit(message.substr(0,100))
		return
	id_token = str(response.get("idToken", ""))
	user_id = str(response.get("localId", ""))
	user_email = str(response.get("email", ""))
	refresh_token = str(response.get("refreshToken", ""))
	if not is_authenticated():
		auth_failure.emit("Compte Firebase incomplet")
		return
	# Login is session-only: no sensitive tokens are written to the historical game save.
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
	if not board_id in ["global", "weekly", "monthly", "expert", "impossible", "daily", "marathon"]:
		ranking_failed.emit("Classement inconnu")
		return
	var fb: Dictionary = config.get("firebase", {})
	var project_id: String = str(fb.get("project_id", ""))
	var collection: String = str(config.get("leaderboards",{}).get("collection","public_leaderboards"))
	var url := "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/%s/%s/entries?pageSize=20" % [project_id.uri_encode(),collection.uri_encode(),board_id.uri_encode()]
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
