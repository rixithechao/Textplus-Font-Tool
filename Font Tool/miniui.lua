-- a basic ui lib. I made this so when its time to make the real deal, I have at least an idea of what type of features it really needs ~setayoshi
local lib = {}

local textplus = require("textplus")
local cursor = require("cursor")

local uiFont = textplus.loadFont("textplus/font/4.ini")
local isActiveBuffer = false
local activeBuffer = ""

local ceil, min = math.ceil, math.min

local buttonGfx = {
    left = Graphics.loadImageResolved("button_left.png"),
    right = Graphics.loadImageResolved("button_right.png"),
    up = Graphics.loadImageResolved("button_up.png"),
    down = Graphics.loadImageResolved("button_down.png"),
    reset = Graphics.loadImageResolved("button_reset.png"),
}

local lineEditGFX = Graphics.loadImageResolved("lineEdit.png")


local activeWidgets = {}

local function advance(x, min, max, wrap)
  if wrap then
    return ((x - max + min - 1) % (min - max - 1)) + max
  else
    return math.clamp(x, min, max)
  end
end

local function drawTextureBox(texture, coll, sx, sy, sw, sh)

  local width, height = vector(coll.width, 0), vector(0, coll.height)
  local z1 = vector(coll.x, coll.y)
  local z2, z3, z4 = z1 + height, z1 + width, z1 + width + height

  local tx, ty = sx/texture.width, sy/texture.height
  local tw, th = (sx + sw)/texture.width, (sy + sh)/texture.height


  local vertexCoords = {z1.x, z1.y, z2.x, z2.y, z4.x, z4.y, z1.x, z1.y, z3.x, z3.y, z4.x, z4.y}
  local textureCoords = {tx, ty, tx, th, tw, th, tx, ty, tw, ty, tw, th}

  Graphics.glDraw{texture = texture, vertexCoords = vertexCoords,textureCoords = textureCoords, priority = 0,}
end

-- Big thanks to MDA for supplying this function
local function drawSegmentedBox(args)
  local texture = args.texture or args.image
  local target = args.target or nil

  local priority = args.priority or 0
  local sceneCoords = args.sceneCoords or false
  local color = args.color or Color.white

  local x = args.x
  local y = args.y
  local width = args.width
  local height = args.height

  local segmentWidth = texture.width / 3
  local segmentHeight = texture.height / 3

  local segmentCountX = ceil(width / segmentWidth)
  local segmentCountY = ceil(height / segmentHeight)


  local vertexCoords = {}
  local textureCoords = {}
  local vertexCount = 0

  for segmentX = 1,segmentCountX do
    for segmentY = 1,segmentCountY do
      local thisX = x
      local thisY = y
      local thisWidth = min(width*0.5,segmentWidth)
      local thisHeight = min(height*0.5,segmentHeight)
      local thisSourceX = 0
      local thisSourceY = 0

      if segmentX == segmentCountX then
        thisX = thisX + width - thisWidth
        thisSourceX = texture.width - thisWidth
      elseif segmentX > 1 then
        thisX = thisX + thisWidth + (segmentX-2)*segmentWidth
        thisWidth = min(width - segmentWidth - (thisX - x),segmentWidth)
        thisSourceX = segmentWidth
      end

      if segmentY == segmentCountY then
        thisY = thisY + height - thisHeight
        thisSourceY = texture.height - thisHeight
      elseif segmentY > 1 then
        thisY = thisY + thisHeight + (segmentY-2)*segmentHeight
        thisHeight = min(height - segmentHeight - (thisY - y),segmentHeight)
        thisSourceY = segmentHeight
      end


      if thisWidth > 0 and thisHeight > 0 then
        -- Add to vertexCoords
        local x1 = thisX
        local y1 = thisY
        local x2 = thisX + thisWidth
        local y2 = thisY + thisHeight

        vertexCoords[vertexCount+1 ] = x1 -- top left
        vertexCoords[vertexCount+2 ] = y1
        vertexCoords[vertexCount+3 ] = x1 -- bottom left
        vertexCoords[vertexCount+4 ] = y2
        vertexCoords[vertexCount+5 ] = x2 -- top right
        vertexCoords[vertexCount+6 ] = y1
        vertexCoords[vertexCount+7 ] = x1 -- bottom left
        vertexCoords[vertexCount+8 ] = y2
        vertexCoords[vertexCount+9 ] = x2 -- top right
        vertexCoords[vertexCount+10] = y1
        vertexCoords[vertexCount+11] = x2 -- bottom right
        vertexCoords[vertexCount+12] = y2

        -- Add to textureCoords
        local x1 = thisSourceX / texture.width
        local y1 = thisSourceY / texture.height
        local x2 = (thisSourceX + thisWidth) / texture.width
        local y2 = (thisSourceY + thisHeight) / texture.height

        textureCoords[vertexCount+1 ] = x1 -- top left
        textureCoords[vertexCount+2 ] = y1
        textureCoords[vertexCount+3 ] = x1 -- bottom left
        textureCoords[vertexCount+4 ] = y2
        textureCoords[vertexCount+5 ] = x2 -- top right
        textureCoords[vertexCount+6 ] = y1
        textureCoords[vertexCount+7 ] = x1 -- bottom left
        textureCoords[vertexCount+8 ] = y2
        textureCoords[vertexCount+9 ] = x2 -- top right
        textureCoords[vertexCount+10] = y1
        textureCoords[vertexCount+11] = x2 -- bottom right
        textureCoords[vertexCount+12] = y2

        vertexCount = vertexCount + 12
      end
    end
  end

  Graphics.glDraw{
    texture = texture,target = target,
    priority = priority,sceneCoords = sceneCoords,color = color,
    vertexCoords = vertexCoords,
    textureCoords = textureCoords,
  }
