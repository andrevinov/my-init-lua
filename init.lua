------------------------------------------------------------
-- Plugins via vim-plug ------------------------------------
------------------------------------------------------------
local Plug = vim.fn["plug#"]
vim.call("plug#begin")

Plug('gmarik/Vundle.vim')
Plug('rose-pine/neovim', { ['as'] = 'rose-pine' })
Plug('Valloric/YouCompleteMe')
Plug('dense-analysis/ale')
Plug('kien/ctrlp.vim')
Plug('tpope/vim-fugitive')
Plug('vim-airline/vim-airline')
Plug('vim-airline/vim-airline-themes')
Plug('Dimercel/todo-vim')
Plug('DavidEGx/ctrlp-smarttabs')
Plug('tpope/vim-commentary')
Plug('farfanoide/vim-kivy')
Plug('lepture/vim-jinja')
Plug('catppuccin/nvim', { ['as'] = 'catppuccin' })
Plug('lervag/vimtex')
Plug('alvan/vim-closetag')
Plug('AndrewRadev/tagalong.vim')
Plug('dccsillag/magma-nvim', { ['do'] = ':UpdateRemotePlugins' })
Plug('nvim-tree/nvim-tree.lua')
Plug('nvim-tree/nvim-web-devicons')
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'famiu/bufdelete.nvim'
Plug 'stephpy/vim-yaml'
Plug 'lewis6991/gitsigns.nvim'
Plug('nvim-treesitter/nvim-treesitter', {
  ['branch'] = 'master',
  ['do'] = ':TSUpdate',
})
Plug 'MeanderingProgrammer/render-markdown.nvim'

vim.call("plug#end")

------------------------------------------------------------
-- Desabilita netrw (para nvim-tree) -----------------------
------------------------------------------------------------
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

------------------------------------------------------------
-- nvim-tree -----------------------------------------------
------------------------------------------------------------
local function on_attach(bufnr)
  local api = require('nvim-tree.api')

  -- 1) Restaura TODOS os mapeamentos padrão do nvim-tree
  api.config.mappings.default_on_attach(bufnr)

  -- 2) Mantém SUA customização de Shift+I (toggle “tudo ou nada”)
  vim.keymap.set('n', 'I', function()
    api.tree.toggle_hidden_filter()     -- dotfiles/custom
    api.tree.toggle_gitignore_filter()  -- gitignored
  end, { buffer = bufnr, noremap = true, silent = true, nowait = true })
end

require('nvim-tree').setup {
  on_attach = on_attach,

  view = { width = 35, side = 'left' },
  renderer = { group_empty = true },
  update_focused_file = { enable = true, update_root = true },

  -- Esconde por padrão:
  filters = {
    dotfiles = true,
    custom   = {},
    git_clean = false,
  },
  git = {
    enable = true,
    ignore = true,  -- oculta itens do .gitignore inicialmente
  },
}
------------------------------------------------------------
-- Opções globais ------------------------------------------
------------------------------------------------------------
local opt = vim.opt
opt.termguicolors   = true
opt.encoding        = 'utf-8'
opt.clipboard:append('unnamedplus')
opt.wrap            = false
opt.number          = true
opt.foldmethod      = 'indent'
opt.foldlevel       = 99
opt.textwidth       = 0
opt.tw              = 0
opt.wildignore:append{
  '*.pyc','*.o','*.obj','*.svn','*.swp','*.class','*.hg',
  '*.DS_Store','*.min.*','__pycache__'
}

------------------------------------------------------------
-- Swap / backup / undo ------------------------------------
------------------------------------------------------------
opt.swapfile = false      -- não cria .swp
opt.backup = false        -- não cria backup ~
opt.writebackup = false   -- evita backup temporário ao salvar

-- Mantém undo persistente entre sessões, sem depender de swap
opt.undofile = true

local undo_dir = vim.fn.stdpath("state") .. "/undo"
vim.fn.mkdir(undo_dir, "p")
opt.undodir = undo_dir

-- Mantém coluna de sinais sempre visível, sem o texto ficar pulando
opt.signcolumn = "yes"

------------------------------------------------------------
--- Leader & mapeamentos -----------------------------------
------------------------------------------------------------
vim.g.mapleader = '\\'
local map = vim.keymap.set
map('n', '<Space>', '<Nop>', { silent = true })
map('n', '<C-f>', ':NvimTreeToggle<CR>', { silent = true })
map({'n','v'}, '++', '<Plug>NERDCommenterToggle')
map('n', '<F5>', ':TODOToggle<CR>')
map('n', 'K', '<Esc>')

-- Permite usar Ctrl+W normalmente mesmo dentro do terminal/Codex
map('t', '<C-w>', [[<C-\><C-n><C-w>]], { silent = true })

------------------------------------------------------------
--- Highlights & transparência -----------------------------
------------------------------------------------------------
vim.cmd [[
  hi Normal   guibg=NONE ctermbg=NONE
  hi NormalNC guibg=#1f1d2e ctermbg=236
  highlight BadWhitespace ctermbg=red guibg=darkred
]]

