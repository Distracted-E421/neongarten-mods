#!/usr/bin/env nu
# Dialog prompt hook for AI agent workflow
# Provides interactive prompts using cursor-dialog-daemon

# Check if dialog daemon is available
def dialog-available [] {
  (do { cursor-dialog-cli ping } | complete).exit_code == 0
}

# Prompt user for choice before major operations
export def "dialog choice" [
  title: string,
  prompt: string,
  options: list<record<value: string, label: string, description: string>>
] {
  if not (dialog-available) {
    print $"⚠️  Dialog daemon unavailable - using default"
    return null
  }
  
  let options_json = ($options | to json)
  let result = (cursor-dialog-cli choice --title $title --prompt $prompt --options $options_json | from json)
  
  if $result.cancelled {
    null
  } else {
    $result.selection
  }
}

# Confirm before destructive operations
export def "dialog confirm" [
  title: string,
  prompt: string,
  --yes: string = "Yes",
  --no: string = "No"
] {
  if not (dialog-available) {
    print $"⚠️  Dialog daemon unavailable - proceeding with caution"
    return false  # Default to safe option
  }
  
  let result = (cursor-dialog-cli confirm --title $title --prompt $prompt --yes $yes --no $no | from json)
  
  if $result.cancelled {
    false
  } else {
    $result.selection
  }
}

# Get text input from user
export def "dialog text" [
  title: string,
  prompt: string,
  --placeholder: string = ""
] {
  if not (dialog-available) {
    return null
  }
  
  let result = (cursor-dialog-cli text --title $title --prompt $prompt --placeholder $placeholder | from json)
  
  if $result.cancelled {
    null
  } else {
    $result.selection
  }
}

# Notify user (fire-and-forget)
export def "dialog notify" [
  title: string,
  message: string
] {
  if (dialog-available) {
    cursor-dialog-cli confirm --title $title --prompt $message --yes "OK" --no "Dismiss" | ignore
  } else {
    print $"📢 ($title): ($message)"
  }
}

# Pre-operation safety check using dialog
export def "dialog safety-check" [
  operation: string,
  details: string
] {
  dialog confirm "⚠️ Safety Check" $"About to: ($operation)\n\nDetails:\n($details)\n\nProceed?" --yes "Proceed" --no "Cancel"
}

# Task completion feedback
export def "dialog task-complete" [
  summary: string,
  --next-steps: list<string> = []
] {
  let next = if ($next_steps | is-empty) {
    ""
  } else {
    $"\n\nSuggested next steps:\n" + ($next_steps | each {|s| $"• ($s)"} | str join "\n")
  }
  
  dialog notify "✅ Task Complete" $"($summary)($next)"
}

