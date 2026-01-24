@tool
extends EditorScript

## EditorScript: Find Orphaned Assets
## 
## Scans the project for assets (textures, models, scenes) that are not
## referenced by any resource or scene file.
##
## Run with: File > Run (Ctrl+Shift+X) in the Godot editor

func _run():
	print("=== Orphaned Asset Finder ===\n")
	
	var all_files = _get_all_files("res://")
	var referenced_files = _get_all_references()
	
	print("Total files found: ", all_files.size())
	print("Referenced files: ", referenced_files.size())
	print("")
	
	# Find orphans
	var orphans = {
		"textures": [],
		"models": [],
		"scenes": [],
		"resources": [],
		"other": []
	}
	
	for file in all_files:
		# Skip import files and .godot directory
		if file.ends_with(".import") or file.begins_with("res://.godot"):
			continue
		
		# Skip this script
		if file.ends_with("find_orphaned_assets.gd"):
			continue
		
		# Check if orphaned
		if not file in referenced_files:
			var category = _categorize_file(file)
			orphans[category].append(file)
	
	# Output results
	print("=== ORPHANED ASSETS ===\n")
	
	for category in orphans.keys():
		if orphans[category].size() > 0:
			print("--- ", category.to_upper(), " (", orphans[category].size(), ") ---")
			for file in orphans[category]:
				print("  ", file)
			print("")
	
	# Summary
	var total_orphans = 0
	for category in orphans.keys():
		total_orphans += orphans[category].size()
	
	print("\n=== SUMMARY ===")
	print("Total orphaned: ", total_orphans)
	print("  Textures: ", orphans["textures"].size())
	print("  Models: ", orphans["models"].size())
	print("  Scenes: ", orphans["scenes"].size())
	print("  Resources: ", orphans["resources"].size())
	print("  Other: ", orphans["other"].size())
	
	# Output JSON for machine parsing
	print("\n=== JSON OUTPUT ===")
	print(JSON.stringify({"orphans": orphans, "total": total_orphans}))

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

func _get_all_references() -> Dictionary:
	"""Scan all resource files to find what they reference."""
	var referenced = {}
	var scannable_extensions = ["tscn", "tres", "gd", "gdshader"]
	var all_files = _get_all_files("res://")
	
	for file in all_files:
		var ext = file.get_extension()
		if ext in scannable_extensions:
			# Always mark the file itself as "referenced" (it exists)
			referenced[file] = true
			
			# Read and scan for references
			var fa = FileAccess.open(file, FileAccess.READ)
			if fa:
				var content = fa.get_as_text()
				fa.close()
				
				# Find all res:// paths
				var regex = RegEx.new()
				regex.compile("res://[\\w/\\-\\.]+")
				var matches = regex.search_all(content)
				for m in matches:
					var ref_path = m.get_string()
					# Handle uid:// references by marking the source
					referenced[ref_path] = true
	
	return referenced

func _categorize_file(file: String) -> String:
	var ext = file.get_extension().to_lower()
	match ext:
		"png", "jpg", "jpeg", "webp", "svg", "bmp", "tga", "dds", "hdr", "exr":
			return "textures"
		"glb", "gltf", "obj", "fbx", "dae", "blend":
			return "models"
		"tscn":
			return "scenes"
		"tres", "res":
			return "resources"
		_:
			return "other"