------------------------------------------------------------
--- Rose-Pine ----------------------------------------------
------------------------------------------------------------
require('rose-pine').setup {
  variant = 'auto',
  dark_variant = 'main',
  disable_background = true,
  disable_float_background = true,
}
vim.cmd 'colorscheme rose-pine'

------------------------------------------------------------
--- YouCompleteMe ------------------------------------------
------------------------------------------------------------
vim.g.ycm_autoclose_preview_window_after_completion = 1
vim.g.ycm_semantic_triggers = { python = { 're!\\w{2}' } }
vim.g.ycm_auto_hover = ''
vim.opt.completeopt:remove('preview')

------------------------------------------------------------
-- ALE: Ruff + Pyright -------------------------------------
------------------------------------------------------------
vim.g.ale_sign_column_always = 1

-- Diagnósticos:
-- Ruff   -> lint, estilo, imports, problemas comuns
-- Pyright -> análise estática de tipos
vim.g.ale_linters = {
  python = { "ruff", "pyright" },
}

-- Correções executadas pelo :ALEFix
vim.g.ale_fixers = {
  python = {
    "ruff",        -- ruff check --fix
    "ruff_format", -- ruff format
  },
}


-- Ruff instalado dentro do ambiente Poetry de cada projeto
vim.g.ale_python_ruff_auto_poetry = 1
vim.g.ale_python_ruff_format_auto_poetry = 1

-- Pyright continua instalado globalmente via npm
vim.g.ale_python_pyright_use_global = 1

-- Corrige e formata automaticamente ao salvar
vim.g.ale_fix_on_save = 1

-- Mantém as mensagens fora do texto do código
vim.g.ale_virtualtext_cursor = "disabled"

-- Atalho manual: \af
map("n", "<leader>af", "<cmd>ALEFix<CR>", {
  silent = true,
  desc = "ALE: Ruff fix + format",
})

------------------------------------------------------------
--- Telescope “buffers” (com delete integrado) -------------
------------------------------------------------------------
-- Substitui o SmartTabs
-- Requer os plugins:
--   Plug 'nvim-lua/plenary.nvim'
--   Plug 'nvim-telescope/telescope.nvim'
-- (adiciona esses dois no bloco de plugins lá em cima)
--
require('telescope').setup {
  defaults = {
    sorting_strategy = 'ascending',
    layout_config    = { prompt_position = 'top' },
    preview = { treesitter = false },
  },
  pickers = {
    buffers = {
      sort_lastused = true,
      theme         = 'dropdown',
      previewer     = false,
      mappings      = {
        i = { ['<C-d>'] = require('telescope.actions').delete_buffer },
        n = { ['dd']    = require('telescope.actions').delete_buffer },
      },
    },
  },
}

-- Atalho: <leader>p abre a lista de buffers
map('n', '<leader>p', '<cmd>Telescope buffers<CR>', { silent = true })

------------------------------------------------------------
--- Terminal Toggle ----------------------------------------
------------------------------------------------------------
local term = { buf = 0, win = 0 }

function _G.TermToggle(height)
  -- Se a janela do terminal existe, só esconder
  if term.win ~= 0 and vim.api.nvim_win_is_valid(term.win) then
    vim.api.nvim_win_hide(term.win)
    term.win = 0
    return
  end

  -- Abre nova janela na base
  vim.cmd('botright new')
  vim.cmd('resize ' .. (height or 12))

  if term.buf ~= 0 and vim.api.nvim_buf_is_valid(term.buf) then
    -- Reusa o buffer de terminal existente (NÃO chama termopen de novo)
    vim.api.nvim_set_current_buf(term.buf)
  else
    -- Cria um terminal novo no buffer vazio recém-aberto
    term.buf = vim.api.nvim_get_current_buf()
    vim.fn.termopen(vim.o.shell, { detach = 0 })   -- <<< uma única vez
    -- Não listar no :ls nem no Telescope buffers
    vim.bo[term.buf].buflisted = false
    -- Cosmética
    vim.cmd([[setlocal nonumber norelativenumber signcolumn=no]])
  end

  term.win = vim.api.nvim_get_current_win()
  vim.cmd('startinsert')
end

-- Atalhos
map('n', '<A-t>', '<cmd>lua TermToggle(12)<CR>', { silent = true })
map('i', '<A-t>', '<Esc><cmd>lua TermToggle(12)<CR>', { silent = true })
map('t', '<A-t>', [[<C-\><C-n><cmd>lua TermToggle(12)<CR>]], { silent = true })
map('t', '<Esc>', [[<C-\><C-n>]], { silent = true })
map('t', ':q!', [[<C-\><C-n>:q!<CR>]], { silent = true })

------------------------------------------------------------
--- Buffers de Arquivos ------------------------------------
------------------------------------------------------------

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.foldmethod = "manual"
  end,
})


local uv = vim.uv or vim.loop

local function path_exists(path, expected_type)
  local stat = uv.fs_stat(path)
  return stat and stat.type == expected_type
end

