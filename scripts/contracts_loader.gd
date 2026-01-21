extends Node
## Загрузчик контрактов и ассетов (Autoload: ContractsLoader)

# Путь к contracts (настраивается)
var base_path: String = "../contracts/contracts/public"

# Кэш загруженных ассетов
var _asset_cache: Dictionary = {}

func _ready() -> void:
	_load_local_config()
	print("[ContractsLoader] Base path: ", base_path)

## Загрузить локальный конфиг путей
func _load_local_config() -> void:
	var config_path = "res://config/local_paths.json"
	if FileAccess.file_exists(config_path):
		var file = FileAccess.open(config_path, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK:
				var config = json.get_data()
				if config.has("contracts_path"):
					base_path = config.contracts_path
					print("[ContractsLoader] Using custom path: ", base_path)

## Загрузить JSON файл
func load_json(relative_path: String) -> Variant:
	var full_path = base_path + "/" + relative_path
	
	if not FileAccess.file_exists(full_path):
		push_error("[ContractsLoader] File not found: " + full_path)
		return null
	
	var file = FileAccess.open(full_path, FileAccess.READ)
	if not file:
		push_error("[ContractsLoader] Cannot open: " + full_path)
		return null
	
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error != OK:
		push_error("[ContractsLoader] JSON parse error in " + full_path + ": " + json.get_error_message())
		return null
	
	print("[ContractsLoader] Loaded: ", relative_path)
	return json.get_data()

## Загрузить layout контракт
func load_layout(name: String = "visitor") -> Dictionary:
	var data = load_json("ui/layout/" + name + ".layout.json")
	return data if data else {}

## Загрузить interaction контракт
func load_interaction(name: String = "visitor") -> Array:
	var data = load_json("ui/interaction/" + name + ".interaction.json")
	return data if data is Array else []

## Загрузить bindings контракт
func load_bindings(name: String = "visitor") -> Dictionary:
	var data = load_json("ui/bindings/" + name + ".bindings.json")
	return data if data else {}

## Загрузить route
func load_route(category: String, name: String) -> Dictionary:
	var data = load_json("routes/" + category + "/" + name + ".json")
	return data if data else {}

## Загрузить Universe Graph (канонический граф из extended-mind)
func load_universe_graph() -> Dictionary:
	var data = load_json("graph/universe.json")
	return data if data else {"nodes": [], "edges": []}

## Загрузить session
func load_session(category: String, name: String) -> Dictionary:
	var data = load_json("sessions/" + category + "/" + name + ".json")
	return data if data else {}

## Загрузить изображение (фон, иконка)
func load_image(relative_path: String) -> Texture2D:
	var full_path = base_path + "/" + relative_path
	
	# Проверить кэш
	if _asset_cache.has(full_path):
		return _asset_cache[full_path]
	
	if not FileAccess.file_exists(full_path):
		push_warning("[ContractsLoader] Image not found: " + full_path)
		return null
	
	var image = Image.load_from_file(full_path)
	if image:
		var texture = ImageTexture.create_from_image(image)
		_asset_cache[full_path] = texture
		print("[ContractsLoader] Loaded image: ", relative_path)
		return texture
	
	return null

## Загрузить текстовый файл (Markdown)
func load_text(relative_path: String) -> String:
	var full_path = base_path + "/" + relative_path
	
	if not FileAccess.file_exists(full_path):
		push_warning("[ContractsLoader] Text not found: " + full_path)
		return ""
	
	var file = FileAccess.open(full_path, FileAccess.READ)
	if file:
		return file.get_as_text()
	return ""

## Получить путь к ассету
func get_asset_path(asset_type: String, asset_name: String) -> String:
	match asset_type:
		"background":
			return "assets/ui/backgrounds/" + asset_name
		"frame":
			return "assets/ui/frames/" + asset_name
		"icon":
			return "assets/icons/" + asset_name
		"avatar":
			return "assets/avatars/" + asset_name
		"logo":
			return "assets/logos/" + asset_name
		"image":
			return "assets/images/" + asset_name
		_:
			return "assets/" + asset_name

## Загрузить ассет по типу и имени
func load_asset(asset_type: String, asset_name: String) -> Texture2D:
	var path = get_asset_path(asset_type, asset_name)
	return load_image(path)

## Проверить существование файла
func file_exists(relative_path: String) -> bool:
	return FileAccess.file_exists(base_path + "/" + relative_path)
