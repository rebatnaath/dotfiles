-- Theme profiles: named accent palettes for the UI (statusline + sidebar
-- separator). The editor background stays transparent regardless of theme --
-- only the accent surfaces change color.
--
-- Switch live with `:Theme <name>` (tab-completes), or change the default
-- below. Add new profiles by appending to `themes`.
--
-- Each profile can also set `icons = false` to hide the file/folder icons in
-- the sidebar (see the `min` profile). This is applied live when you switch
-- themes.

local M = {}

M.default = "amber"

-- Each profile:
--   statusline -> fg/bg of the focused statusline (accent surface)
--   dim        -> fg/bg of the non-focused statusline + separator tint
--   icons      -> (optional, default true) show file icons in the sidebar
M.themes = {
    -- Current default: warm amber, matching the bar/OSD/selection accent.
    amber = {
        statusline = { fg = "#442c00", bg = "#f2be6e" },
        dim = { fg = "#9b8f80", bg = "#251f17" },
    },
    -- Cool green (nord palette). Tweak freely.
    mint = {
        statusline = { fg = "#2e3440", bg = "#a3be8c" },
        dim = { fg = "#7f8f74", bg = "#1f2a1f" },
    },
    -- Minimal: neutral slate accents and no file icons in the sidebar.
    min = {
        statusline = { fg = "#e5e9f0", bg = "#4c566a" },
        dim = { fg = "#7b8494", bg = "#1e222c" },
        icons = false,
    },
}

-- Currently active theme name.
M.current = M.default

-- Desired sidebar-icon state, applied when neo-tree first sets up.
M.pending_icons = (M.themes[M.default].icons ~= false)

--- Resolve a theme by name, falling back to the default.
function M.get(name)
    return M.themes[name] or M.themes[M.default]
end

--- Renderer provider that blanks file icons (keeps the indent padding).
local function blank_icon()
    return { text = "" }
end

--- Config for neo-tree's `default_component_configs.icon`, used at setup time.
function M.icon_config()
    if M.pending_icons then
        return {} -- keep neo-tree's default (devicons) provider
    end
    return { provider = blank_icon }
end

--- Patch every `icon` component in a renderer table (config or live state).
local function patch_renderers(tbl, enabled)
    local renderers = tbl and tbl.renderers
    if type(renderers) ~= "table" then
        return
    end
    for _, renderer in pairs(renderers) do
        if type(renderer) == "table" then
            for _, comp in ipairs(renderer) do
                if type(comp) == "table" and comp[1] == "icon" then
                    if enabled then
                        if comp._blank_icons_orig then
                            comp.provider = comp._blank_icons_orig
                            comp._blank_icons_orig = nil
                        end
                    elseif not comp._blank_icons_orig then
                        comp._blank_icons_orig = comp.provider
                        comp.provider = blank_icon
                    end
                end
            end
        end
    end
end

--- Apply the active theme's icon preference to a loaded neo-tree (live).
function M.sync_sidebar_icons(enabled)
    -- Avoid loading neo-tree here: if it isn't set up yet, M.icon_config()
    -- already applies the preference when the plugin initializes.
    if not package.loaded["neo-tree"] then
        return
    end
    local nt = require("neo-tree")
    if not nt.config then
        return
    end
    -- Master config: applies to windows opened later.
    patch_renderers(nt.config, enabled)
    -- Live states: apply to windows already open.
    local manager = require("neo-tree.sources.manager")
    local renderer = require("neo-tree.ui.renderer")
    manager._for_each_state(nil, function(state)
        patch_renderers(state, enabled)
        if renderer.window_exists(state) then
            renderer.redraw(state)
        end
    end)
end

--- Apply a theme's colors (and sidebar preferences) to the UI.
function M.apply(name)
    local t = M.get(name)
    vim.api.nvim_set_hl(0, "StatusLine", {
        fg = t.statusline.fg,
        bg = t.statusline.bg,
        bold = true,
    })
    vim.api.nvim_set_hl(0, "StatusLineNC", {
        fg = t.dim.fg,
        bg = t.dim.bg,
    })
    vim.api.nvim_set_hl(0, "NeoTreeWinSeparator", {
        bg = "none",
        fg = t.dim.fg,
    })
    M.current = name
    local want = t.icons ~= false
    if want ~= M.pending_icons then
        M.pending_icons = want
        M.sync_sidebar_icons(want)
    end
end

--- Names of all available themes (for completion).
function M.list()
    local names = vim.tbl_keys(M.themes)
    table.sort(names)
    return names
end

return M
