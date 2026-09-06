-- Testes isolados, sem plugins externos ou instância do Neovim.
-- A partir da raiz do repositório: lua tests/git-conflicts.lua
-- Também funciona com: texlua tests/git-conflicts.lua
-- A API vim abaixo é um stub; folds e desenho da janela exigem
-- validação em uma instância real do Neovim.

local mapping
local state

vim = {
  api = {
    nvim_buf_get_lines = function(bufnr, first, last, strict)
      assert(bufnr == 0 and first == 0 and last == -1 and strict == false)
      return state.lines
    end,
    nvim_win_set_cursor = function(win, pos)
      assert(win == 0)
      state.cursor = { pos[1], pos[2] }
    end,
  },
  keymap = {
    set = function(mode, lhs, callback, opts)
      assert(mode == "n" and lhs == "<leader>gc")
      assert(opts.silent and opts.desc == "Git: primeiro conflito")
      assert(opts.buffer == nil, "O atalho deve funcionar sem on_attach")
      mapping = callback
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

dofile("plugin/git-conflicts.lua")
assert(type(mapping) == "function")

local function check(name, lines, initial, expected)
  state = { lines = lines, cursor = initial, commands = {}, notifications = {} }
  local contents_before = table.concat(lines, "\n")
  mapping()
  assert(table.concat(lines, "\n") == contents_before, name .. ": conteúdo alterado")

  if expected then
    assert(state.cursor[1] == expected and state.cursor[2] == 0, name)
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

local conflicts = {
  "introdução", "<<<<<<< HEAD", "nosso lado", "=======", "outro lado", ">>>>>>> branch",
  "entre conflitos", "<<<<<<< HEAD", "nosso lado", "=======", "outro lado", ">>>>>>> branch",
}
check("primeiro conflito mesmo começando depois do segundo", conflicts, { 12, 4 }, 2)
check("primeiro conflito a partir do topo", conflicts, { 1, 0 }, 2)
check("cursor já no primeiro marcador", conflicts, { 2, 3 }, 2)
check("marcador na primeira linha", { "<<<<<<< HEAD", "conteúdo" }, { 2, 3 }, 1)
check("marcador com mais de sete caracteres", { "texto", "<<<<<<<<<< HEAD" }, { 1, 2 }, 2)
check("estilo diff3", { "<<<<<<< HEAD", "a", "||||||| base", "b", "=======", "c", ">>>>>>> branch" }, { 7, 0 }, 1)
check("ignora texto inline, recuado e marcador curto", { "texto <<<<<<< HEAD", " <<<<<<< HEAD", "<<<<<< HEAD" }, { 3, 2 })
check("ignora separadores sem abertura", { "||||||| base", "=======", ">>>>>>> branch" }, { 2, 3 })
check("arquivo sem conflitos mantém o cursor", { "primeira", "segunda" }, { 2, 3 })
check("buffer vazio", { "" }, { 1, 0 })

-- Recarregar o arquivo deve substituir o atalho sem erro.
dofile("plugin/git-conflicts.lua")
check("recarregamento e conteúdo atual do buffer", { "novo texto", "<<<<<<< HEAD" }, { 1, 0 }, 2)
print("11 testes passaram (API do Neovim simulada).")