end

-- =======================================
-- ==========      Spin Box     ==========
-- =======================================
local function tick_spinbox(ui)
  if Colliders.collide(cursor.screenpos, ui.lButtonColl) then
    if (cursor.click or (cursor.left and cursor.leftDragBox.timer >= 20 and cursor.leftDragBox.timer % 10 == 0)) and ui.value > ui.min then
      ui.value = advance(ui.value - ui.int, ui.min, ui.max, ui.canWrap)
      SFX.play(14)
      if ui.func then ui.func('left') end
    end
    if cursor.left then
      ui.lButtonState = 2
    else
      ui.lButtonState = 1
    end
  else
    ui.lButtonState = 0
  end

  if ui.value == ui.min then
    ui.lButtonState = 3
  end

  if Colliders.collide(cursor.screenpos, ui.rButtonColl) then
    if (cursor.click or (cursor.left and cursor.leftDragBox.timer >= 20 and cursor.leftDragBox.timer % 10 == 0)) and ui.value < ui.max then
      ui.value = advance(ui.value + ui.int, ui.min, ui.max, ui.canWrap)
      SFX.play(14)
      if ui.func then ui.func('right') end
    end
    if cursor.left then
      ui.rButtonState = 2
    else
      ui.rButtonState = 1
    end
  else
    ui.rButtonState = 0
  end

  if ui.value == ui.max then
    ui.rButtonState = 3
  end

  if Colliders.collide(cursor.screenpos, ui.lineEditColl) then
    if cursor.click and ui.lineEditState == 0 then
      ui.lineEditState = 1
      ui.lineEditBuffer = tostring(ui.value)
      isActiveBuffer = true
      activeBuffer = ui.lineEditBuffer
    end
  else
    if cursor.click and ui.lineEditState == 1 then
      ui.lineEditState = 0
      isActiveBuffer = false
      ui.value = tonumber(ui.lineEditBuffer) or ui.default
      ui.value = math.clamp(ui.value, ui.min, ui.max)
      if ui.func then ui.func('line') end
    end
  end

  if ui.lineEditState == 1 then
    ui.lineEditBuffer = activeBuffer
    if player.keys.left then
      ui.lineEditCursor = ui.lineEditCursor - 1
    elseif player.keys.right then
      ui.lineEditCursor = ui.lineEditCursor + 1
    end
    ui.lineEditCursor = math.clamp(ui.lineEditCursor, 1, #ui.lineEditBuffer)
  end
end

local function draw_spinbox(ui)
  textplus.print{text = ui.name, x = ui.x, y = ui.y, font = uiFont, xscale = 2, yscale = 2}
  drawTextureBox(buttonGfx.left, ui.lButtonColl, 0, ui.lButtonState*buttonGfx.left.height/4, buttonGfx.left.width, buttonGfx.left.height/4)
  drawTextureBox(buttonGfx.right, ui.rButtonColl, 0, ui.rButtonState*buttonGfx.right.height/4, buttonGfx.right.width, buttonGfx.right.height/4)
  drawTextureBox(lineEditGFX, ui.lineEditColl, 0, 0, lineEditGFX.width, lineEditGFX.height)

  if ui.lineEditState == 0 then
    textplus.print{text = tostring(ui.value), x = ui.lineEditColl.x + 0.5*ui.lineEditColl.width, y = ui.lineEditColl.y + 0.5*ui.lineEditColl.height, font = uiFont, xscale = 2, yscale = 2, pivot = {0.5, 0.5}}
  else
    textplus.print{text = ui.lineEditBuffer, x = ui.lineEditColl.x + 0.5*ui.lineEditColl.width, y = ui.lineEditColl.y + 0.5*ui.lineEditColl.height, font = uiFont, xscale = 2, yscale = 2, pivot = {0.5, 0.5}}
  end
end


-- =======================================
-- ==========      List Box     ==========
-- =======================================
local function tick_listbox(ui)
  if Colliders.collide(cursor.screenpos, ui.lButtonColl) then
    if (cursor.click or (cursor.left and cursor.leftDragBox.timer >= 20 and cursor.leftDragBox.timer % 10 == 0)) and (ui.index > 1 or ui.canWrap)then
      ui.index = advance(ui.index - 1, 1, #ui.list, ui.canWrap)
      SFX.play(14)
      if ui.func then ui.func() end
    end
    if cursor.left then
      ui.lButtonState = 2
    else
      ui.lButtonState = 1
    end
  else
    ui.lButtonState = 0
  end

  if ui.index == 1 and not ui.canWrap then
    ui.lButtonState = 3
  end

  if Colliders.collide(cursor.screenpos, ui.rButtonColl) then
    if (cursor.click or (cursor.left and cursor.leftDragBox.timer >= 20 and cursor.leftDragBox.timer % 10 == 0)) and (ui.index < #ui.list or ui.canWrap) then
      ui.index = advance(ui.index + 1, 1, #ui.list, ui.canWrap)
      SFX.play(14)
      if ui.func then ui.func() end
    end
    if cursor.left then
      ui.rButtonState = 2
    else
      ui.rButtonState = 1
    end
  else
    ui.rButtonState = 0
  end

  if ui.index == #ui.list and not ui.canWrap then
    ui.rButtonState = 3
  end


  ui.value = ui.list[ui.index]
end

local function draw_listbox(ui)
  textplus.print{text = ui.name, x = ui.x, y = ui.y, font = uiFont, xscale = 2, yscale = 2}
  drawTextureBox(buttonGfx.left, ui.lButtonColl, 0, ui.lButtonState*buttonGfx.left.height/4, buttonGfx.left.width, buttonGfx.left.height/4)
  drawTextureBox(buttonGfx.right, ui.rButtonColl, 0, ui.rButtonState*buttonGfx.right.height/4, buttonGfx.right.width, buttonGfx.right.height/4)
  drawSegmentedBox{texture = lineEditGFX, x = ui.lineEditColl.x, y = ui.lineEditColl.y, width = ui.lineEditColl.width, height = ui.lineEditColl.height, priority = 0}

  if ui.name == "Color: " then
    textplus.print{text = '<color '..string.lower(ui.value)..">"..ui.value.."</color>", x = ui.lineEditColl.x + 0.5*ui.lineEditColl.width, y = ui.lineEditColl.y + 0.5*ui.lineEditColl.height, font = uiFont, xscale = 2, yscale = 2, pivot = {0.5, 0.5}}
  else
    textplus.print{text = ui.value, x = ui.lineEditColl.x + 0.5*ui.lineEditColl.width, y = ui.lineEditColl.y + 0.5*ui.lineEditColl.height, font = uiFont, xscale = 2, yscale = 2, pivot = {0.5, 0.5}}
  end
end



--[[
  @ x = X position on screen
  @ y = Y position on screen
  @ min = Minimum value possible
  @ max = Maximum value possible
  @ int = Interval from pressing buttons
]]
lib.SpinBox = function(args)
  args.active = true
  args.value = args.default or 1

  args.buttonSize = args.buttonSize or vector(32, 32)
  args.lineEditSize = args.lineEditSize or vector(96, 32)

  args.lButtonState = 0
  args.rButtonState = 0
  args.lineEditState = 0

  args.lineEditBuffer = ""
  args.lineEditCursor = 0

  -- these should be combined into a "style" parameter
  args.lButtonColl = Colliders.Box(args.x, args.y + 24, args.buttonSize.x, args.buttonSize.y)
  args.lineEditColl = Colliders.Box(args.x + args.buttonSize.x, args.y + 24, args.lineEditSize.x, args.lineEditSize.y)
  args.rButtonColl = Colliders.Box(args.x + args.buttonSize.x + args.lineEditSize.x, args.y + 24, args.buttonSize.x, args.buttonSize.y)

  args.tick = tick_spinbox
  args.draw = draw_spinbox

  table.insert(activeWidgets, args)

  return args
end

--[[
  @ x = X position on screen
  @ y = Y position on screen
  @ list = Table of strings
]]
lib.ListBox = function(args)
  args.active = true

  args.index = args.index or 1
  args.value = args.list[args.index]

  args.buttonSize = args.buttonSize or vector(32, 32)
  args.lineEditSize = args.lineEditSize or vector(96, 32)

  args.lButtonState = 0
  args.rButtonState = 0
  args.lineEditState = 0

  args.lineEditBuffer = ""
  args.lineEditCursor = 0

  -- these should be combined into a "style" parameter
  args.lButtonColl = Colliders.Box(args.x, args.y + 24, args.buttonSize.x, args.buttonSize.y)
  args.lineEditColl = Colliders.Box(args.x + args.buttonSize.x, args.y + 24, args.lineEditSize.x, args.lineEditSize.y)
  args.rButtonColl = Colliders.Box(args.x + args.buttonSize.x + args.lineEditSize.x, args.y + 24, args.buttonSize.x, args.buttonSize.y)

  args.tick = tick_listbox
  args.draw = draw_listbox

  table.insert(activeWidgets, args)

  return args
end


function lib.onTick()
  for k, v in ipairs(activeWidgets) do
    if v.active then
      v:tick()
    end
  end
end

function lib.onDraw()
  for k, v in ipairs(activeWidgets) do
    if v.active then
      v:draw()
    end
  end
end


function lib.onKeyboardPressDirect(id, b)
  if isActiveBuffer then
    if id == 110 or id == 190 then
      activeBuffer = activeBuffer.."."
    end
    -- Number keys
    if (id <= 57 and id >= 48 ) then
      activeBuffer = activeBuffer..(id - 48)
    elseif (id >= 96 and id <= 105 ) then
      activeBuffer = activeBuffer..(id - 96)
    end

    -- Backspace
    if id == 8 then
      local s = activeBuffer
      s = s:sub(1, -2)
      activeBuffer = s
    end
  end
end

function lib.onInitAPI()
  registerEvent(lib, "onTick", "onTick")
  registerEvent(lib, "onDraw", "onDraw")
  registerEvent(lib, "onKeyboardPressDirect", "onKeyboardPressDirect")
end

return lib
