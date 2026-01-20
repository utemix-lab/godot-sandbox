extends Node
## Парсер Markdown → BBCode для RichTextLabel (Autoload: MarkdownParser)

## Конвертировать Markdown в BBCode
func to_bbcode(markdown: String) -> String:
	var result = markdown
	
	# Заголовки
	result = _parse_headers(result)
	
	# Жирный текст **text** или __text__
	var bold_regex = RegEx.new()
	bold_regex.compile("\\*\\*(.+?)\\*\\*|__(.+?)__")
	result = bold_regex.sub(result, "[b]$1$2[/b]", true)
	
	# Курсив *text* или _text_ (но не внутри слов)
	var italic_regex = RegEx.new()
	italic_regex.compile("(?<![\\w\\*])\\*([^\\*]+?)\\*(?![\\w\\*])|(?<![\\w_])_([^_]+?)_(?![\\w_])")
	result = italic_regex.sub(result, "[i]$1$2[/i]", true)
	
	# Зачёркнутый ~~text~~
	var strike_regex = RegEx.new()
	strike_regex.compile("~~(.+?)~~")
	result = strike_regex.sub(result, "[s]$1[/s]", true)
	
	# Код `code`
	var code_regex = RegEx.new()
	code_regex.compile("`([^`]+?)`")
	result = code_regex.sub(result, "[code]$1[/code]", true)
	
	# Ссылки [text](url)
	var link_regex = RegEx.new()
	link_regex.compile("\\[([^\\]]+?)\\]\\(([^\\)]+?)\\)")
	result = link_regex.sub(result, "[url=$2]$1[/url]", true)
	
	# Теги #tag
	var tag_regex = RegEx.new()
	tag_regex.compile("#([\\w\\-]+)")
	result = tag_regex.sub(result, "[color=#6366f1][url=tag:$1]#$1[/url][/color]", true)
	
	# Списки (простые)
	result = _parse_lists(result)
	
	# Горизонтальная линия ---
	result = result.replace("\n---\n", "\n[center]───────────────[/center]\n")
	
	# Цитаты > text
	result = _parse_quotes(result)
	
	return result

## Парсить заголовки
func _parse_headers(text: String) -> String:
	var lines = text.split("\n")
	var result = PackedStringArray()
	
	for line in lines:
		if line.begins_with("### "):
			result.append("[font_size=18][b]" + line.substr(4) + "[/b][/font_size]")
		elif line.begins_with("## "):
			result.append("[font_size=22][b]" + line.substr(3) + "[/b][/font_size]")
		elif line.begins_with("# "):
			result.append("[font_size=26][b]" + line.substr(2) + "[/b][/font_size]")
		else:
			result.append(line)
	
	return "\n".join(result)

## Парсить списки
func _parse_lists(text: String) -> String:
	var lines = text.split("\n")
	var result = PackedStringArray()
	
	for line in lines:
		var trimmed = line.strip_edges(true, false)
		if trimmed.begins_with("- ") or trimmed.begins_with("* "):
			result.append("  • " + trimmed.substr(2))
		elif trimmed.length() > 0 and trimmed[0].is_valid_int():
			var dot_pos = trimmed.find(". ")
			if dot_pos > 0 and dot_pos < 4:
				result.append("  " + trimmed)
		else:
			result.append(line)
	
	return "\n".join(result)

## Парсить цитаты
func _parse_quotes(text: String) -> String:
	var lines = text.split("\n")
	var result = PackedStringArray()
	
	for line in lines:
		if line.begins_with("> "):
			result.append("[indent][color=#9ca3af]│ " + line.substr(2) + "[/color][/indent]")
		else:
			result.append(line)
	
	return "\n".join(result)

## Простой текст без форматирования
func strip_markdown(markdown: String) -> String:
	var result = markdown
	
	# Убрать заголовки
	result = RegEx.create_from_string("^#{1,6}\\s+").sub(result, "", true)
	
	# Убрать форматирование
	result = result.replace("**", "").replace("__", "")
	result = result.replace("*", "").replace("_", "")
	result = result.replace("~~", "")
	result = result.replace("`", "")
	
	# Убрать ссылки, оставить текст
	var link_regex = RegEx.new()
	link_regex.compile("\\[([^\\]]+?)\\]\\([^\\)]+?\\)")
	result = link_regex.sub(result, "$1", true)
	
	return result
