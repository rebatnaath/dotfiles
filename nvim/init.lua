-- Minimal config: keep the editor background fully transparent so kitty's
-- transparency + blur shows through (instead of the default nvim blue-grey bg).
vim.opt.termguicolors = true

-- Show line numbers and relative line numbers.
vim.opt.number = true
vim.opt.relativenumber = true

-- Hide the empty command-line row below the statusline so the bar sits at the
-- very bottom of the terminal. The cmdline still pops up when needed (':').
vim.opt.cmdheight = 0

-- Clear the background of every editor surface group. Functional highlights
-- like Visual / Search / Pmenu keep their backgrounds so selection etc. stays
-- visible.
for _, group in ipairs({
    "Normal",
    "NormalFloat",
    "SignColumn",
    "LineNr",
    "CursorLineNr",
    "CursorLine",
    "FoldColumn",
    "EndOfBuffer",
    "WinSeparator",
    "VertSplit",
    "TabLine",
    "TabLineFill",
    "TabLineSel",
    "MsgArea",
    "ModeMsg",
    "MsgSeparator",
    "NonText",
    "Whitespace",
}) do
    vim.api.nvim_set_hl(0, group, { bg = "none" })
end

-- Statusline & sidebar accent colors come from the active theme profile
-- (lua/themes.lua). Switch live with `:Theme <name>`.
require("themes").apply(require("themes").default)

-- Show the current mode in the statusline.
local mode_map = {
    n = "NORMAL", i = "INSERT", c = "COMMAND", v = "VISUAL",
    V = "V-LINE", ["\22"] = "V-BLOCK", R = "REPLACE", s = "SELECT",
    S = "S-LINE", ["\19"] = "S-BLOCK", t = "TERMINAL",
}
-- Must be global: the statusline calls it via %{v:lua.current_mode()}, and
-- v:lua only resolves functions in the global (_G) namespace.
function current_mode()
    return mode_map[vim.fn.mode()] or vim.fn.mode()
end

vim.o.statusline = "%#StatusLine# %{v:lua.current_mode()} %=%h%=%r%=%{expand('%:p:~:.')}%="

-- ---- Plugin manager (lazy.nvim) ------------------------------------------

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            local theme = require("themes")
            require("neo-tree").setup({
                close_if_last_window = true,
                -- Themes can hide sidebar icons (e.g. `min`); the provider is
                -- chosen from the active theme at setup time.
                default_component_configs = {
                    icon = theme.icon_config(),
                },
                filesystem = {
                    follow_current_file = { enabled = true },
                    use_libuv_file_watcher = true,
                },
                window = {
                    position = "left",
                    width = 34,
                },
            })
            -- Keep the sidebar transparent like the rest of the editor (and
            -- give its split separator a subtle tint matching the active theme).
            vim.api.nvim_set_hl(0, "NeoTreeNormal",     { bg = "none" })
            vim.api.nvim_set_hl(0, "NeoTreeNormalNC",   { bg = "none" })
            local theme = require("themes")
            vim.api.nvim_set_hl(0, "NeoTreeWinSeparator", {
                bg = "none",
                fg = theme.get(theme.current).dim.fg,
            })
        end,
    },

    -- Treesitter syntax highlighting for a broad set of languages.
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter").setup({
                ensure_installed = {
                    -- explicitly requested
                    "rust", "html", "css", "bash",
                    -- web / config
                    "javascript", "typescript", "tsx", "json", "jsonc", "yaml", "toml",
                    -- scripting / editors
                    "lua", "vim", "vimdoc", "fish", "python",
                    -- systems / backend
                    "c", "cpp", "go", "java", "sql", "zig",
                    -- docs / meta
                    "markdown", "markdown_inline", "comment", "diff", "gitcommit", "gitignore",
                    -- build / nix
                    "make", "cmake", "dockerfile", "xml", "query", "nix",
                },
                highlight = { enable = true },
                indent = { enable = true },
            })
        end,
    },
})

-- ---- Padding / breathing room around the code area ------------------------

-- Keep the cursor a few lines off the top/bottom and columns off the sides
-- while scrolling.
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
-- Reserve a sign column (left gutter) and a fold column, so code doesn't sit
-- flush against the window edge.
vim.opt.signcolumn = "yes"
vim.opt.foldcolumn = "1"

-- ---- Keybinds -------------------------------------------------------------

-- Toggle the file sidebar (VS Code style): <leader>e or Ctrl+n.
vim.keymap.set("n", "<leader>e", "<Cmd>Neotree toggle<CR>", { desc = "Toggle file explorer" })
vim.keymap.set("n", "<C-n>", "<Cmd>Neotree toggle<CR>", { desc = "Toggle file explorer" })

-- Auto-open the sidebar when launching `nvim` (no file args) inside a
-- directory, so a bare `nvim` in a project shows the file tree like VS Code.
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        -- #argv() = number of file args: 0 means bare `nvim` (project dir).
        -- `focus` opens the tree AND puts the cursor in it, so you can start
        -- navigating with j/k/Enter immediately (no mouse needed).
        if #vim.fn.argv() == 0 then
            vim.cmd("Neotree focus")
        end
    end,
})

-- ---- Theme switching -------------------------------------------------------

-- Switch UI theme profiles live: `:Theme <name>` with tab-completion.
vim.api.nvim_create_user_command("Theme", function(opts)
    local themes = require("themes")
    if not themes.themes[opts.args] then
        vim.notify(
            "Unknown theme '" .. opts.args .. "'. Available: "
                .. table.concat(themes.list(), ", "),
            vim.log.levels.ERROR
        )
        return
    end
    themes.apply(opts.args)
    vim.notify("Theme switched to '" .. opts.args .. "'")
end, {
    nargs = 1,
    complete = function()
        return require("themes").list()
    end,
})
