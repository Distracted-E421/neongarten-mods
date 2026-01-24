@tool
extends EditorScript

## EditorScript: Identify Prologue Assets
## 
## Finds assets from the "Neongarten Prologue" that don't match the 
## main game's art style conventions.
##
## Prologue asset indicators:
## - Filename patterns: lame_*, prologue_*, old_*
## - Missing standardized naming (T_UI_*, T_Building_*)
## - Different directory structure
## - Metadata inconsistencies
##
## Run with: File > Run (Ctrl+Shift+X) in the Godot editor

const PROLOGUE_PATTERNS = [
	"lame_",
	"prologue_", 
	"old_",
	"test_",
	"placeholder_"
]

const MODERN_SPRITE_PATTERN = "T_UI_"
const MODERN_MODEL_DIRS = ["scenes/lit_model_scenes"]

func _run():
	print("=== Prologue Asset Identifier ===\n")
	
	var results = {
		"by_pattern": [],      # Matched by filename pattern
		"sprites_non_standard": [],  # Sprites not following T_UI_ convention
		"models_non_standard": [],   # Models not in lit_model_scenes
		"structures_mismatched": [], # Structure .tres with mismatched refs
		"summary": {}
	}
	
	# 1. Find by filename pattern
	print("Scanning for prologue filename patterns...")
	var all_files = _get_all_files("res://")
	
	for file in all_files:
		if file.begins_with("res://.godot"):
			continue
		if file.ends_with(".import"):
			continue
			
		var basename = file.get_file().to_lower()
		for pattern in PROLOGUE_PATTERNS:
			if basename.begins_with(pattern):
				results["by_pattern"].append({
					"file": file,
					"pattern": pattern
				})
				break
	
	# 2. Find sprites not following T_UI_ convention
	print("Scanning for non-standard sprite naming...")
	var sprites_dir = DirAccess.open("res://sprites")
	if sprites_dir:
		sprites_dir.list_dir_begin()
		var fname = sprites_dir.get_next()
		while fname != "":
			if not sprites_dir.current_is_dir():
				if fname.get_extension().to_lower() == "png":
					if not fname.begins_with("T_UI_"):
						# Check if it's not a known exception
						if not _is_exception(fname):
							results["sprites_non_standard"].append("res://sprites/" + fname)
			fname = sprites_dir.get_next()
	
	# 3. Check structure files for mismatched references
	print("Checking structure resource references...")
	var structures_dir = DirAccess.open("res://structures")
	if structures_dir:
		structures_dir.list_dir_begin()
		var fname = structures_dir.get_next()
		while fname != "":
			if fname.ends_with(".tres"):
				var issues = _check_structure_consistency("res://structures/" + fname)
				if issues.size() > 0:
					results["structures_mismatched"].append({
						"file": "res://structures/" + fname,
						"issues": issues
					})
			fname = structures_dir.get_next()
	
	# Output results
	print("\n=== PROLOGUE ASSETS BY PATTERN ===")
	for item in results["by_pattern"]:
		print("  [", item["pattern"], "] ", item["file"])
	print("Total: ", results["by_pattern"].size())
	
	print("\n=== NON-STANDARD SPRITES ===")
	for file in results["sprites_non_standard"]:
		print("  ", file)
	print("Total: ", results["sprites_non_standard"].size())
	
	print("\n=== STRUCTURES WITH MISMATCHED REFS ===")
	for item in results["structures_mismatched"]:
		print("  ", item["file"])
		for issue in item["issues"]:
			print("    - ", issue)
	print("Total: ", results["structures_mismatched"].size())
	
	# Summary
	results["summary"] = {
		"by_pattern": results["by_pattern"].size(),
		"sprites_non_standard": results["sprites_non_standard"].size(),
		"structures_mismatched": results["structures_mismatched"].size()
	}
	
	print("\n=== SUMMARY ===")
	print(JSON.stringify(results["summary"], "\t"))
	
	# JSON output for machine parsing
	print("\n=== JSON OUTPUT ===")
	print(JSON.stringify(results))

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

func _is_exception(filename: String) -> bool:
	"""Files that are known to not follow T_UI_ but are still modern."""
	var exceptions = [
		"icon.png",
		"Godot.png",
		"bg_",  # Background images
		"gradient",
		"noise",
		"slot_",
		"unlock_",
		"perk_",
		"effect_",
		"ui_"
	]
	var lower = filename.to_lower()
	for exc in exceptions:
		if lower.begins_with(exc) or exc in lower:
			return true
	return false

func _check_structure_consistency(tres_path: String) -> Array:
	"""Check if a .tres structure file has internally consistent references."""
	var issues = []
	
	var fa = FileAccess.open(tres_path, FileAccess.READ)
	if not fa:
		return issues
	
	var content = fa.get_as_text()
	fa.close()
	
	# Extract the structure's base name
	var tres_basename = tres_path.get_file().get_basename()
	
	# Check if it references lame_* assets while being named differently
	if not tres_basename.begins_with("lame_"):
		if "lame_" in content:
			issues.append("References 'lame_' assets but is not a prologue structure")
	
	# Check if a lame_* structure references modern assets
	if tres_basename.begins_with("lame_"):
		if "T_UI_" in content or "lit_model_scenes" in content:
			issues.append("Prologue structure references modern assets - may be intentional replacement")
	
	return issues