local function find_upwards(start_dir, callback)
  local dir = vim.fn.fnamemodify(start_dir, ":p")

  while dir and dir ~= "" do
    dir = dir:gsub("/+$", "")

    local result = callback(dir)
    if result then
      return result, dir
    end

    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      break
    end

    dir = parent
  end

  return nil, nil
end

local function get_python_runner(file)
  local file_dir = vim.fn.fnamemodify(file, ":p:h")

  local venv_python, venv_root = find_upwards(file_dir, function(dir)
    local python = dir .. "/.venv/bin/python"

    if path_exists(python, "file") then
      return vim.fn.shellescape(python)
    end
  end)

  if venv_python then
    return venv_python, venv_root
  end

  local _, project_root = find_upwards(file_dir, function(dir)
    return path_exists(dir .. "/pyproject.toml", "file")
      or path_exists(dir .. "/poetry.lock", "file")
      or path_exists(dir .. "/.git", "directory")
  end)

  if project_root
      and path_exists(project_root .. "/poetry.lock", "file")
      and vim.fn.executable("poetry") == 1 then
    return "poetry run python", project_root
  end

  return "python3", project_root or file_dir
end

local function run_python_file()
  vim.cmd("write")

  local file = vim.fn.expand("%:p")
  local runner, root = get_python_runner(file)
  local command = "cd "
    .. vim.fn.shellescape(root)
    .. " && "
    .. runner
    .. " "
    .. vim.fn.shellescape(file)

  vim.cmd("!" .. command)
end

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'python',
  callback = function()
    map('n', '<leader>r', run_python_file, { buffer = true, desc = 'Run Python file' })
    map('i', '<leader>r', function()
      vim.cmd('stopinsert')
      run_python_file()
    end, { buffer = true, desc = 'Run Python file' })
    vim.opt_local.expandtab = true
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.softtabstop = 4

    vim.opt_local.autoindent = true
    vim.opt_local.smartindent = false
    vim.opt_local.cindent = false
    vim.opt_local.indentexpr = ""
  end,
})

-- Identador
vim.keymap.set('n', '<leader>bf', '<cmd>ALEFix<CR>', { desc = 'Black format (ALEFix)' })

-- Define o espaçamento para arquivos JSON
vim.api.nvim_create_autocmd("FileType", {
  pattern = "json",
  callback = function()
    vim.opt_local.expandtab = true  -- usa espaços em vez de tabs
    vim.opt_local.shiftwidth = 3    -- número de espaços por indentação automática
    vim.opt_local.tabstop = 3       -- número de espaços que uma tab "vale"
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "yaml", "yml" },
  callback = function()
    -- vim.opt_local.indentexpr = ""   -- <- chave
    -- vim.opt_local.indentkeys = ""   -- evita triggers de reindent
    vim.opt_local.autoindent = true
    vim.opt_local.smartindent = false
    vim.opt_local.cindent = false
    -- mantenha o espaço que você quer:
    vim.opt_local.expandtab = true
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
  end,
})


vim.api.nvim_create_autocmd("FileType", {
  pattern = "lua",
  callback = function()
    vim.opt_local.expandtab = true
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "tex",
  callback = function()
    vim.opt_local.expandtab = true
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.textwidth = 80
    vim.opt_local.conceallevel = 0
    vim.opt_local.spell = true
    vim.opt_local.spelllang = {'pt', 'en'}
  end,
})

------------------------------------------------------------
-- 14. Recordar folds automaticamente (ignora nofile) ----
------------------------------------------------------------
local remember = vim.api.nvim_create_augroup('remember_folds', { clear = true })

-- Salva a posição/folds ao sair de um buffer “normal”
vim.api.nvim_create_autocmd('BufWinLeave', {
  group = remember,
  pattern = '*',
  callback = function()
    if vim.bo.buftype == '' and vim.api.nvim_buf_get_name(0) ~= '' then
      -- mkview pode falhar (por exemplo, em arquivos só-leitura), então uso pcall
      pcall(vim.cmd, 'silent! mkview')
    end
  end,
})

-- Restaura a posição/folds ao reabrir o buffer
vim.api.nvim_create_autocmd('BufWinEnter', {
  group = remember,
  pattern = '*',
  callback = function()
    if vim.bo.buftype == '' and vim.api.nvim_buf_get_name(0) ~= '' then
      pcall(vim.cmd, 'silent! loadview')
    end
  end,
})

---------------------------------------------------------------
-- 15. Air-line (setas ▸, tema “luna” e tabline integrada)  ---
---------------------------------------------------------------
-- Usa ícones/patch-fonts para as setas; certifique-se de ter Nerd Font.
vim.g.airline_powerline_fonts = 1

-- Tema escuro “luna”
vim.g.airline_theme = 'luna'

-- Caracteres de separação em formato seta
vim.g.airline_left_sep       = ''
vim.g.airline_left_alt_sep   = ''
vim.g.airline_right_sep      = ''
vim.g.airline_right_alt_sep  = ''

