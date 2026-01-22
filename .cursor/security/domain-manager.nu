#!/usr/bin/env nu
# Domain Manager - Persistent whitelist/blacklist management for AI browser automation
# 
# Usage:
#   domain-manager check <url>           - Check if URL is allowed
#   domain-manager add <domain> [--category <cat>] [--reason <reason>]
#   domain-manager block <domain> [--reason <reason>]
#   domain-manager remove <domain>       - Remove from any list
#   domain-manager list                  - Show all domains
#   domain-manager history               - Show verification log

const CONFIG_PATH = "/home/e421/homelab/.cursor/security/domain-lists.json"

# Load domain lists from JSON file
def load-config [] {
  if ($CONFIG_PATH | path exists) {
    open $CONFIG_PATH
  } else {
    # Return default config if file doesn't exist
    {
      version: "1.0.0",
      last_updated: (date now | format date "%Y-%m-%dT%H:%M:%SZ"),
      whitelist: {
        documentation: [],
        search_engines: [],
        development: [],
        local_services: ["localhost", "127.0.0.1"],
        trusted_services: [],
        user_added: []
      },
      blacklist: {
        url_shorteners: [],
        tracking_analytics: [],
        known_malicious: [],
        user_blocked: []
      },
      verification_log: []
    }
  }
}

# Save config back to JSON file
def save-config [config: record] {
  let updated = ($config | update last_updated (date now | format date "%Y-%m-%dT%H:%M:%SZ"))
  $updated | to json -i 2 | save -f $CONFIG_PATH
}

# Flatten whitelist into single list
def get-whitelist [] {
  let config = (load-config)
  $config.whitelist | values | flatten
}

# Flatten blacklist into single list
def get-blacklist [] {
  let config = (load-config)
  $config.blacklist | values | flatten
}

# Check if domain matches a pattern (supports wildcards)
def domain-matches [domain: string, pattern: string] -> bool {
  if ($pattern | str starts-with "*.") {
    let suffix = ($pattern | str substring 1..)
    $domain | str ends-with $suffix
  } else {
    $domain == $pattern or ($domain | str ends-with $".($pattern)")
  }
}

# Check domain against lists
def check-domain [domain: string] -> record {
  let whitelist = (get-whitelist)
  let blacklist = (get-blacklist)
  
  # Check blacklist first (higher priority)
  for pattern in $blacklist {
    if (domain-matches $domain $pattern) {
      return { status: "blocked", matched_pattern: $pattern, list: "blacklist" }
    }
  }
  
  # Check whitelist
  for pattern in $whitelist {
    if (domain-matches $domain $pattern) {
      return { status: "allowed", matched_pattern: $pattern, list: "whitelist" }
    }
  }
  
  return { status: "unknown", matched_pattern: null, list: null }
}

# Extract domain from URL
def extract-domain [url: string] -> string {
  try {
    $url | url parse | get host | default ""
  } catch {
    ""
  }
}

# Add domain to whitelist
def add-to-whitelist [
  domain: string,
  --category: string = "user_added",
  --reason: string = ""
] {
  mut config = (load-config)
  
  # Ensure category exists
  if not ($category in ($config.whitelist | columns)) {
    $config = ($config | update whitelist ($config.whitelist | insert $category []))
  }
  
  # Check if already in whitelist
  let all_whitelisted = (get-whitelist)
  if $domain in $all_whitelisted {
    print $"⚠️ ($domain) is already whitelisted"
    return
  }
  
  # Remove from blacklist if present
  $config = (remove-from-blacklist-internal $config $domain)
  
  # Add to whitelist
  let current = ($config.whitelist | get $category)
  $config = ($config | update whitelist ($config.whitelist | update $category ($current | append $domain)))
  
  # Log the action
  let log_entry = {
    timestamp: (date now | format date "%Y-%m-%dT%H:%M:%SZ"),
    action: "whitelist_add",
    domain: $domain,
    category: $category,
    reason: $reason
  }
  $config = ($config | update verification_log ($config.verification_log | append $log_entry))
  
  save-config $config
  print $"✅ Added ($domain) to whitelist (category: ($category))"
}

