
-- init.lua

-- ============================
-- 1. Basic Configuration
-- ============================

-- Set the leader key to space
vim.g.mapleader = " "

-- Set up base46 cache directory
vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46/"

-- ============================
-- 2. Set Default Working Directory to Home
-- ============================

-- Function to get the home directory on Windows
local function get_home_dir()
  return os.getenv("USERPROFILE") or os.getenv("HOME")
end

-- Set the default working directory to home
vim.cmd('cd ' .. get_home_dir())

-- ============================
-- 3. Bootstrap lazy.nvim
-- ============================

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- Clone lazy.nvim if it's not already installed
if not vim.loop.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    repo,
    "--branch=stable", -- Latest stable release
    lazypath,
  })
end

-- Prepend lazy.nvim to runtime path
vim.opt.rtp:prepend(lazypath)

-- Require lazy.nvim configuration
local lazy_config = require("configs.lazy")

-- ============================
-- 4. Plugin Setup with lazy.nvim
-- ============================

require("lazy").setup({
  -- ----------------------------
  -- 4.1. NvChad Base Configuration
  -- ----------------------------
  {
    "NvChad/NvChad",
    branch = "v2.5",
    import = "nvchad.plugins",
  },

  -- ----------------------------
  -- 4.2. Comment.nvim Plugin
  -- ----------------------------
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup({
        mappings = {
          basic = false,
          extra = false,
        },
        pre_hook = function(ctx)
          if vim.bo.filetype == "cpp" or vim.bo.filetype == "c" then
            return require("Comment.api").extend_linewise_op()
          elseif vim.bo.filetype == "python" then
            return require("Comment.api").extend_linewise_op()
          end
        end,
      })
    end,
    event = { "BufReadPost", "BufNewFile" },
  },

  -- ----------------------------
  -- 4.3. nvim-lint Plugin
  -- ----------------------------
  {
    "mfussenegger/nvim-lint",
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        python = { "flake8" },
        lua = { "luacheck" },
        c = { "clangtidy" },
        cpp = { "clangtidy" },
      }
      lint.linters.flake8.args = {
        "--max-line-length=88",
        "--ignore=E203,W503",
      }
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter", "TextChanged" }, {
        callback = function()
          lint.try_lint()
        end,
      })
    end,
    event = { "BufReadPost", "BufNewFile" },
  },

  -- ----------------------------
  -- 4.4. nvim-treesitter Plugin
  -- ----------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "c",
          "cpp",
          "python",
          "lua",
          "javascript",
          "typescript",
          "html",
          "css",
          "rust",
        },
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = true,
        },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "gnn",
            node_incremental = "grn",
            scope_incremental = "grc",
            node_decremental = "grm",
          },
        },
      })
    end,
  },

  -- ----------------------------
  -- 4.5. telescope.nvim Plugin
  -- ----------------------------
  {
    "nvim-telescope/telescope.nvim",
    branch = "master",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "Telescope",
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Find Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
    },
    config = function()
      require("telescope").setup({
        defaults = {
          mappings = {
            i = {
              ["<C-u>"] = false,
              ["<C-d>"] = false,
            },
          },
          prompt_prefix = "🔍 ",
          selection_caret = "➜ ",
          entry_prefix = "  ",
        },
        pickers = {
          find_files = {
            hidden = true,
          },
          live_grep = {
            only_sort_text = true,
          },
        },
        extensions = {},
      })
    end,
  },

  -- ----------------------------
  -- 4.6. auto-session Plugin (Updated)
  -- ----------------------------
  {
    "rmagatti/auto-session",
    lazy = false,
    config = function()
      -- Set recommended session options for auto-session
      vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

      -- Configure auto-session
      require("auto-session").setup({
        log_level = "info",
        auto_session_enable_last_session = true,
        auto_restore_enabled = true,
        auto_save_enabled = true,
        auto_session_root_dir = vim.fn.stdpath("data") .. "\\sessions\\",
      })
    end,
  },

  -- ----------------------------
  -- 4.7. toggleterm.nvim Plugin
  -- ----------------------------

  {
    "akinsho/toggleterm.nvim",
    version = "*",
    lazy = false, -- Force the plugin to load immediately
    config = function()
      require("toggleterm").setup({
        size = 20,
        open_mapping = "<C-\\>",
        shade_filetypes = {},
        shade_terminals = true,
        shading_factor = 2,
        start_in_insert = true,
        insert_mappings = true,
        persist_size = true,
        direction = "float",
        close_on_exit = false, -- Keep terminal open until manually closed
        shell = vim.o.shell,
      })

      local Terminal = require("toggleterm.terminal").Terminal

      -- Function to run the current script based on filetype
      function _G.run_current_script()
        local ft = vim.bo.filetype
        local cmd
        local filename = vim.fn.expand("%")
        local filedir = vim.fn.expand("%:p:h")
        local build_dir = filedir .. "/builds"

        -- Ensure builds directory exists
        if vim.fn.isdirectory(build_dir) == 0 then
          vim.fn.mkdir(build_dir, "p")
        end

        -- Determine the command based on filetype
        if ft == "python" then
          cmd = "python " .. filename
        elseif ft == "lua" then
          cmd = "lua " .. filename
        elseif ft == "javascript" or ft == "typescript" then
          cmd = "node " .. filename
        elseif ft == "javascriptreact" or ft == "typescriptreact" then
          cmd = "npm start"
        elseif ft == "rust" then
          cmd = "cargo run"
        elseif ft == "java" then
          -- Check for Maven or Gradle build files
          if vim.fn.filereadable(filedir .. "/pom.xml") == 1 then
            cmd = "cd " .. filedir .. " && mvn clean compile exec:java"
          elseif vim.fn.filereadable(filedir .. "/build.gradle") == 1 or vim.fn.filereadable(filedir .. "/build.gradle.kts") == 1 then
            cmd = "cd " .. filedir .. " && gradle run"
          else
            -- Compile and run Java program
            cmd = "javac " .. filename .. " && java -cp " .. filedir .. " " .. vim.fn.expand("%:t:r")
          end
        elseif ft == "kotlin" then
          -- Check for Gradle build files
          if vim.fn.filereadable(filedir .. "/build.gradle") == 1 or vim.fn.filereadable(filedir .. "/build.gradle.kts") == 1 then
            cmd = "cd " .. filedir .. " && gradle run"
          else
            -- Compile and run Kotlin program
            local output = build_dir .. "/" .. vim.fn.expand("%:t:r") .. ".jar"
            cmd = "kotlinc " .. filename .. " -include-runtime -d " .. output .. " && java -jar " .. output
          end
        elseif ft == "c" or ft == "cpp" then
          -- Check for Makefile
          if vim.fn.filereadable(filedir .. "/Makefile") == 1 then
            cmd = "cd " .. filedir .. " && make"
          else
            -- Compile and run C/C++ program
            local output = build_dir .. "/" .. vim.fn.expand("%:t:r")
            local compiler = ft == "c" and "gcc" or "g++"
            cmd = compiler .. " \"" .. filename .. "\" -o \"" .. output .. "\" && \"" .. output .. "\""
          end
        else
          vim.notify("No run command for this filetype.", vim.log.levels.WARN)
          return
        end

        local run = Terminal:new({
          cmd = cmd,
          dir = filedir, -- Set the working directory
          hidden = true,
          direction = "float",
          close_on_exit = false, -- Keep terminal open
          on_close = function()
            vim.cmd("stopinsert")
          end,
        })
        run:toggle()
      end

      -- Keybinding to run the current script with <leader>a
      vim.api.nvim_set_keymap(
        "n",
        "<leader>a",
        "<cmd>lua run_current_script()<CR>",
        { noremap = true, silent = true, desc = "Run Current Script" }
      )

      -- Keybinding to toggle terminal with <leader>h
      vim.api.nvim_set_keymap(
        "n",
        "<leader>h",
        "<cmd>ToggleTerm<CR>",
        { noremap = true, silent = true, desc = "Toggle Terminal" }
      )

      -- Keybinding to open horizontal terminal with <leader>th
      vim.api.nvim_set_keymap(
        "n",
        "<leader>th",
        "<cmd>ToggleTerm direction=horizontal<CR>",
        { noremap = true, silent = true, desc = "Open Horizontal Terminal" }
      )

      -- Keybinding to open vertical terminal with <leader>tv
      vim.api.nvim_set_keymap(
        "n",
        "<leader>tv",
        "<cmd>ToggleTerm direction=vertical<CR>",
        { noremap = true, silent = true, desc = "Open Vertical Terminal" }
      )
    end,
  },

  -- ----------------------------
  -- 4.8. nvim-lspconfig for Language Servers
  -- ----------------------------
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require("lspconfig")

      -- Set up LSP for C/C++
      lspconfig.clangd.setup({})

      -- Set up LSP for Python
      lspconfig.pyright.setup({})

      -- Set up LSP for Lua using lua_ls
      lspconfig.lua_ls.setup({
        settings = {
          Lua = {
            runtime = {
              version = "LuaJIT",
            },
            diagnostics = {
              globals = { "vim" },
            },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false,
            },
            telemetry = {
              enable = false,
            },
          },
        },
      })
    end,
  },

  -- ----------------------------
  -- 4.9. trouble.nvim for Diagnostics List
  -- ----------------------------
  {
    "folke/trouble.nvim",
    dependencies = { "kyazdani42/nvim-web-devicons" },
    config = function()
      require("trouble").setup({})
    end,
    cmd = { "TroubleToggle", "Trouble" },
    keys = {
      { "<leader>xx", "<cmd>TroubleToggle<cr>", desc = "Toggle Trouble" },
      { "<leader>xw", "<cmd>TroubleToggle workspace_diagnostics<cr>", desc = "Workspace Diagnostics" },
      { "<leader>xd", "<cmd>TroubleToggle document_diagnostics<cr>", desc = "Document Diagnostics" },
      { "<leader>xl", "<cmd>TroubleToggle loclist<cr>", desc = "Location List" },
      { "<leader>xq", "<cmd>TroubleToggle quickfix<cr>", desc = "Quickfix List" },
    },
  },

  -- ----------------------------
  -- 4.10. Additional Plugins
  -- ----------------------------
  { import = "plugins" },
}, lazy_config)