-- Habilita tabline do Airline
vim.g['airline#extensions#tabline#enabled'] = 1
-- (opcional) formatação padrão; altera se quiser outro estilo
vim.g['airline#extensions#tabline#formatter'] = 'default'

------------------------------------------------------------
-- LaTeX
------------------------------------------------------------

vim.api.nvim_set_keymap('n', '<F5>', 
  ':w<CR>:!pdflatex -interaction=nonstopmode %<CR>', 
  { noremap = true, silent = false })

------------------------------------------------------------
-- Comando Teste
------------------------------------------------------------

vim.api.nvim_create_user_command('LuaTest', function(opts)
  vim.notify("Args passados: " .. (opts.largs or ""))  
end, {nargs = '*', range = true, desc = "Run selected Lua lines"})


------------------------------------------------------------
-- Clipboard -> pasta selecionada no NvimTree --------------
------------------------------------------------------------
local CLIPBOARD_FALLBACK_DIR = "/home/andre/Projects/diariodebordo/anexos"

local function find_nvimtree_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)

      if vim.bo[buf].filetype == "NvimTree" then
        return win
      end
    end
  end

  return nil
end

local function dir_from_nvimtree_node(node)
  if not node then
    return nil
  end

  local path = node.absolute_path or node.link_to

  if not path or path == "" then
    return nil
  end

  -- Se for diretório, salva dentro dele.
  if node.type == "directory" or vim.fn.isdirectory(path) == 1 then
    return path
  end

  -- Se for arquivo, salva na pasta onde ele está.
  return vim.fn.fnamemodify(path, ":h")
end

local function get_nvimtree_selected_dir()
  local ok, api = pcall(require, "nvim-tree.api")

  if not ok then
    return nil
  end

  -- Caso o foco esteja no próprio NvimTree.
  if vim.bo.filetype == "NvimTree" then
    return dir_from_nvimtree_node(api.tree.get_node_under_cursor())
  end

  -- Caso o foco esteja em outro lugar, ex.: editor ou terminal Codex.
  local tree_win = find_nvimtree_win()

  if not tree_win then
    return nil
  end

  local ok_dir, dir = pcall(vim.api.nvim_win_call, tree_win, function()
    return dir_from_nvimtree_node(api.tree.get_node_under_cursor())
  end)

  if ok_dir then
    return dir
  end

  return nil
end

local function path_exists(path)
  local uv = vim.uv or vim.loop
  return uv.fs_stat(path) ~= nil
end

local function unique_clipboard_path(dir, ext)
  vim.fn.mkdir(dir, "p")

  local base = os.date("%Y-%m-%d-%H-%M-%S")
  local path = string.format("%s/%s.%s", dir, base, ext)

  local i = 1
  while path_exists(path) do
    path = string.format("%s/%s-%02d.%s", dir, base, i, ext)
    i = i + 1
  end

  return path
end

local function pick_mime(mimes, wanted_list)
  for _, wanted in ipairs(wanted_list) do
    for _, got in ipairs(mimes) do
      if got:lower() == wanted:lower() then
        return got
      end
    end
  end

  return nil
end

function _G.SaveClipboardToNvimTreeDir()
  if vim.fn.executable("wl-paste") == 0 then
    vim.notify(
      "wl-paste não encontrado. Instale com: sudo apt install wl-clipboard",
      vim.log.levels.ERROR
    )
    return
  end

  local target_dir = get_nvimtree_selected_dir()

  if not target_dir or target_dir == "" then
    target_dir = CLIPBOARD_FALLBACK_DIR
    vim.notify(
      "NvimTree sem pasta selecionada; usando fallback: " .. target_dir,
      vim.log.levels.WARN
    )
  end

  target_dir = vim.fn.expand(target_dir)

  local mimes = vim.fn.systemlist({ "wl-paste", "--list-types" })

  if vim.v.shell_error ~= 0 or #mimes == 0 then
    vim.notify("Clipboard vazia ou inacessível.", vim.log.levels.WARN)
    return
  end

  local image_exts = {
    ["image/png"] = "png",
    ["image/jpeg"] = "jpg",
    ["image/jpg"] = "jpg",
    ["image/webp"] = "webp",
    ["image/gif"] = "gif",
    ["image/bmp"] = "bmp",
    ["image/tiff"] = "tiff",
  }

  local image_mime = pick_mime(mimes, {
    "image/png",
    "image/jpeg",
    "image/jpg",
    "image/webp",
    "image/gif",
    "image/bmp",
    "image/tiff",
  })

  local text_mime = pick_mime(mimes, {
    "text/plain;charset=utf-8",
    "text/plain",
    "UTF8_STRING",
    "STRING",
  })

  local mime, ext, no_newline

  if image_mime then
    mime = image_mime
    ext = image_exts[image_mime:lower()] or "img"
    no_newline = false
  elseif text_mime then
    mime = text_mime
    ext = "txt"
    no_newline = true
  else
    vim.notify("Clipboard ignorada: não é texto nem imagem.", vim.log.levels.INFO)
    return
  end

  local path = unique_clipboard_path(target_dir, ext)

  local cmd
  if no_newline then
    cmd = string.format(
      "wl-paste --no-newline --type %s > %s",
      vim.fn.shellescape(mime),
      vim.fn.shellescape(path)
    )
  else
    cmd = string.format(
      "wl-paste --type %s > %s",
      vim.fn.shellescape(mime),
      vim.fn.shellescape(path)
    )
  end

  vim.fn.system({ "sh", "-c", cmd })

  if vim.v.shell_error ~= 0 then
    vim.notify("Falha ao salvar clipboard.", vim.log.levels.ERROR)
    return
  end

  pcall(function()
    require("nvim-tree.api").tree.reload()
  end)

  vim.notify(
    "Clipboard salva em: " .. vim.fn.fnamemodify(path, ":~"),
    vim.log.levels.INFO
  )
