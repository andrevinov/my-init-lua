------------------------------------------------------------
-- Python runner interativo --------------------------------
------------------------------------------------------------
-- Executa arquivos Python em um terminal buffer dedicado,
-- mantendo stdin/PTY disponível para input(), pdb etc.
local python_runner = {
  buf = 0,
  win = 0,
  job = 0,
}

local uv = vim.uv or vim.loop

local function valid_win(win)
  return win ~= 0 and vim.api.nvim_win_is_valid(win)
end

local function valid_buf(buf)
  return buf ~= 0 and vim.api.nvim_buf_is_valid(buf)
end

local function path_exists(path, expected_type)
  local stat = uv.fs_stat(path)
  return stat and stat.type == expected_type
end

local function find_upwards(start_dir, callback)
  local dir = vim.fn.fnamemodify(start_dir, ':p')

  while dir and dir ~= '' do
    dir = dir:gsub('/+$', '')

    local result = callback(dir)
    if result then
      return result, dir
    end

    local parent = vim.fn.fnamemodify(dir, ':h')
    if parent == dir then
      break
    end

    dir = parent
  end

  return nil, nil
end

local function get_python_runner(file)
  local file_dir = vim.fn.fnamemodify(file, ':p:h')

  local venv_python, venv_root = find_upwards(file_dir, function(dir)
    local python = dir .. '/.venv/bin/python'

    if path_exists(python, 'file') then
      return python
    end
  end)

  if venv_python then
    return { venv_python }, venv_root
  end

  local _, project_root = find_upwards(file_dir, function(dir)
    return path_exists(dir .. '/pyproject.toml', 'file')
      or path_exists(dir .. '/poetry.lock', 'file')
      or path_exists(dir .. '/.git', 'directory')
  end)

  if project_root
      and path_exists(project_root .. '/poetry.lock', 'file')
      and vim.fn.executable('poetry') == 1 then
    return { 'poetry', 'run', 'python' }, project_root
  end

  return { 'python3' }, project_root or file_dir
end

local function reset_runner_state()
  python_runner.buf = 0
  python_runner.win = 0
  python_runner.job = 0
end

local function close_python_runner()
  local old_buf = python_runner.buf
  local old_win = python_runner.win
  local old_job = python_runner.job

  reset_runner_state()

  if old_job > 0 then
    pcall(vim.fn.jobstop, old_job)
  end

  if valid_win(old_win) then
    pcall(vim.api.nvim_win_close, old_win, true)
  elseif valid_buf(old_buf) then
    pcall(vim.api.nvim_buf_delete, old_buf, { force = true })
  end
end

local function run_python_file()
  local source_buf = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(source_buf)

  if file == '' then
    vim.notify('Python runner: salve o arquivo antes de executar.', vim.log.levels.WARN)
    return
  end

  local ok, err = pcall(vim.cmd, 'write')
  if not ok then
    vim.notify('Python runner: não foi possível salvar o arquivo: ' .. tostring(err), vim.log.levels.ERROR)
    return
  end

  local runner, root = get_python_runner(file)
  local command = vim.deepcopy(runner)
  table.insert(command, file)

  -- Cada execução substitui o runner anterior, evitando splits acumuladas.
  close_python_runner()

  vim.cmd('botright new')
  vim.cmd('resize 12')

  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()

  python_runner.buf = buf
  python_runner.win = win

  vim.bo[buf].buflisted = false
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false

  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = 'no'
  vim.wo[win].winfixheight = true

  local job = vim.fn.termopen(command, {
    cwd = root,
    on_exit = function()
      vim.schedule(function()
        if python_runner.buf == buf then
          python_runner.job = 0
        end
      end)
    end,
  })

  if job <= 0 then
    vim.notify('Python runner: falha ao iniciar o processo Python.', vim.log.levels.ERROR)
    close_python_runner()
    return
  end

  python_runner.job = job

  -- Esc sai do modo terminal para navegar pelo output.
  vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]], {
    buffer = buf,
    silent = true,
  })

  -- Em modo normal, q fecha somente o runner.
  vim.keymap.set('n', 'q', close_python_runner, {
    buffer = buf,
    silent = true,
    desc = 'Fechar Python runner',
  })

  vim.cmd('startinsert')
end

vim.api.nvim_create_user_command('PythonRun', run_python_file, {
  force = true,
  desc = 'Executar arquivo Python em terminal interativo',
})

local group = vim.api.nvim_create_augroup('InteractivePythonRunner', { clear = true })

vim.api.nvim_create_autocmd('FileType', {
  group = group,
  pattern = 'python',
  callback = function(args)
    vim.keymap.set('n', '<leader>r', run_python_file, {
      buffer = args.buf,
      silent = true,
      desc = 'Run Python file (interactive)',
    })

    vim.keymap.set('i', '<leader>r', function()
      vim.cmd('stopinsert')
      run_python_file()
    end, {
      buffer = args.buf,
      silent = true,
      desc = 'Run Python file (interactive)',
    })
  end,
})
