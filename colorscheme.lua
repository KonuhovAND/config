local DAY_START = 7 -- 07:00 -> switch to morning
local DAY_END = 19 -- 19:00 -> switch back to default

local function is_day()
  local h = tonumber(os.date("%H"))
  return h >= DAY_START and h < DAY_END
end

local function apply()
  if is_day() then
    vim.o.background = "light"
    vim.cmd.colorscheme("morning")
  else
    vim.o.background = "dark"
    vim.cmd.colorscheme("default")
  end
end

-- Re-check every 10 minutes while Neovim is open
vim.fn.timer_start(10 * 60 * 1000, apply, { ["repeat"] = -1 })

return {
  -- Pick the right scheme for the very first frame at startup
  { "LazyVim/LazyVim", opts = { colorscheme = is_day() and "morning" or "default" } },
}