end

map("n", "<leader>v", "<cmd>lua SaveClipboardToNvimTreeDir()<CR>", {
  silent = true,
  desc = "Salvar clipboard na pasta selecionada do NvimTree",
})

map("i", "<leader>v", "<Esc><cmd>lua SaveClipboardToNvimTreeDir()<CR>", {
  silent = true,
  desc = "Salvar clipboard na pasta selecionada do NvimTree",
})

map("t", "<leader>v", [[<C-\><C-n><cmd>lua SaveClipboardToNvimTreeDir()<CR>i]], {
  silent = true,
  desc = "Salvar clipboard na pasta selecionada do NvimTree",
})

------------------------------------------------------------
-- NvimTree: ENTER abre imagens no app padrão do Ubuntu ----
------------------------------------------------------------
local function install_nvimtree_image_opener(bufnr)
  local api = require("nvim-tree.api")

  local external_open_exts = {
    -- imagens
    png = true,
    jpg = true,
    jpeg = true,
    gif = true,
    webp = true,
    bmp = true,
    tif = true,
    tiff = true,
    svg = true,
    avif = true,
    heic = true,

    -- documentos
    pdf = true,
  }


  local function open_with_system(path)
    local job_id = vim.fn.jobstart({ "xdg-open", path }, { detach = true })

    if job_id <= 0 then
      vim.notify("Falha ao abrir imagem com xdg-open: " .. path, vim.log.levels.ERROR)
    end
  end

  local function smart_open()
    local node = api.tree.get_node_under_cursor()

    if not node then
      return
    end

    if node.type ~= "file" then
      api.node.open.edit()
      return
    end

    local path = node.absolute_path or node.link_to
    local ext = path and vim.fn.fnamemodify(path, ":e"):lower()

    if path and ext and external_open_exts[ext] then
      open_with_system(path)
      return
    end

    api.node.open.edit()
  end

  for _, lhs in ipairs({ "<CR>", "o", "<2-LeftMouse>" }) do
    pcall(vim.keymap.del, "n", lhs, { buffer = bufnr })

    vim.keymap.set("n", lhs, smart_open, {
      buffer = bufnr,
      noremap = true,
      silent = true,
      nowait = true,
      desc = "NvimTree smart open",
    })
  end
end

vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
  pattern = "NvimTree",
  callback = function(args)
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(args.buf) then
        install_nvimtree_image_opener(args.buf)
      end
    end)
  end,
})

------------------------------------------------------------
-- Smart Quit: :q, :q!, :wq fecham o BUFFER de verdade -----
------------------------------------------------------------

local function buffer_is_visible(bufnr)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win)
        and vim.api.nvim_win_get_buf(win) == bufnr then
      return true
    end
  end

  return false
end

local function is_empty_unnamed_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return false end
  if not vim.api.nvim_buf_is_loaded(bufnr) then return false end
  if vim.bo[bufnr].buftype ~= "" then return false end
  if vim.api.nvim_buf_get_name(bufnr) ~= "" then return false end
  if vim.bo[bufnr].modified then return false end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)
  return vim.api.nvim_buf_line_count(bufnr) == 1 and (lines[1] or "") == ""
end

local function cleanup_no_name_buffers()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if is_empty_unnamed_buffer(bufnr) then
      -- Some do Telescope buffers / Airline tabline
      vim.bo[bufnr].buflisted = false

      -- Se não estiver visível em janela nenhuma, apaga de vez
      if not buffer_is_visible(bufnr) then
        pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
      end
    end
  end
end

local function is_good_replacement_buffer(bufnr, current)
  return bufnr ~= current
    and vim.api.nvim_buf_is_valid(bufnr)
    and vim.api.nvim_buf_is_loaded(bufnr)
    and vim.bo[bufnr].buflisted
    and vim.bo[bufnr].buftype == ""
    and vim.api.nvim_buf_get_name(bufnr) ~= ""
end

