local M = {}
local api = vim.api
local util = require "lspconfig.util"
local tools = require 'quarto.tools'
local otter = require 'otter'
local otterkeeper = require 'otter.keeper'

M.defaultConfig = {
  debug = false,
  closePreviewOnExit = true,
  lspFeatures = {
    enabled = true,
    chunks = 'curly',
    languages = { 'r', 'python', 'julia', 'bash', 'html' },
    diagnostics = {
      enabled = true,
      triggers = { "BufWritePost" }
    },
    completion = {
      enabled = true,
    },
  },
  keymap = {
    hover = 'K',
    definition = 'gd',
    rename = '<leader>lR',
    references = 'gr',
  }
}

function M.quartoPreview()
  -- find root directory / check if it is a project
  local buffer_path = api.nvim_buf_get_name(0)
  local root_dir = util.root_pattern("_quarto.yml")(buffer_path)
  local cmd
  local mode
  if root_dir then
    mode = "project"
    cmd = 'quarto preview'
  else
    mode = "file"
    if vim.loop.os_uname().sysname == "Windows_NT" then
      cmd = 'quarto preview \\"' .. buffer_path .. '\\"'
    else
      cmd = 'quarto preview \'' .. buffer_path .. '\''
    end
  end

  local quarto_extensions = { ".qmd", ".Rmd", ".ipynb", ".md" }
  local file_extension = buffer_path:match("^.+(%..+)$")
  if mode == "file" and not file_extension then
    vim.notify("Not in a file. exiting.")
    return
  end
  if mode == "file" and not tools.contains(quarto_extensions, file_extension) then
    vim.notify("Not a quarto file, ends in " .. file_extension .. " exiting.")
    return
  end

  -- run command in embedded terminal
  -- in a new tab and go back to the buffer
  vim.cmd('tabedit term://' .. cmd)
  local quartoOutputBuf = vim.api.nvim_get_current_buf()
  vim.cmd('tabprevious')
  api.nvim_buf_set_var(0, 'quartoOutputBuf', quartoOutputBuf)

  if not M.config then
    return
  end

  -- close preview terminal on exit of the quarto buffer
  if M.config.closePreviewOnExit then
    api.nvim_create_autocmd({ "QuitPre", "WinClosed" }, {
      buffer = api.nvim_get_current_buf(),
      group = api.nvim_create_augroup("quartoPreview", {}),
      callback = function(_, _)
        if api.nvim_buf_is_loaded(quartoOutputBuf) then
          api.nvim_buf_delete(quartoOutputBuf, { force = true })
        end
      end
    })
  end
end

function M.quartoClosePreview()
  local success, quartoOutputBuf = pcall(api.nvim_buf_get_var, 0, 'quartoOutputBuf')
  if not success then return end
  if api.nvim_buf_is_loaded(quartoOutputBuf) then
    api.nvim_buf_delete(quartoOutputBuf, { force = true })
  end
end

M.searchHelp = function(cmd_input)
  local topic = cmd_input.args
  local url = 'https://quarto.org/?q=' .. topic .. '&show-results=1'
  local sysname = vim.loop.os_uname().sysname
  local cmd
  if sysname == "Linux" then
    cmd = 'xdg-open "' .. url .. '"'
  elseif sysname == "Darwin" then
    cmd = 'open "' .. url .. '"'
  else
    print(
      'sorry, I do not know how to make Windows open a url with the default browser. This feature currently only works on linux and mac.')
    return
  end
  vim.fn.jobstart(cmd)
end

M.activate = function()
  local tsquery = nil
  if M.config.lspFeatures.chunks == 'curly' then
    tsquery = [[
      (fenced_code_block
      (info_string
        (language) @_lang
      ) @info
        (#match? @info "{")
      (code_fence_content) @content (#offset! @content)
      )
      ((html_block) @html @combined)

      ((minus_metadata) @yaml (#offset! @yaml 1 0 -1 0))
      ((plus_metadata) @toml (#offset! @toml 1 0 -1 0))

      ]]
  end
  otter.activate(M.config.lspFeatures.languages, M.config.lspFeatures.completion.enabled,
    M.config.lspFeatures.diagnostics.enabled, tsquery)
end

-- setup
M.setup = function(opt)
  M.config = vim.tbl_deep_extend('force', M.defaultConfig, opt or {})

  api.nvim_create_autocmd({ "BufEnter" }, {
    pattern = { "*.qmd" },
    group = vim.api.nvim_create_augroup('QuartoSetup', {}),
    desc = 'set up quarto',
    callback = function()
      if M.config.lspFeatures.enabled and vim.bo.buftype ~= 'terminal' then
        M.activate()

        vim.api.nvim_buf_set_keymap(0, 'n', M.config.keymap.definition, ":lua require'otter'.ask_definition()<cr>",
          { silent = true })
        vim.api.nvim_buf_set_keymap(0, 'n', M.config.keymap.hover, ":lua require'otter'.ask_hover()<cr>",
          { silent = true })
        vim.api.nvim_buf_set_keymap(0, 'n', M.config.keymap.rename, ":lua require'otter'.ask_rename()<cr>",
          { silent = true })
        vim.api.nvim_buf_set_keymap(0, 'n', M.config.keymap.references, ":lua require'otter'.ask_references()<cr>",
          { silent = true })
      end
    end,
  })
end

local function concat(ls)
  local s = ''
  for _, l in ipairs(ls) do
    if l ~= '' then
      s = s .. '\n' .. l
    end
  end
  return s .. '\n'
end

local function send(lines)
  local yarepl = require 'yarepl'
  lines = concat(lines)

  if yarepl ~= nil then
    yarepl._send_strings(0, 'ipython')
  else
    local success, error = pcall(vim.fn[vim.fn['slime#send'](lines)])
    if not success then
      vim.fn.notify('Install a REPL code sending plugin to use this feature. Options are yarepl.nvim and vim-slim.')
    end
  end
end

M.quartoSendAbove = function()
  local lines = otterkeeper.get_language_lines_to_cursor(true)
  if lines == nil then
    print(
      'No code chunks found for the current language, which is detected based on the current code block. Is your cursor in a code block?')
    return
  end
  send(lines)
end


M.quartoSendBelow = function()
  local lines = otterkeeper.get_language_lines_from_cursor(true)
  if lines == nil then
    print(
      'No code chunks found for the current language, which is detected based on the current code block. Is your cursor in a code block?')
    return
  end
  send(lines)
end


M.quartoSendAll = function()
  local lines = otterkeeper.get_language_lines(true)
  if lines == nil then
    print(
      'No code chunks found for the current language, which is detected based on the current code block. Is your cursor in a code block?')
    return
  end
  send(lines)
end

M.quartoSendRange = function()
  local lines = otterkeeper.get_language_lines_in_visual_selection(true)
  if lines == nil then
    print(
      'No code chunks found for the current language, which is detected based on the current code block. Is your cursor in a code block?')
    return
  end
  send(lines)
end



return M
