local core = require "core"
local config = require "core.config"
local common = require "core.common"
local command = require "core.command"
local View = require "core.view"
local style = require "core.style"
local RootView = require "core.rootview"

config.nagbar_color = { common.color "#FF0000" }
config.nagbar_text_color = { common.color "#FFFFFF" }
config.nagbar_dim_color = { common.color "rgba(0, 0, 0, 0.45)" }

local BORDER_WIDTH = common.round(2 * SCALE)
local BORDER_PADDING = common.round(5 * SCALE)

local NagView = View:extend()

function NagView:new()
  NagView.super.new(self)
  self.size.y = 0
  self.title = "Warning"
  self.message = ""
  self.options = {}
end

function NagView:get_title()
  return self.title
end

function NagView:get_options_height()
  local max = 0
  for _, text in ipairs(self.options) do
    local lh = style.font:get_height(text)
    if lh > max then max = lh end
  end
  return max
end

function NagView:get_line_height()
  if core.active_view == self then
    return 2 * BORDER_WIDTH + 2 * BORDER_PADDING + math.max(style.font:get_height(self.message), self:get_options_height()) + style.padding.y
   else
    return 0
  end
end

function NagView:get_scrollable_size()
  return 0
end

function NagView:update()
  NagView.super.update(self)
  local dest = self:get_line_height()
  self:move_towards(self.size, "y", dest)
end

function NagView:draw_overlay()
  local ox, oy = self:get_content_offset()
  oy = oy + self.size.y
  local w, h = core.root_view.size.x, core.root_view.size.y - oy
  core.root_view:defer_draw(function()
    renderer.draw_rect(ox, oy, w, h, config.nagbar_dim_color)
  end)
end

function NagView:each_option()
  return coroutine.wrap(function()
    local halfh = math.floor(self.size.y / 2)
    local ox, oy = self:get_content_offset()
    ox = ox + self.size.x - style.padding.x

    for i, v in ipairs(self.options) do
      local lw, lh = style.font:get_width(v), style.font:get_height(v)
      local bw, bh = (lw + 2 * BORDER_WIDTH + 2 * BORDER_PADDING), (lh + 2 * BORDER_WIDTH + 2 * BORDER_PADDING)
      local halfbh = math.floor(bh / 2)
      local box, boy = math.max(0, ox - bw), math.max(0, oy + halfh - halfbh)
      local fw, fh = bw - 2 * BORDER_WIDTH, bh - 2 * BORDER_WIDTH
      local fox, foy = box + BORDER_WIDTH, boy + BORDER_WIDTH
      coroutine.yield(i, box, boy, bw, bh, fox, foy, fw, fh, v)
      ox = ox - bw - style.padding.x
    end
  end)
end

function NagView:on_mouse_moved(x, y, ...)
  NagView.super.on_mouse_moved(self, x, y, ...)

  local selected = false
  for i, ox, oy, w, h in self:each_option() do
    if x >= ox and y >= oy and x < ox + w and y < oy + h then
      self.selected = i
      selected = true
      break
    end
  end

  if not selected then self.selected = nil end
end

function NagView:on_mouse_pressed(...)
  if not NagView.super.on_mouse_pressed(self, ...) and self.selected then
    core.set_active_view(core.last_active_view, true)
    self:on_select(self.options[self.selected])
  end
end

function NagView:on_select(item)
  print(item)
end

function NagView:draw()
  if self.size.y <= 0 then return end

  self:draw_overlay()
  self:draw_background(config.nagbar_color)

  -- draw message
  local ox, oy = self:get_content_offset()
  common.draw_text(style.font, config.nagbar_text_color, self.message, "left", ox + style.padding.x, oy, self.size.x, self.size.y)

  -- draw buttons
  for i, box, boy, bw, bh, fox, foy, fw, fh, text in self:each_option() do
    local fill = i == self.selected and config.nagbar_text_color or config.nagbar_color
    local text_color = i == self.selected and config.nagbar_color or config.nagbar_text_color

    renderer.draw_rect(box, boy, bw, bh, config.nagbar_text_color)

    if i ~= self.selected then
      renderer.draw_rect(fox, foy, fw, fh, fill)
    end

    common.draw_text(style.font, text_color, text, "center", fox, foy, fw, fh)
  end
end

function NagView:show(title, message, options)
  self.title = title or "Warning"
  self.message = message or ""
  self.options = options or {}
  core.set_active_view(self)
end

core.nagview = NagView()

local last_view = core.active_view
-- this method prevents splitting non-leaf node error while preserving the tree structure
local node = RootView().root_node -- Node is not exported so we have to get it this way ;-;
node:split("up", core.nagview, true)
node.b:consume(core.root_view.root_node.a)
core.root_view.root_node.a = node
core.set_active_view(last_view)

local set_active_view = core.set_active_view
function core.set_active_view(view, override)
  if core.active_view == core.nagview and not override then return end -- prevent stealing focus
  set_active_view(view)
end

-- TESTING CODE
command.add(nil, {
  ["nagbar:show"] = function()
    core.nagview:show("PLEASE NO", "NO", { "lmao", "wut" })
  end
})
