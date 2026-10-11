extends Node
## Optional Firebase REST integration. No real public score submission from the client.
## Online data is unavailable until Firebase is explicitly configured.
signal ranking_loaded(entries: Array)
signal ranking_failed(reason: String)

var config: Dictionary = {}
var busy: bool = false

func _ready() -> void:
    var path := "res://config/online_services.json"
    if FileAccess.file_exists(path):
        var result = JSON.parse_string(FileAccess.get_file_as_string(path))
        if typeof(result) == TYPE_DICTIONARY:
            config = result

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
