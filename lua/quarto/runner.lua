--- Code runner, configurable to use different engines.
local Runner = {}

local otterkeeper = require 'otter.keeper'

local function concat(ls)
  if type(ls) ~= "table" then
    return ls .. "\n\n"
  end
  local s = ""
  for _, l in ipairs(ls) do
    if l ~= "" then
      s = s .. "\n" .. l
    end
  end
  return s .. "\n"
end

local function send(lines)
  lines = concat(lines)
  local success, yarepl = pcall(require, "yarepl")
  if success then
    yarepl._send_strings(0)
  else
    vim.fn["slime#send"](lines)
    if success then
      vim.fn.notify(
        "Install a REPL code sending plugin to use this feature. Options are yarepl.nvim and vim-slim."
      )
    end
  end
end

Runner.run_cell = function()
  local lines = otterkeeper.get_language_lines_around_cursor()
  if lines == nil then
    print("No code chunk detected around cursor")
    return
  end
  send(lines)
end

Runner.run_above = function()
  local lines = otterkeeper.get_language_lines_to_cursor(true)
  if lines == nil then
    print(
      "No code chunks found for the current language, which is detected based on the current code block. Is your cursor in a code block?"
    )
    return
  end
  send(lines)
end

Runner.run_below = function()
  local lines = otterkeeper.get_language_lines_from_cursor(true)
  if lines == nil then
    print(
      "No code chunks found for the current language, which is detected based on the current code block. Is your cursor in a code block?"
    )
    return
  end
  send(lines)
end

Runner.run_all = function()
  local lines = otterkeeper.get_language_lines(true)
  if lines == nil then
    print(
      "No code chunks found for the current language, which is detected based on the current code block. Is your cursor in a code block?"
    )
    return
  end
  send(lines)
end

Runner.run_range = function()
  local lines = otterkeeper.get_language_lines_in_visual_selection(true)
  if lines == nil then
    print(
      "No code chunks found for the current language, which is detected based on the current code block. Is your cursor in a code block?"
    )
    return
  end
  send(lines)
end
