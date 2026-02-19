# Please Read in full!
# Currency-Monitor.sh
# Designed with tmux in mind, a currency tracker.  

When you create the script please make sure to make the script executable. 
chmod +x nameofscript.sh

# SETUP NOTES
# ─────────────────────────────────────────
# Make the file executable chmod +x nameoffile.sh
# Terminal Used: Kitty (switched from Konsole due to:  mouse flicker issue)

# Font: monospace with emoji flag support via:
#   sudo apt install fonts-noto-color-emoji
#   symbol_map U+1F1E0-U+1F1FF Noto Color Emoji  (in ~/.config/kitty/kitty.conf)

# My curren kitty config file setup. 
# ═══════════════════════════════════
# Kitty Terminal Configuration
# ═══════════════════════════════════

# Font settings
font_family      monospace
font_size        11.0

# Emoji / Flag support
symbol_map U+1F1E0-U+1F1FF Noto Color Emoji

# Colors and performance
enable_audio_bell no
term xterm-256color
