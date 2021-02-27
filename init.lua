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

function NagView:each_option()
  return coroutine.wrap(function()
    for i = #self.options, 1, -1 do
      coroutine.yield(i, self.options[i])
    end
  end)
end

function NagView:get_options_height()
  local max = 0
  for _, opt in ipairs(self.options) do
    local lh = style.font:get_height(opt.text)
    if lh > max then max = lh end
  end
  return max
end

function NagView:get_line_height()
  local maxlh = math.max(style.font:get_height(self.message), self:get_options_height())
  return 2 * BORDER_WIDTH + 2 * BORDER_PADDING + maxlh + 2 * style.padding.y
end

function NagView:update()
  NagView.super.update(self)

  local dest = core.active_view == self and self:get_line_height() or 0
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

function NagView:each_visible_option()
  return coroutine.wrap(function()
    local halfh = math.floor(self.size.y / 2)
    local ox, oy = self:get_content_offset()
    ox = ox + self.size.x - style.padding.x

    for i, opt in self:each_option() do
      local lw, lh = opt.font:get_width(opt.text), opt.font:get_height(opt.text)
      local bw, bh = (lw + 2 * BORDER_WIDTH + 2 * BORDER_PADDING), (lh + 2 * BORDER_WIDTH + 2 * BORDER_PADDING)
      local halfbh = math.floor(bh / 2)
      local bx, by = math.max(0, ox - bw), math.max(0, oy + halfh - halfbh)
      local fw, fh = bw - 2 * BORDER_WIDTH, bh - 2 * BORDER_WIDTH
      local fx, fy = bx + BORDER_WIDTH, by + BORDER_WIDTH
      coroutine.yield(i, opt, bx,by,bw,bh, fx,fy,fw,fh)
      ox = ox - bw - style.padding.x
    end
  end)
end

function NagView:on_mouse_moved(mx, my, ...)
  NagView.super.on_mouse_moved(self, mx, my, ...)

  local selected = false
  for i, _, x,y,w,h in self:each_visible_option() do
    if mx >= x and my >= y and mx < x + w and my < y + h then
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
end

function NagView:draw()
  if self.size.y <= 0 then return end

  self:draw_overlay()
  self:draw_background(config.nagbar_color)

  -- draw message
  local ox, oy = self:get_content_offset()
  common.draw_text(style.font, config.nagbar_text_color, self.message, "left", ox + style.padding.x, oy, self.size.x, self.size.y)

  -- draw buttons
  for i, opt, bx,by,bw,bh, fx,fy,fw,fh in self:each_visible_option() do
    local fill = i == self.selected and config.nagbar_text_color or config.nagbar_color
    local text_color = i == self.selected and config.nagbar_color or config.nagbar_text_color

    renderer.draw_rect(bx,by,bw,bh, config.nagbar_text_color)

    if i ~= self.selected then
      renderer.draw_rect(fx,fy,fw,fh, fill)
    end

    common.draw_text(opt.font, text_color, opt.text, "center", fx,fy,fw,fh)
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
