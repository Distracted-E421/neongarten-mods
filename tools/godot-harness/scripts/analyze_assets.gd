#!/usr/bin/env godot -s
extends SceneTree

## Headless Asset Analyzer
## 
## Run from command line: godot --headless -s analyze_assets.gd
## Or via godot-cmds: godot-cmds query "$(cat analyze_assets.gd)"
##
## Outputs JSON to stdout for easy parsing.

func _init():
	var results = {
		"prologue_assets": [],
		"modern_assets": [],
		"orphaned_assets": [],
		"statistics": {}
	}
	
	# Get all files
	var all_files = get_all_files("res://")
	var referenced = get_all_references(all_files)
	
	for file in all_files:
		if file.begins_with("res://.godot"):
			continue
		if file.ends_with(".import"):
			continue
		
		var filename = file.get_file().to_lower()
		var is_orphan = not file in referenced
		var is_prologue = _is_prologue_asset(filename)
		
		if is_orphan:
			results["orphaned_assets"].append(file)
		
		if is_prologue:
			results["prologue_assets"].append({
				"path": file,
				"orphaned": is_orphan
			})
		else:
			# Only track modern assets that are textures/models
			var ext = file.get_extension().to_lower()
			if ext in ["png", "glb", "tscn", "tres"]:
				results["modern_assets"].append(file)
	
	# Statistics
	results["statistics"] = {
		"total_files": all_files.size(),
		"prologue_count": results["prologue_assets"].size(),
		"orphaned_count": results["orphaned_assets"].size(),
		"modern_count": results["modern_assets"].size()
	}
	
	# Output JSON
	print(JSON.stringify(results))
	
	quit()

func get_all_files(path: String) -> Array:
	var files = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var full_path = path.path_join(file_name)
			if dir.current_is_dir():
				if not file_name.begins_with("."):
					files.append_array(get_all_files(full_path))
			else:
				files.append(full_path)
			file_name = dir.get_next()
	return files

func get_all_references(all_files: Array) -> Dictionary:
	var referenced = {}
	var scannable = ["tscn", "tres", "gd", "gdshader"]
	
	for file in all_files:
		var ext = file.get_extension()
		if ext in scannable:
			referenced[file] = true
			var fa = FileAccess.open(file, FileAccess.READ)
			if fa:
				var content = fa.get_as_text()
				fa.close()
				var regex = RegEx.new()
				regex.compile("res://[\\w/\\-\\.]+")
				var matches = regex.search_all(content)
				for m in matches:
					referenced[m.get_string()] = true
	
	return referenced

func _is_prologue_asset(filename: String) -> bool:
	var patterns = ["lame_", "prologue_", "old_", "test_", "placeholder_"]
	for pattern in patterns:
		if filename.begins_with(pattern):
			return true
	return false