# Add domain to blacklist
def add-to-blacklist [
  domain: string,
  --category: string = "user_blocked",
  --reason: string = ""
] {
  mut config = (load-config)
  
  # Ensure category exists
  if not ($category in ($config.blacklist | columns)) {
    $config = ($config | update blacklist ($config.blacklist | insert $category []))
  }
  
  # Check if already in blacklist
  let all_blacklisted = (get-blacklist)
  if $domain in $all_blacklisted {
    print $"⚠️ ($domain) is already blacklisted"
    return
  }
  
  # Remove from whitelist if present
  $config = (remove-from-whitelist-internal $config $domain)
  
  # Add to blacklist
  let current = ($config.blacklist | get $category)
  $config = ($config | update blacklist ($config.blacklist | update $category ($current | append $domain)))
  
  # Log the action
  let log_entry = {
    timestamp: (date now | format date "%Y-%m-%dT%H:%M:%SZ"),
    action: "blacklist_add",
    domain: $domain,
    category: $category,
    reason: $reason
  }
  $config = ($config | update verification_log ($config.verification_log | append $log_entry))
  
  save-config $config
  print $"🚫 Added ($domain) to blacklist (category: ($category))"
  
  # Notify user via dialog
  cursor-dialog-cli notify
    --title "🚫 Domain Blocked"
    --prompt $"($domain) has been added to your blacklist.\n\nReason: ($reason | default 'No reason provided')"
    --timeout 5
}

# Internal helper to remove from whitelist without saving
def remove-from-whitelist-internal [config: record, domain: string] -> record {
  mut updated = $config
  for category in ($config.whitelist | columns) {
    let current = ($config.whitelist | get $category)
    if $domain in $current {
      $updated = ($updated | update whitelist ($updated.whitelist | update $category ($current | where {|d| $d != $domain })))
    }
  }
  $updated
}

# Internal helper to remove from blacklist without saving
def remove-from-blacklist-internal [config: record, domain: string] -> record {
  mut updated = $config
  for category in ($config.blacklist | columns) {
    let current = ($config.blacklist | get $category)
    if $domain in $current {
      $updated = ($updated | update blacklist ($updated.blacklist | update $category ($current | where {|d| $d != $domain })))
    }
  }
  $updated
}

# Remove domain from all lists
def remove-domain [domain: string] {
  mut config = (load-config)
  
  let was_whitelisted = $domain in (get-whitelist)
  let was_blacklisted = $domain in (get-blacklist)
  
  $config = (remove-from-whitelist-internal $config $domain)
  $config = (remove-from-blacklist-internal $config $domain)
  
  if $was_whitelisted or $was_blacklisted {
    # Log the action
    let log_entry = {
      timestamp: (date now | format date "%Y-%m-%dT%H:%M:%SZ"),
      action: "remove",
      domain: $domain,
      was_whitelisted: $was_whitelisted,
      was_blacklisted: $was_blacklisted
    }
    $config = ($config | update verification_log ($config.verification_log | append $log_entry))
    
    save-config $config
    print $"🗑️ Removed ($domain) from all lists"
  } else {
    print $"⚠️ ($domain) was not in any list"
  }
}

# Quick mark as unsafe - for when something previously trusted becomes malicious
def mark-unsafe [
  domain: string,
  --reason: string = "Marked as unsafe by user"
] {
  print $"⚠️ Marking ($domain) as UNSAFE"
  
  # Show confirmation dialog
  let result = (cursor-dialog-cli confirm
    --title "⚠️ Mark Domain as Unsafe"
    --prompt $"Are you sure you want to mark ($domain) as unsafe?\n\nThis will:\n• Remove it from whitelist (if present)\n• Add it to blacklist\n• Log the action for audit"
    --yes "Yes, Block It"
    --no "Cancel"
    --timeout 30
    | from json)
  
  if $result.selection? == true {
    add-to-blacklist $domain --category "user_blocked" --reason $reason
    print $"✅ ($domain) is now blocked"
  } else {
    print "Cancelled"
  }
}

# List all domains
def list-domains [] {
  let config = (load-config)
  
  print "═══════════════════════════════════════════"
  print "              WHITELIST                     "
  print "═══════════════════════════════════════════"
  
  for category in ($config.whitelist | columns) {
    let domains = ($config.whitelist | get $category)
    if ($domains | length) > 0 {
      print $"\n📁 ($category):"
      for domain in $domains {
        print $"   ✅ ($domain)"
      }
    }
  }
  
  print "\n═══════════════════════════════════════════"
  print "              BLACKLIST                     "
  print "═══════════════════════════════════════════"
  
  for category in ($config.blacklist | columns) {
    let domains = ($config.blacklist | get $category)
    if ($domains | length) > 0 {
      print $"\n📁 ($category):"
      for domain in $domains {
        print $"   🚫 ($domain)"
      }
    }
  }
}

# Show verification history
def show-history [--limit: int = 20] {
  let config = (load-config)
  let log = $config.verification_log
  
  if ($log | length) == 0 {
    print "No verification history"
    return
  }
  
  print "═══════════════════════════════════════════"
  print "         VERIFICATION HISTORY              "
  print "═══════════════════════════════════════════\n"
  
  $log | last $limit | reverse | each {|entry|
    let icon = match $entry.action {
      "whitelist_add" => "✅",
      "blacklist_add" => "🚫",
      "remove" => "🗑️",
      _ => "📝"
    }
    print $"($icon) [($entry.timestamp)] ($entry.action): ($entry.domain)"
    if ($entry.reason? | default "") != "" {
      print $"   Reason: ($entry.reason)"
    }
  }
}

