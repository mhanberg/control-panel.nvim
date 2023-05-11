local Text = require("control_panel.text")

local Panel = {}

function Panel.new(buf)
  local p = setmetatable({}, { __index = Panel })

  p.buf = buf
  p.tabs = {}

  return p
end

local buf
local panel
local win

function Panel:set(tab)
  self.current = tab
  self:render()
end

function Panel:tab(opts)
  local name = opts.name
  local text = Text.new()
  local key = opts.key
  text.padding = 2
  text.wrap = 120

  vim.keymap.set("n", key, function()
    panel:set(name)
  end, { buffer = self.buf })

  self.tabs[name] = { text = text, key = key }

  if self.current == nil then
    self.current = name
  end

  return self
end

function Panel:append(opts)
  local tab = opts.tab
  local text = opts.text
  self.tabs[tab].text:append(text)
  self.tabs[tab].text:nl()

  return self
end

function Panel:render()
  local text = Text.new()

  text.padding = 2
  text.wrap = 120

  text:nl():nl()
  local first = true

  for tabname, tab in pairs(self.tabs) do
    local hl
    if tabname == self.current then
      hl = "Visual"
    else
      hl = "Normal"
    end

    if not first then
      text:append(" ")
    else
      first = false
    end
    text:append(" " .. tabname .. " (" .. tab.key .. ") ", hl, { wrap = true })
    text:highlight({ ["%(.%)"] = "@punctuation.special" })
  end

  text:nl():nl()

  local body = text:concat(self.tabs[self.current].text)
  body.padding = 2
  body.wrap = 120

  body:render(self.buf)

  vim.api.nvim_set_current_win(win)

  return self
end

local M = {}

local function new_win()
  local columns = vim.o.columns
  local lines = vim.o.lines
  local width = math.ceil(columns * 0.8)
  local height = math.ceil(lines * 0.8)

  local col = (columns - width) / 2
  local row = ((lines - height) / 2) - 2

  return vim.api.nvim_open_win(buf, true, {
    style = "minimal",
    relative = "win",
    row = row,
    col = col,
    width = width,
    height = height,
  })
end

function M.setup()
  buf = vim.api.nvim_create_buf(0, 0)
  panel = Panel.new(buf)

  vim.api.nvim_create_user_command("ToggleControlPanel", M.toggle, {})
end

function M.toggle()
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  else
    if not win or not vim.api.nvim_win_is_valid(win) then
      win = new_win()
    end

    panel:render()
  end
end

function M.panel()
  return panel
end

return M
