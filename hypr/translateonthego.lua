-- TranslateOnTheGo — Hyprland integration (Lua config provider).
--
-- Used by Omarchy 4+ and any Hyprland running `configProvider: lua`.
-- Loaded from ~/.config/hypr/hyprland.lua with:
--     require("hypr.translateonthego")
--
-- The equivalent legacy file is hypr/translateonthego.conf, for Hyprland
-- setups still using the classic .conf provider. Keep the two in sync.

-- Keybind: Super + H → trigger writing tools on the PRIMARY selection.
-- o.launch() wraps the command in `uwsm-app --` so it lands in its own
-- systemd scope rather than inheriting the compositor's.
o.bind("SUPER + H", "TranslateOnTheGo", o.launch("translateonthego"))

-- Review window: floating, centred, comfortably sized.
o.window("^(com\\.translateonthego\\.review)$", {
  float = true,
  center = true,
  size = { 740, 560 },
})