# Interactive domain verification for navigation gating
def verify-url [url: string] -> record {
  let domain = (extract-domain $url)
  
  if $domain == "" {
    return { allowed: false, reason: "Invalid URL" }
  }
  
  let check = (check-domain $domain)
  
  match $check.status {
    "blocked" => {
      return { allowed: false, reason: $"Blacklisted (pattern: ($check.matched_pattern))" }
    },
    "allowed" => {
      return { allowed: true, reason: $"Whitelisted (pattern: ($check.matched_pattern))" }
    },
    "unknown" => {
      # Prompt user
      let result = (cursor-dialog-cli choice
        --title "🌐 Unknown Domain"
        --prompt $"AI agent wants to navigate to:\n\n📍 URL: ($url)\n🔗 Domain: ($domain)\n\nThis domain is not recognized. What would you like to do?"
        --options '[
          {"value": "allow_once", "label": "Allow Once", "description": "Allow this navigation only"},
          {"value": "allow_remember", "label": "Allow & Remember", "description": "Allow and add to whitelist"},
          {"value": "block_once", "label": "Block Once", "description": "Block this navigation only"},
          {"value": "block_remember", "label": "Block & Remember", "description": "Block and add to blacklist"},
          {"value": "preview", "label": "Preview First", "description": "Open in sandbox for inspection"}
        ]'
        --timeout 120
        | from json)
      
      if $result.cancelled? == true {
        return { allowed: false, reason: "User cancelled" }
      }
      
      match $result.selection {
        "allow_once" => {
          # Log but don't persist
          return { allowed: true, reason: "User allowed (once)" }
        },
        "allow_remember" => {
          add-to-whitelist $domain --reason "Added via navigation prompt"
          return { allowed: true, reason: "User allowed (added to whitelist)" }
        },
        "block_once" => {
          return { allowed: false, reason: "User blocked (once)" }
        },
        "block_remember" => {
          add-to-blacklist $domain --reason "Added via navigation prompt"
          return { allowed: false, reason: "User blocked (added to blacklist)" }
        },
        "preview" => {
          return { allowed: false, reason: "preview_requested", preview: true }
        },
        _ => {
          return { allowed: false, reason: "Unknown selection" }
        }
      }
    }
  }
}

# Main command dispatcher
def main [
  command?: string,
  arg?: string,
  --category: string = "",
  --reason: string = "",
  --limit: int = 20
] {
  match $command {
    "check" => {
      if $arg == null {
        print "Usage: domain-manager check <url>"
        exit 1
      }
      let result = (verify-url $arg)
      print $result
    },
    "add" | "whitelist" => {
      if $arg == null {
        print "Usage: domain-manager add <domain> [--category <cat>] [--reason <reason>]"
        exit 1
      }
      let cat = if $category == "" { "user_added" } else { $category }
      add-to-whitelist $arg --category $cat --reason $reason
    },
    "block" | "blacklist" => {
      if $arg == null {
        print "Usage: domain-manager block <domain> [--reason <reason>]"
        exit 1
      }
      add-to-blacklist $arg --category "user_blocked" --reason $reason
    },
    "unsafe" | "mark-unsafe" => {
      if $arg == null {
        print "Usage: domain-manager unsafe <domain> [--reason <reason>]"
        exit 1
      }
      mark-unsafe $arg --reason $reason
    },
    "remove" => {
      if $arg == null {
        print "Usage: domain-manager remove <domain>"
        exit 1
      }
      remove-domain $arg
    },
    "list" | "ls" => {
      list-domains
    },
    "history" | "log" => {
      show-history --limit $limit
    },
    _ => {
      print "Domain Manager - AI Browser Automation Security"
      print ""
      print "Commands:"
      print "  check <url>              - Check if URL is allowed"
      print "  add <domain>             - Add domain to whitelist"
      print "  block <domain>           - Add domain to blacklist"
      print "  unsafe <domain>          - Quick mark as unsafe (removes from whitelist, adds to blacklist)"
      print "  remove <domain>          - Remove domain from all lists"
      print "  list                     - Show all domains"
      print "  history                  - Show verification log"
      print ""
      print "Options:"
      print "  --category <cat>         - Category for add command"
      print "  --reason <reason>        - Reason for add/block/unsafe"
      print "  --limit <n>              - Limit history entries (default: 20)"
    }
  }
}

