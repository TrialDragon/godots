class LocalEditors extends RefCounted:
	const dir = preload("res://src/extensions/dir.gd")
	const dict = preload("res://src/extensions/dict.gd")
	
	signal editor_removed(editor_path)
	signal editor_name_changed(editor_path)
	
	var _cfg_path
	var _cfg = ConfigFile.new()
	var _editors = {}
	
	func _init(cfg_path) -> void:
		_cfg_path = cfg_path
	
	func add(name, editor_path) -> LocalEditor:
		var editor = LocalEditor.new(
			ConfigFileSection.new(editor_path, _cfg),
		)
		_connect_name_changed(editor)
		editor.name = name
		editor.favorite = false
		_editors[editor_path] = editor
		return editor
	
	func all() -> Array[LocalEditor]:
		var result: Array[LocalEditor] = []
		for x in _editors.values():
			result.append(x)
		return result
	
	func retrieve(editor_path) -> LocalEditor:
		return _editors[editor_path]
	
	func has(editor_path) -> bool:
		return _editors.has(editor_path)
	
	func editor_is_valid(editor_path):
		return has(editor_path) and dir.path_is_valid(editor_path)
	
	func erase(editor_path) -> void:
		var editor = retrieve(editor_path)
		editor.free()
		_editors.erase(editor_path)
		_cfg.erase_section(editor_path)
		editor_removed.emit(editor_path)
	
	func as_option_button_items():
		return all().map(func(x: LocalEditor): return {
			'label': x.name,
			'path': x.path
		})
	
	func load() -> Error:
		dict.clear_and_free(_editors)
		var err = _cfg.load(_cfg_path)
		if err: return err
		for section in _cfg.get_sections():
			var editor = LocalEditor.new(
				ConfigFileSection.new(section, _cfg)
			)
			_connect_name_changed(editor)
			_editors[section] = editor
		return Error.OK
	
	func save() -> Error:
		return _cfg.save(_cfg_path)
	
	func _connect_name_changed(editor: LocalEditor):
		editor.name_changed.connect(func(_new_name): 
			editor_name_changed.emit(editor.path)
		)


class LocalEditor extends Object:
	const dir = preload("res://src/extensions/dir.gd")
	
	signal name_changed(new_name)
	
	var path:
		get: return _section.name
	
	var name:
		get: return _section.get_value("name", "")
		set(value): 
			_section.set_value("name", value)
			name_changed.emit(value)

	var favorite:
		get: return _section.get_value("favorite", false)
		set(value): _section.set_value("favorite", value)
	
	var is_value:
		get: return dir.path_is_valid(path)
	
	var _section: ConfigFileSection
	
	func _init(section: ConfigFileSection) -> void:
		self._section = section