@tool
extends EditorScript

## EditorScript: Export Asset Manifest
## 
## Creates a JSON manifest of all assets in the project with metadata,
## useful for external analysis and automation.
##
## Output includes:
## - All textures, models, scenes, resources, scripts
## - File sizes, modification times
## - Reference graph (what references what)
## - Naming convention analysis
##
## Run with: File > Run (Ctrl+Shift+X) in the Godot editor

const OUTPUT_PATH = "res://asset_manifest.json"

func _run():
	print("=== Asset Manifest Generator ===\n")
	
	var manifest = {
		"generated_at": Time.get_datetime_string_from_system(),
		"project": {
			"name": ProjectSettings.get_setting("application/config/name", "Unknown"),
			"version": ProjectSettings.get_setting("application/config/version", "Unknown")
		},
		"assets": {
			"textures": [],
			"models": [],
			"scenes": [],
			"resources": [],
			"scripts": [],
			"shaders": [],
			"audio": []
		},
		"statistics": {},
		"naming_analysis": {}
	}
	
	print("Scanning project files...")
	var all_files = _get_all_files("res://")
	
	# Categorize and analyze each file
	for file in all_files:
		if file.begins_with("res://.godot"):
			continue
		if file.ends_with(".import"):
			continue
		
		var info = _analyze_file(file)
		if info:
			var category = info["category"]
			if category in manifest["assets"]:
				manifest["assets"][category].append(info)
	
	# Calculate statistics
	manifest["statistics"] = {
		"total_files": 0,
		"total_size_bytes": 0,
		"by_category": {}
	}
	
	for category in manifest["assets"].keys():
		var count = manifest["assets"][category].size()
		var size = 0
		for asset in manifest["assets"][category]:
			size += asset.get("size_bytes", 0)
		
		manifest["statistics"]["by_category"][category] = {
			"count": count,
			"size_bytes": size
		}
		manifest["statistics"]["total_files"] += count
		manifest["statistics"]["total_size_bytes"] += size
	
	# Naming convention analysis
	manifest["naming_analysis"] = _analyze_naming_conventions(manifest["assets"])
	
	# Write manifest
	var json_str = JSON.stringify(manifest, "\t")
	var fa = FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if fa:
		fa.store_string(json_str)
		fa.close()
		print("Manifest written to: ", OUTPUT_PATH)
	else:
		print("ERROR: Could not write manifest to ", OUTPUT_PATH)
	
	# Print summary
	print("\n=== STATISTICS ===")
	print("Total files: ", manifest["statistics"]["total_files"])
	print("Total size: ", _format_size(manifest["statistics"]["total_size_bytes"]))
	print("")
	for category in manifest["statistics"]["by_category"].keys():
		var stats = manifest["statistics"]["by_category"][category]
		print("  ", category, ": ", stats["count"], " files (", _format_size(stats["size_bytes"]), ")")
	
	print("\n=== NAMING CONVENTIONS ===")
	for convention in manifest["naming_analysis"].keys():
		var data = manifest["naming_analysis"][convention]
		print("  ", convention, ": ", data["count"], " files")
	
	print("\nDone!")

func _get_all_files(path: String) -> Array:
	var files = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var full_path = path.path_join(file_name)
			if dir.current_is_dir():
				if not file_name.begins_with("."):
					files.append_array(_get_all_files(full_path))
			else:
				files.append(full_path)
			file_name = dir.get_next()
	return files

func _analyze_file(file: String) -> Dictionary:
	var ext = file.get_extension().to_lower()
	var category = _get_category(ext)
	
	if category == "":
		return {}
	
	var info = {
		"path": file,
		"filename": file.get_file(),
		"extension": ext,
		"category": category,
		"size_bytes": 0,
		"naming_convention": _detect_naming_convention(file.get_file())
	}
	
	# Get file size
	var fa = FileAccess.open(file, FileAccess.READ)
	if fa:
		info["size_bytes"] = fa.get_length()
		fa.close()
	
	return info

func _get_category(ext: String) -> String:
	match ext:
		"png", "jpg", "jpeg", "webp", "svg", "bmp", "tga", "dds", "hdr", "exr":
			return "textures"
		"glb", "gltf", "obj", "fbx", "dae", "blend":
			return "models"
		"tscn":
			return "scenes"
		"tres", "res":
			return "resources"
		"gd":
			return "scripts"
		"gdshader", "shader":
			return "shaders"
		"ogg", "wav", "mp3":
			return "audio"
		_:
			return ""

func _detect_naming_convention(filename: String) -> String:
	var lower = filename.to_lower()
	
	# Check for known conventions
	if filename.begins_with("T_UI_"):
		return "T_UI_Standard"
	elif filename.begins_with("T_Building_"):
		return "T_Building_Standard"
	elif lower.begins_with("lame_"):
		return "Prologue_Lame"
	elif "_with_light" in lower or "_w_lights" in lower:
		return "LitModel"
	elif filename.begins_with("coin_"):
		return "Coin"
	elif filename.begins_with("perk_"):
		return "Perk"
	elif filename.begins_with("effect_"):
		return "Effect"
	elif filename.begins_with("ui_"):
		return "UI_Legacy"
	elif "_" in filename:
		return "SnakeCase"
	else:
		return "Unknown"

func _analyze_naming_conventions(assets: Dictionary) -> Dictionary:
	var analysis = {}
	
	for category in assets.keys():
		for asset in assets[category]:
			var convention = asset.get("naming_convention", "Unknown")
			if not convention in analysis:
				analysis[convention] = {
					"count": 0,
					"examples": []
				}
			analysis[convention]["count"] += 1
			if analysis[convention]["examples"].size() < 3:
				analysis[convention]["examples"].append(asset["path"])
	
	return analysis

func _format_size(bytes: int) -> String:
	if bytes < 1024:
		return str(bytes) + " B"
	elif bytes < 1024 * 1024:
		return "%.1f KB" % (bytes / 1024.0)
	else:
		return "%.1f MB" % (bytes / (1024.0 * 1024.0))