local function find_replacement_buffer(current)
  -- Primeiro tenta o buffer alternativo: Ctrl-^ / :b#
  local alt = vim.fn.bufnr("#")

  if alt > 0 and is_good_replacement_buffer(alt, current) then
    return alt
  end

  -- Depois pega o buffer listado usado mais recentemente
  local buffers = vim.fn.getbufinfo({ buflisted = 1 })

  table.sort(buffers, function(a, b)
    return (a.lastused or 0) > (b.lastused or 0)
  end)

  for _, info in ipairs(buffers) do
    if is_good_replacement_buffer(info.bufnr, current) then
      return info.bufnr
    end
  end

  return nil
end

local function listed_file_buffer_count()
  local count = 0

  for _, info in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    local bufnr = info.bufnr

    if vim.api.nvim_buf_is_valid(bufnr)
        and vim.api.nvim_buf_is_loaded(bufnr)
        and vim.bo[bufnr].buftype == ""
        and vim.api.nvim_buf_get_name(bufnr) ~= "" then
      count = count + 1
    end
  end

  return count
end

local function quit_all(force)
  pcall(vim.cmd, force and "quitall!" or "quitall")
  vim.schedule(cleanup_no_name_buffers)
end

local function smart_quit(force)
  local current = vim.api.nvim_get_current_buf()

  -- Buffers especiais continuam se comportando como janela.
  -- Exceção: NvimTree sozinho, ou com um único arquivo real, fecha tudo.
  if vim.bo[current].buftype ~= "" then
    if vim.bo[current].filetype == "NvimTree" and listed_file_buffer_count() <= 1 then
      quit_all(force)
      return
    end

    pcall(vim.cmd, force and "quit!" or "quit")
    vim.schedule(cleanup_no_name_buffers)
    return
  end

  -- :q não descarta arquivo modificado
  if vim.bo[current].modified and not force then
    vim.notify(
      "Arquivo modificado. Use :wq para salvar ou :q! para descartar.",
      vim.log.levels.ERROR
    )
    return
  end

  local replacement = find_replacement_buffer(current)

  if not replacement then
    quit_all(force)
    return
  end

  vim.api.nvim_win_set_buf(0, replacement)

  pcall(vim.api.nvim_buf_delete, current, { force = force })

  vim.schedule(cleanup_no_name_buffers)
end

vim.api.nvim_create_user_command("Q", function(opts)
  smart_quit(opts.bang)
end, { bang = true, force = true })

vim.api.nvim_create_user_command("WQ", function(opts)
  if vim.bo.buftype ~= "" then
    pcall(vim.cmd, opts.bang and "quit!" or "quit")
    return
  end

  local ok, err = pcall(vim.cmd, opts.bang and "write!" or "write")

  if not ok then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end

  smart_quit(true)
end, { bang = true, force = true })

