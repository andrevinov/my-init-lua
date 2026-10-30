-- A partir da raiz do repositório: texlua tests/fugitive-keymaps.lua
-- Testa mapeamentos, navegação e ausência de sobrescrita de atalhos
-- existentes. Não depende de plugins externos nem de Neovim.

local maps = {}
local state

-- Atalhos já usados em init.lua e plugin/git-conflicts.lua.
for _, key in ipairs({
  "n", "p", "v", "i", "s", "r", "S", "R", "b", "B", "d", "D", "q", "Q", "c",
}) do
  maps["<leader>g" .. key] = { existing = true }
end

vim = {
  keymap = {
    set = function(mode, lhs, rhs, opts)
      assert(mode == "n", lhs .. ": modo incorreto")
      assert(maps[lhs] == nil, lhs .. ": sobrescreveu atalho existente")
      assert(opts.silent and type(opts.desc) == "string", lhs)
      maps[lhs] = { rhs = rhs, desc = opts.desc }
    end,
  },
  api = {
    nvim_buf_get_lines = function(bufnr, first, last, strict)
      assert(bufnr == 0 and first == 0 and last == -1 and strict == false)
      return state.lines
    end,
    nvim_win_get_cursor = function(win)
      assert(win == 0)
      return state.cursor
    end,
    nvim_win_set_cursor = function(win, cursor)
      assert(win == 0)
      state.cursor = { cursor[1], cursor[2] }
    end,
  },
  cmd = function(command)
    state.commands[#state.commands + 1] = command
    if command == "normal! m'" then
      state.previous = { state.cursor[1], state.cursor[2] }
    end
  end,
  notify = function(message, level)
    state.notifications[#state.notifications + 1] = { message, level }
  end,
  log = { levels = { INFO = 2 } },
}

dofile("plugin/fugitive-keymaps.lua")

local commands = {
  gg = "Git", gf = "Gvdiffsplit", gl = "Git blame", gh = "0Gclog",
  gw = "Gwrite", gm = "Git mergetool", gxd = "Gvdiffsplit!",
  gxo = "diffget //2", gxt = "diffget //3",
}

for suffix, command in pairs(commands) do
  local mapping = maps["<leader>" .. suffix]
  assert(mapping and mapping.rhs == "<cmd>" .. command .. "<CR>", suffix)
  assert(mapping.desc:match("^Fugitive:"), suffix)
end

assert(maps["<leader>gc"].existing, "mapeamento do primeiro conflito foi alterado")
assert(type(maps["<leader>gxn"].rhs) == "function")
assert(type(maps["<leader>gxp"].rhs) == "function")

local conflicts = {
  "a", "<<<<<<< HEAD", "ours", "=======", "theirs", ">>>>>>> other",
  "b", "<<<<<<< HEAD", "ours 2", "=======", "theirs 2", ">>>>>>> other",
}

local function check(name, key, lines, initial, target)
  state = {
    lines = lines,
    cursor = { initial[1], initial[2] },
    commands = {},
    notifications = {},
  }
  local content = table.concat(lines, "\n")
  maps[key].rhs()
  assert(table.concat(lines, "\n") == content, name .. ": modificou conteúdo")

  if target then
    assert(state.cursor[1] == target and state.cursor[2] == 0, name)
    assert(state.previous[1] == initial[1] and state.previous[2] == initial[2], name)
    assert(#state.commands == 2, name)
    assert(state.commands[1] == "normal! m'" and state.commands[2] == "normal! zvzz", name)
    assert(#state.notifications == 0, name)
  else
    assert(state.cursor[1] == initial[1] and state.cursor[2] == initial[2], name)
    assert(#state.commands == 0 and state.previous == nil, name)
    assert(#state.notifications == 1, name)
    assert(state.notifications[1][1] == "Nenhum marcador de conflito neste buffer.", name)
    assert(state.notifications[1][2] == vim.log.levels.INFO, name)
  end
  print("PASS: " .. name)
end

check("proximo no inicio", "<leader>gxn", conflicts, {1, 0}, 2)
check("proximo no primeiro conflito", "<leader>gxn", conflicts, {2, 0}, 8)
check("proximo apos o ultimo da a volta", "<leader>gxn", conflicts, {12, 2}, 2)
check("anterior apos o ultimo", "<leader>gxp", conflicts, {12, 0}, 8)
check("anterior no segundo conflito", "<leader>gxp", conflicts, {8, 0}, 2)
check("anterior antes do primeiro da a volta", "<leader>gxp", conflicts, {1, 0}, 8)
check("ignora marcadores indentados e inline", "<leader>gxn", {"a <<<<<<< HEAD", " <<<<<<< HEAD", "b"}, {1, 0})
check("ignora separadores sem abertura", "<leader>gxp", {"=======", ">>>>>>> other"}, {1, 0})
check("buffer vazio", "<leader>gxn", {}, {1, 0})
check("sem conflitos", "<leader>gxp", {"a", "b"}, {2, 1})
check("um unico conflito", "<leader>gxn", {"<<<<<<< HEAD", "ours"}, {1, 4}, 1)
print("PASS: 9 comandos e 11 cenarios de navegacao; atalhos anteriores preservados.")