-- ============================
-- 5. Theme and UI Configurations
-- ============================

-- Load theme defaults and statusline configurations
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

-- ============================
-- 6. Options and Autocommands
-- ============================

-- Load additional options and autocmds
require("options")
require("nvchad.autocmds")

-- ============================
-- 7. Key Mappings
-- ============================

-- ----------------------------
-- 7.1. Commenting Mappings
-- ----------------------------

-- Define custom key mappings for toggling comments using <leader>/
vim.keymap.set("n", "<leader>/", function()
  require("Comment.api").toggle.linewise.current()
end, { noremap = true, silent = true, desc = "Toggle comment on current line" })

vim.keymap.set("v", "<leader>/", function()
  require("Comment.api").toggle.linewise(vim.fn.visualmode())
end, { noremap = true, silent = true, desc = "Toggle comment on selected lines" })

-- ----------------------------
-- 7.2. Diagnostics Mappings
-- ----------------------------

-- Toggle virtual text diagnostics with <leader>dt
vim.keymap.set("n", "<leader>dt", function()
  local virtual_text = vim.diagnostic.config().virtual_text
  vim.diagnostic.config({ virtual_text = not virtual_text })
end, { noremap = true, silent = true, desc = "Toggle Diagnostics Virtual Text" })

-- Key mappings for navigating diagnostics
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous Diagnostic" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next Diagnostic" })

-- Trouble.nvim keybindings are set in the plugin configuration

-- ----------------------------
-- 7.3. Additional Mappings
-- ----------------------------

-- Toggle Terminal with <C-\>
-- Configured in toggleterm.nvim setup

-- Run Current Script with <leader>a
-- Configured in toggleterm.nvim setup

-- Schedule loading of mappings from a separate file, if you have one
vim.schedule(function()
  pcall(require, "mappings")
end)

-- ============================
-- 8. Diagnostics and Linting
-- ============================

-- Configure vim.diagnostic settings
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  float = {
    border = "rounded",
    source = "always",
    focusable = false,
  },
})

-- ============================
-- End of init.lua
-- ============================