vim.cmd([[
  cnoreabbrev <expr> q   (getcmdtype()==':' && getcmdline() ==# 'q')   ? 'Q'   : 'q'
  cnoreabbrev <expr> q!  (getcmdtype()==':' && getcmdline() ==# 'q!')  ? 'Q!'  : 'q!'
  cnoreabbrev <expr> wq  (getcmdtype()==':' && getcmdline() ==# 'wq')  ? 'WQ'  : 'wq'
  cnoreabbrev <expr> wq! (getcmdtype()==':' && getcmdline() ==# 'wq!') ? 'WQ!' : 'wq!'
]])

vim.keymap.set("n", "ZZ", "<cmd>WQ<CR>", { silent = true })
vim.keymap.set("n", "ZQ", "<cmd>Q!<CR>", { silent = true })

vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
  callback = function()
    vim.schedule(cleanup_no_name_buffers)
  end,
})

------------------------------------------------------------
-- Gitsigns: atalhos Git -----------------------------------
------------------------------------------------------------
require("gitsigns").setup({
  on_attach = function(bufnr)
    local gs = require("gitsigns")

    local function gmap(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, {
        buffer = bufnr,
        silent = true,
        desc = "Git: " .. desc,
      })
    end

    -- Navegação entre hunks
    gmap("n", "<leader>gn", function()
      gs.nav_hunk("next")
    end, "próximo hunk")

    gmap("n", "<leader>gp", function()
      gs.nav_hunk("prev")
    end, "hunk anterior")

    -- Visualização
    gmap("n", "<leader>gv", gs.preview_hunk, "visualizar hunk")
    gmap("n", "<leader>gi", gs.preview_hunk_inline, "visualizar hunk inline")

    -- Stage/reset do hunk atual
    gmap("n", "<leader>gs", gs.stage_hunk, "stage/unstage do hunk")
    gmap("n", "<leader>gr", gs.reset_hunk, "resetar hunk")

    -- Stage/reset de apenas parte de um hunk
    gmap("x", "<leader>gs", function()
      gs.stage_hunk({
        vim.fn.line("."),
        vim.fn.line("v"),
      })
    end, "stage/unstage da seleção")

    gmap("x", "<leader>gr", function()
      gs.reset_hunk({
        vim.fn.line("."),
        vim.fn.line("v"),
      })
    end, "resetar seleção")

    -- Arquivo inteiro
    gmap("n", "<leader>gS", gs.stage_buffer, "stage do arquivo")
    gmap("n", "<leader>gR", gs.reset_buffer, "resetar arquivo inteiro")

    -- Blame
    gmap("n", "<leader>gb", function()
      gs.blame_line({ full = true })
    end, "blame da linha")

    gmap(
      "n",
      "<leader>gB",
      gs.toggle_current_line_blame,
      "alternar blame permanente"
    )

    -- Diff
    gmap("n", "<leader>gd", gs.diffthis, "diff contra o index")

    gmap("n", "<leader>gD", function()
      gs.diffthis("~1")
    end, "diff contra o último commit")

    -- Lista de mudanças
    gmap("n", "<leader>gq", function()
      gs.setqflist(0)
    end, "mudanças deste arquivo")

    gmap("n", "<leader>gQ", function()
      gs.setqflist("all")
    end, "mudanças do repositório")

    -- Text object: vih, dih, yih etc.
    gmap({ "o", "x" }, "ih", gs.select_hunk, "selecionar hunk")
  end,
})

------------------------------------------------------------
-- Markdown: renderização -----------------------------------
------------------------------------------------------------
local render_markdown_ok, render_markdown =
  pcall(require, "render-markdown")

if render_markdown_ok then
  render_markdown.setup({
    enabled = true,

    -- Renderiza no modo normal, mas revela o Markdown
    -- original quando você entra no modo de inserção.
    render_modes = { "n", "c" },
  })
end

local markdown_render_group =
  vim.api.nvim_create_augroup("MarkdownRender", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = markdown_render_group,
  pattern = "markdown",

  callback = function(args)
    map("n", "<leader>md", function()
      local ok, renderer = pcall(require, "render-markdown")

      if ok then
        -- Alterna somente o arquivo Markdown atual.
        renderer.buf_toggle()
      end
    end, {
      buffer = args.buf,
      silent = true,
      desc = "Markdown: alternar renderização",
    })
  end,
})


------------------------------------------------------------
-- Markdown: comentários ME / AI ---------------------------
------------------------------------------------------------
local markdown_comments_group = vim.api.nvim_create_augroup(
  "MarkdownReviewComments",
  { clear = true }
)

------------------------------------------------------------
-- Cores ---------------------------------------------------
------------------------------------------------------------
local function set_markdown_comment_highlights()
  vim.api.nvim_set_hl(0, "MarkdownMeComment", {
    fg = "#98c379", -- verde claro
  })

  vim.api.nvim_set_hl(0, "MarkdownAiComment", {
    fg = "#e5c07b", -- amarelo claro
  })
end

set_markdown_comment_highlights()

-- Reaplica as cores caso você troque o colorscheme.
vim.api.nvim_create_autocmd("ColorScheme", {
  group = markdown_comments_group,
  callback = set_markdown_comment_highlights,
})

------------------------------------------------------------
-- Inserção dos comentários --------------------------------
------------------------------------------------------------

local function insert_markdown_comment(author)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_get_current_line()
  local indent = line:match("^%s*") or ""

  local timestamp = os.date("%Y-%m-%d-%H-%M-%S")

  local prefix = string.format(
    "<!-- %s: %s | ",
    author,
    timestamp
  )

  local comment = indent .. prefix .. " -->"

  -- Insere uma linha abaixo da atual.
  vim.api.nvim_buf_set_lines(0, row, row, false, {
    comment,
  })

  -- Deixa o cursor depois de "| " e antes do espaço final.
  vim.api.nvim_win_set_cursor(0, {
    row + 1,
    #indent + #prefix,
  })

  vim.cmd("startinsert")
end

------------------------------------------------------------
-- Localiza o comentário ME/AI sob o cursor ----------------
------------------------------------------------------------
local function find_markdown_comment_range()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local line_starts = {}
  local absolute = 1

  for row, line in ipairs(lines) do
    line_starts[row] = absolute
    absolute = absolute + #line + 1
  end

  local text = table.concat(lines, "\n")
  local cursor = vim.api.nvim_win_get_cursor(0)

  -- Posições absolutas são baseadas em 1.
  local cursor_absolute =
    line_starts[cursor[1]] + cursor[2]

  local search_from = 1

  while true do
    local open_start, open_end, author = text:find(
      "<!%-%-[ \t]*([%a]+)[ \t]*:",
      search_from
    )

    if not open_start then
      return nil
    end

    local close_start, close_end =
      text:find("%-%->", open_end + 1)

    if not close_start then
      return nil
    end

    author = author:upper()

    local is_review_comment =
      author == "ME" or author == "AI"

    local cursor_is_inside =
      cursor_absolute >= open_start
      and cursor_absolute <= close_end

    if is_review_comment and cursor_is_inside then
      -- Inicialmente, o conteúdo começa depois de "ME:" ou "AI:".
      local content_start = open_end + 1

      -- Procura um timestamp no formato:
      -- 2026-07-21-17-32-53 |
      local timestamp_start, timestamp_end = text:find(
        "[ \t]*%d%d%d%d%-%d%d%-%d%d%-%d%d%-%d%d%-%d%d[ \t]*|",
        content_start
      )

      -- Se houver timestamp, o text object interno começa depois do "|".
      if timestamp_start == content_start
          and timestamp_end
          and timestamp_end < close_start then
        content_start = timestamp_end + 1
      end

      local inner_start = content_start
      local inner_end = close_start - 1
      local inner_text = text:sub(inner_start, inner_end)

      -- Não inclui os espaços decorativos em "it".
      local leading_space =
        inner_text:match("^(%s*)") or ""

      local trailing_space =
        inner_text:match("(%s*)$") or ""

      return {
        line_starts = line_starts,

        -- Inclui <!-- ME: ... --> inteiro.
        outer_start = open_start,
        outer_end = close_end,

        -- Inclui somente o texto do comentário.
        inner_start = inner_start + #leading_space,
        inner_end = inner_end - #trailing_space,
      }
    end

    search_from = close_end + 1
  end
end

local function absolute_to_position(line_starts, offset)
  for row = #line_starts, 1, -1 do
    if offset >= line_starts[row] then
      return {
        row,
        offset - line_starts[row],
      }
    end
  end

  return { 1, 0 }
end

------------------------------------------------------------
-- Text objects: it e at -----------------------------------
------------------------------------------------------------
local function select_markdown_comment(around)
  local range = find_markdown_comment_range()

  if not range then
    return
  end

  local start_offset =
    around and range.outer_start or range.inner_start

  local end_offset =
    around and range.outer_end or range.inner_end

  if end_offset < start_offset then
    -- Isso só ocorre quando o comentário ainda está vazio.
    vim.notify(
      "O comentário está vazio.",
      vim.log.levels.INFO
    )
    return
  end

  -- Se chamado com vit/vat, encerra a seleção anterior.
  local mode = vim.fn.mode(1)

  if mode == "v" or mode == "V" or mode == "\22" then
    vim.cmd([[execute "normal! \<Esc>"]])
  end

  local start_position = absolute_to_position(
    range.line_starts,
    start_offset
  )

  local end_position = absolute_to_position(
    range.line_starts,
    end_offset
  )

  vim.api.nvim_win_set_cursor(0, start_position)
  vim.cmd("normal! v")
  vim.api.nvim_win_set_cursor(0, end_position)
end

-- Evita erro ao recarregar o init.lua.
pcall(
  vim.api.nvim_del_user_command,
  "MarkdownCommentInner"
)

pcall(
  vim.api.nvim_del_user_command,
  "MarkdownCommentAround"
)

vim.api.nvim_create_user_command(
  "MarkdownCommentInner",
  function()
    select_markdown_comment(false)
  end,
  {}
)

vim.api.nvim_create_user_command(
  "MarkdownCommentAround",
  function()
    select_markdown_comment(true)
  end,
  {}
)

------------------------------------------------------------
-- Configuração exclusiva para Markdown --------------------
------------------------------------------------------------
vim.api.nvim_create_autocmd("FileType", {
  group = markdown_comments_group,
  pattern = "markdown",

  callback = function(args)
    vim.opt_local.foldmethod = "manual"

    --------------------------------------------------------
    -- Coloração -------------------------------------------
    --------------------------------------------------------
    vim.cmd([[
      syntax region MarkdownMeComment
            \ start=/<!--\s*ME:/
            \ end=/-->/
            \ keepend
            \ contains=NONE
    ]])

    vim.cmd([[
      syntax region MarkdownAiComment
            \ start=/<!--\s*AI:/
            \ end=/-->/
            \ keepend
            \ contains=NONE
    ]])

    local function markdown_map(mode, lhs, rhs, options)
      options = options or {}
      options.buffer = args.buf
      options.silent = true

      vim.keymap.set(mode, lhs, rhs, options)
    end

    --------------------------------------------------------
    -- Atalhos de inserção ---------------------------------
    --------------------------------------------------------
    markdown_map("n", "<leader>cm", function()
      insert_markdown_comment("ME")
    end, {
      desc = "Markdown: inserir comentário ME",
    })

    markdown_map("n", "<leader>ca", function()
      insert_markdown_comment("AI")
    end, {
      desc = "Markdown: inserir comentário AI",
    })

    --------------------------------------------------------
    -- it: somente o conteúdo ------------------------------
    --------------------------------------------------------
    markdown_map({ "o", "x" }, "it", function()
      if find_markdown_comment_range() then
        return "<Cmd>MarkdownCommentInner<CR>"
      end

      -- Fora de um comentário ME/AI, mantém o it normal.
      return "it"
    end, {
      expr = true,
      desc = "Dentro do comentário Markdown",
    })

    --------------------------------------------------------
    -- at: comentário inteiro ------------------------------
    --------------------------------------------------------
    markdown_map({ "o", "x" }, "at", function()
      if find_markdown_comment_range() then
        return "<Cmd>MarkdownCommentAround<CR>"
      end

      -- Fora de um comentário ME/AI, mantém o at normal.
      return "at"
    end, {
      expr = true,
      desc = "Comentário Markdown inteiro",
    })
  end,
})
