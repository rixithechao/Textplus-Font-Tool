local textplus = require("textplus")
local miniui = require("miniui")
local cursor = require("cursor")

local configFileReader = require("configFileReader")


local uiFont = textplus.loadFont("textplus/font/4.ini")


cursor.create()

function wrapInt(x, min, max)
	return ((x - max + min - 1) % (min - max - 1)) + max

	-- local range = maxVal - minVal + 1
	-- local wrapped = current
	--
	-- -- Todo: optimize this thing with the proper application of simple math
	-- while  wrapped < minVal  do
	-- 	wrapped = wrapped + range
	-- end
	--
	-- while  wrapped > maxVal  do
	-- 	wrapped = wrapped - range
	-- end
	--
	-- return wrapped
end

local fontUI = miniui.ListBox{x = 16, y = 14, canWrap = true, name = 'Font: ', list = {'a', 'b', 'c'}, lineEditSize = vector(256, 32)}
local modeUI = miniui.ListBox{x = 16, y = 120, name = 'Mode: ', list = {'Preview', 'Edit', 'About'}, lineEditSize = vector(152, 32)}
--local displayTypeUI = miniui.ListBox{x = 480, y = 14, name = 'Display: ', list = {'Test String', 'Image'}, lineEditSize = vector(152, 32)}


-- Edit mode
local colsUI = miniui.SpinBox{min = 1, max = 100, int = 1, x = 16, y = 206, name = "Columns: ", default = 16, lineEditSize = vector(40, 32)}
local rowsUI = miniui.SpinBox{min = 1, max = 100, int = 1, x = 128, y = 206, name = "Rows: ", default = 8, lineEditSize = vector(40, 32)}
local ascentUI = miniui.SpinBox{min = 0, max = 1000, int = 1, x = 16, y = 266, name = "Ascent: ", default = 0, lineEditSize = vector(40, 32)}
local descentUI = miniui.SpinBox{min = 0, max = 1000, int = 1, x = 128, y = 266, name = "Descent: ", default = 0, lineEditSize = vector(40, 32)}
local spacingUI = miniui.SpinBox{min = 0, max = 1000, int = 1, x = 64, y = 326, name = "Spacing: ", default = 0, lineEditSize = vector(40, 32)}

local characterUI = miniui.ListBox{x = 16, y = 406, name = 'Character: ', list = {"A", "B"}, lineEditSize = vector(152, 32)}
local widthUI = miniui.SpinBox{min = 0, max = 1000, int = 1, x = 16, y = 466, name = "Width: ", default = 1, lineEditSize = vector(40, 32)}
local heightUI = miniui.SpinBox{min = 1, max = 1000, int = 1, x = 128, y = 466, name = "Height: ", default = 1, lineEditSize = vector(40, 32)}
local baselineUI = miniui.SpinBox{min = 1, max = 1000, int = 1, x = 64, y = 526, name = "Baseline: ", default = 1, lineEditSize = vector(40, 32)}


-- Preview mode
local scaleUI = miniui.SpinBox{min = 0.5, max = 10, int = 0.5, x = 16, y = 246, name = "Scale: ", default = 2, lineEditSize = vector(152, 32)}
local scaleXUI = miniui.SpinBox{min = 0.5, max = 5, int = 0.5, x = 16, y = 316, name = "Scale X: ", default = 1, lineEditSize = vector(40, 32)}
local scaleYUI = miniui.SpinBox{min = 0.5, max = 5, int = 0.5, x = 128, y = 316, name = "Scale Y: ", default = 1, lineEditSize = vector(40, 32)}
local waveUI = miniui.SpinBox{min = -10, max = 10, int = 0.5, x = 16, y = 386, name = "Wave: ", default = 0, lineEditSize = vector(40, 32)}
local glitchUI = miniui.SpinBox{min = 0, max = 1, int = 0.1, x = 128, y = 386, name = "Glitch: ", default = 0, lineEditSize = vector(40, 32)}
local colorUI = miniui.ListBox{x = 16, y = 456, name = 'Color: ', list = {'White', 'Black', 'Gray', 'Red', 'Orange', 'Yellow', 'Green', 'Blue', 'Purple', 'Rainbow'}, lineEditSize = vector(152, 32)}

local fontIndex = 1
local fontList = {}
local fontMap = {}
local fontPaths = {}
local fontInis = {}
local localCount = 1
local defaultTestString = [[The quick brown fox<br>jumps over the lazy dog<br>ABCDEFGHIJKLMNOPQRSTUVWXYZ<br>abcdefghijklmnopqrstuvwxyz<br>1234567890.,!?:;'"&%()[]{}<br>*+=-_]]





local display

local testStringField = {
    active = false,
    --visible = true,
    buffer = CaptureBuffer(2048,32),
    scroll = 0,
    blinkSpeed = 1.5,
    layout = nil,

    getMaxScroll = function(self)
        local stringFieldSize = vector(display.bounds.w-64, 28)

        return math.max(0, self.layout.width - stringFieldSize.x+32)
    end,
    scrollToStart = function(self)
        self.scroll = 0
    end,
    scrollToEnd = function(self)
        self.scroll = self:getMaxScroll()
    end
}

display = {

    -- Control vars
    index = 1,

    bounds = {
        top = 150,
        bottom = 582,
        left = 250,
        right = 782
    },

    scale = 2,
    xscale = 1,
    yscale = 1,
    scrollPos = vector(0,0),
    scrollMax = vector(1000,1000),
    testString = defaultTestString,
    testStringPlaintext = "",
    testStringDirty = true,

    buffer = CaptureBuffer(2048,2048),
    layout = nil,


    -- methods
    getCurrentFont = function(self)
        local fontName = fontList[self.index]  or  ""
        local currentFont = fontMap[fontName]
        return currentFont, fontName
    end,

    OnChangeFont = function(self, newFont)
        self.font = newFont
        colsUI.value = newFont.cols
        rowsUI.value = newFont.rows
        ascentUI.value = newFont.ascent
        descentUI.value = newFont.descent

        local newGlyphNameList = {}
        for  k,v in ipairs(newFont.simplecodes)  do
            newGlyphNameList[k] = string.char(v)
        end
        characterUI.index = 1
        characterUI.list = newGlyphNameList
        self:OnChangeGlyph(1)

        --[[
        local debugStr = ""
        for  k,v in pairs(self.font)  do
            if  type(v) == "table"  then
                Misc.dialog(k,v)
            end
            debugStr = debugStr..tostring(k)..": "..tostring(v).."\n"
        end
        Misc.dialog(debugStr)
        --]]
    end,

    OnChangeGlyph = function(self, newGlyphIndex)
        self.glyphCode = self.font.codes[newGlyphIndex]
        self.glyphChar = string.char(self.glyphCode)
        self.glyph = self.font.glyphs[self.glyphCode]

        baselineUI.value = self.glyph.baseline
        widthUI.value = self.glyph.width
        heightUI.value = self.glyph.height

        --Misc.dialog(display.glyphCode, display.glyphChar, "", display.glyph, "", display.glyph.x1 .. ", " .. display.glyph.x2, display.glyph.y1 .. ", " .. display.glyph.y2, "", display.glyph.x1c .. ", " .. display.glyph.x2c, display.glyph.y1c .. ", " .. display.glyph.y2c, "")
    end,

    ChangeTestString = function(self, newText)
        self.testString = newText
        self.testStringDirty = true
        self.layoutDirty = true
    end
}
display.bounds.w = display.bounds.right-display.bounds.left
display.bounds.h = display.bounds.bottom-display.bounds.top


-- UI
local scales = {0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.5, 3, 4, 5}

local buttonGfx = {
    left = Graphics.loadImageResolved("button_left.png"),
    right = Graphics.loadImageResolved("button_right.png"),
    up = Graphics.loadImageResolved("button_up.png"),
    down = Graphics.loadImageResolved("button_down.png"),
    reset = Graphics.loadImageResolved("button_reset.png"),
    save = Graphics.loadImageResolved("button_save.png")
}
local buttons = {

    -- Display scroll buttons
    displayLeft = {
        x=display.bounds.left+16, y=display.bounds.bottom-16,
        img = buttonGfx.left,
        onHold = function(self)
            display.scrollPos.x = math.max(0, display.scrollPos.x-10)
        end
    },
    displayRight = {
        x=display.bounds.right-16, y=display.bounds.bottom-16,
        img = buttonGfx.right,
        onHold = function(self)
            display.scrollPos.x = math.min(display.scrollMax.x, display.scrollPos.x+10)
        end
    },
    displayUp = {
        x=display.bounds.right-16, y=display.bounds.top+16,
        img = buttonGfx.up,
        onHold = function(self)
            display.scrollPos.y = math.max(0, display.scrollPos.y-10)
        end
    },
    displayDown = {
        x=display.bounds.right-16, y=display.bounds.bottom-16,
        img = buttonGfx.down,
        onHold = function(self)
            display.scrollPos.y = math.min(display.scrollMax.y, display.scrollPos.y+10)
        end
    },


    -- Reload font
    ---[[
    reloadFont = {
        x=fontUI.x + fontUI.lineEditSize.x + 64 + 24, y=fontUI.y + 40,
        img = buttonGfx.reset,
        onPress = function(self)
            local _,fontName = display:getCurrentFont()
            fontMap[fontName] = textplus.loadFont(fontPaths[fontName])
            display.layoutDirty = true
            SFX.play(14)
        end
    },
    --]]

    outputFont = {
        x=fontUI.x + fontUI.lineEditSize.x + 128, y = fontUI.y + 40,
        img = buttonGfx.save,
        onPress = function(self)
            
            local currentFont,fontName = display:getCurrentFont()
            local fontPath = fontPaths[fontName]

            ---[[
            -- Import font ini
            local iniDat = fontInis[fontName]

            local fullPath = Misc.levelPath():gsub([[[\/]+]], [[/]]) .. "output/" .. fontName .. ".ini"
            local iniFile = io.open (fullPath, "w")

            -- Main group
            iniFile:write("# Sheet Information\n[main]\n"

                .."image='"..fontPath:sub(1,-4).."png'\n"
                .."rows="..currentFont.rows.."\n"
                .."cols="..currentFont.cols.."\n")

            for  _,v in ipairs{"ascent", "descent", "spacing"}  do
                if  currentFont[v] ~= nil  then
                    iniFile:write(v.."="..currentFont[v].."\n")
                end
            end

            -- Glyph defaults group
            if  iniDat.glyphdefaults ~= nil  then
                local defs = iniDat.glyphdefaults

                iniFile:write("\n# Default Glyph Properties\n[glyphdefaults]\n")

                for  _,v in ipairs{"width", "height", "baseline"}  do
                    if  defs[v] ~= nil  then
                        iniFile:write(v.."="..defs[v].."\n")
                    end
                end
            end
            iniDat.glyphdefaults = iniDat.glyphdefaults  or  {}
            iniDat.glyphdefaults.width = iniDat.glyphdefaults.width  or  currentFont.cellWidth
            iniDat.glyphdefaults.height = iniDat.glyphdefaults.height  or  currentFont.cellHeight


            -- Glyphmap group
            if  iniDat.glyphmap ~= nil  then
                local gmap = iniDat.glyphmap

                iniFile:write("\n# Glyph Map (optional concise way to indicate the row/column of characters for simple cases)\n[glyphmap]\n")

                local orderedRows = {}
                for k2,lin in pairs(gmap)  do
                    local rowNum = tonumber(string.sub(k2, 4, -1))
                    orderedRows[rowNum] = lin
                end
                for  k2,lin in ipairs(orderedRows)  do
                    iniFile:write("row"..tostring(k2).."='"..tostring(lin).."'\n")
                end

            end

            -- Character entries
            iniFile:write("\n")

            for  _,v in ipairs(currentFont.codes)  do
                local glyph = currentFont.glyphs[v]
                local defs = iniDat.glyphdefaults

                local uniqueProps = {}
                for  _,v2 in ipairs{"width", "height", "baseline"}  do
                    if  glyph[v2] ~= defs[v2]  then
                        uniqueProps[#uniqueProps+1] = v2
                    end
                end

                if  #uniqueProps > 0  then
                    iniFile:write("["..string.char(v).."]\n")
                    for  _,v2 in ipairs(uniqueProps)  do
                        iniFile:write(v2.."="..glyph[v2].."\n")
                    end
                end
            end

            iniFile:close()
            Misc.dialog(fontName.." saved to output folder!")
            --]]
        end
    },


    -- Reset test string
    resetTestString = {
        x=display.bounds.left+24, y=display.bounds.top-24,
        img = buttonGfx.reset,
        onPress = function(self)
            display:ChangeTestString(defaultTestString)
            SFX.play(14)
        end
    }
}
local buttonList = table.unmap(buttons)

local buttonScroll = {
    startTick = 0,
    button = ""
}


local labels = {
    --[[
    fontname = {
        x = 20,y=20,
        text = ""
    },
    scale = {
        x=20, y=96,
        text = ""
    },
    --]]

    about = {
        x=10, y=260,
        text = "<align center>The Font Tool Level v1.1.0<br>by Rixithechao & SetaYoshi<br><br>Pre-packaged fonts<br>(in this level) made by<br>Rixithechao & KBM-Quine<br>using rips by Jackster,<br>Squishy Rex, and<br>Murphmario<br><br>Other info here idk</align>"
    },

    testString = {
        x = 2,
        y = 4,
        text = "",
        visible = true,
        target = testStringField.buffer
    }
}
local labelList = table.unmap(labels)



fontviewer = {}



function onStart()
    Graphics.activateHud(false)

    display.scale = 2


    -- Process buttons
    for  _,k in ipairs(buttonList)  do
        local v = buttons[k]

        v.sprite = Sprite.box{
			x=v.x, y=v.y,
            texture=v.img,
            frames = 4,
			pivot=Sprite.align.CENTER
		}
        v.sprite.scale = vector.one2*2

        v.w = v.img.width
        v.h = v.img.height/4

        v.x1 = v.sprite.x - v.w
        v.x2 = v.sprite.x + v.w
        v.y1 = v.sprite.y - v.h
        v.y2 = v.sprite.y + v.h
    end


    -- Scroll buttons
    for  _,k in ipairs{--[["fontLeft","fontRight","scaleLeft","scaleRight"]]}  do
        local v = buttons[k]
        v.onScroll = function(self)
            self:onPress()
        end
    end


    -- Load fonts
    local fontMaps = {}
    local fontLists = {}
    local fontPathMaps = {}
    local fontIniMaps = {}

    for  k,v in ipairs{
        {files = Misc.listLocalFiles("fonts"),                 root="fonts/"},
        {files = Misc.listFiles(     "scripts/textplus/font"), root="textplus/font/"}
    }  do

        fontMaps[k] = {}
        fontPathMaps[k] = {}
        fontIniMaps[k] = {}

        for  _,v2 in ipairs(v.files)  do
            local str = string.gsub(v2, "([^%.]+)(%.)(%w+)", function(name,dot,extension)
                if  extension == "ini"  then
                    --Misc.dialog(name, dot, extension)
                    fontPathMaps[k][name] = v.root..v2
                    fontMaps[k][name] = textplus.loadFont(v.root..v2)

                    local iniDat = {}
                    local charEntries = {}
                    local charList = {}

                    local layers = configFileReader.parseWithHeaders(Misc.resolveFile(v.root..v2), {})
                    for  k3,v3 in ipairs(layers)  do
                        --Misc.dialog(v3)

                        local header = v3.name
                        v3.name = nil
                        v3._header = nil

                        if  header == "main"  or  header == "glyphmap"  or  header == "glyphdefaults"  then
                            iniDat[header] = v3
                        else
                            charEntries[string.byte(header)] = v3
                        end
                    end
                    iniDat.charEntries = charEntries
                    fontIniMaps[k][name] = iniDat
                end
            end)
        end
        fontLists[k] = table.unmap(fontMaps[k])
        table.sort(fontLists[k])
    end
    fontMap = table.join(fontMaps[1], fontMaps[2])
    fontPaths = table.join(fontPathMaps[1], fontPathMaps[2])
    fontInis = table.join(fontIniMaps[1], fontIniMaps[2])
    fontList = table.append(fontLists[1], fontLists[2])
    localCount = #fontLists[1]

    --Misc.dialog(fontList)
end



function onTick()
    player.forcedState = 8
end


function onKeyboardPressDirect(keyCode, isARepetitionDueToHolding, char)
    if  testStringField.active  then
        local currentStr = display.testString
 
        -- Backspace
        if keyCode == 8 then
            local s = currentStr
            
            -- Delete line breaks
            if  s:sub(-4, -1) == "<br>"  then
                s = s:sub(1, -5)
            else
                s = s:sub(1, -2)
            end
            currentStr = s
            testStringField:scrollToEnd()

        -- Enter
        elseif  keyCode == VK_RETURN  then
            currentStr = currentStr.."<br>"
            testStringField:scrollToEnd()

        -- Add anything typed to the end
        elseif  char ~= nil  and  keyCode ~= VK_LEFT  and  keyCode ~= VK_RIGHT  and  keyCode ~= VK_UP  and  keyCode ~= VK_DOWN  then
            currentStr = currentStr..char
            testStringField:scrollToEnd()
        end

        -- Update the test string
        display:ChangeTestString(currentStr)
        fontviewer.text = currentStr
    end
end

function onPasteText(pastedText)
    if  testStringField.active  then

        display:ChangeTestString(display.testString .. pastedText)
        fontviewer.text = display.testString
    end
end


function onDraw()

    -- exposed table integration
    if  fontviewer.text ~= nil  and  fontviewer.text ~= display.testString  then
        display.testStringDirty = true
    end
    display.testString = fontviewer.text  or  display.testString


    -- Modes
    for  k,v in ipairs{scaleUI, scaleXUI, scaleYUI, waveUI, glitchUI, colorUI}  do
        v.active = modeUI.value == "Preview"
    end
    for  k,v in ipairs{rowsUI, colsUI, ascentUI, descentUI, spacingUI, characterUI, widthUI, heightUI, baselineUI}  do
        v.active = modeUI.value == "Edit"
    end


    -- Display layout dirty check
    for  k,v in ipairs{
        {"index", fontUI},
        {"scale", scaleUI},
        {"xscale", scaleXUI},
        {"yscale", scaleYUI},
        {"glitch", glitchUI},
        {"color", colorUI},
    }  do
        if  display[v[1]] ~= v[2][v[3] or "value"]  then
            display.layoutDirty = true
            break;
        end
    end


    -- Display write
    fontUI.list = fontList

    for k,v in ipairs{
        {"index", fontUI, "index"},
        {"scale", scaleUI},
        {"xscale", scaleXUI},
        {"yscale", scaleYUI},
        {"glitch", glitchUI},
        {"color", colorUI}
    }  do
        if  v[4] ~= true  then
            display[v[1]] = v[2][v[3] or "value"]
        end
    end



    -- Get the current font
    local currentFont, fontName = display:getCurrentFont()
    if  currentFont ~= display.font  then
        display:OnChangeFont(currentFont)
    end


    -- Font write and layout dirty check
    for  k2,v2 in ipairs{
        {"rows", rowsUI},
        {"cols", colsUI},
        {"ascent", ascentUI},
        {"descent", descentUI},
        {"spacing", spacingUI},
    }  do
        if  display.font[v2[1]] ~= v2[2][v2[3] or "value"]  then
            display.layoutDirty = true
            display.fontDirty = true
        end
        if  v2[4] ~= true  then
            display.font[v2[1]] = v2[2][v2[3] or "value"]
        end
    end


    -- Update glyph, or write and layout dirty check
    if  display.glyphChar == nil  or  display.glyphChar ~= characterUI.value  then
        display:OnChangeGlyph(characterUI.index)
    end
    local glyph = display.glyph

    if  glyph.spacing ~= spacingUI.value  then
        glyph.spacing = spacingUI.value
        display.glyphDirty = true
        display.fontDirty = true
        display.layoutDirty = true
    end
    if  glyph.baseline ~= baselineUI.value  then
        glyph.baseline = baselineUI.value
        display.glyphDirty = true
        display.fontDirty = true
        display.layoutDirty = true
    end
    if  glyph.width ~= widthUI.value  then
        glyph.width = widthUI.value

        local f = display.font
        local iW = f.imageWidth

        glyph.x2 = glyph.x1 + (glyph.width/iW)
        glyph.x1c = glyph.x1*iW + 0.5
        glyph.x2c = glyph.x2*iW - 0.5

        display.glyphDirty = true
        display.fontDirty = true
        display.layoutDirty = true
    end
    if  glyph.height ~= heightUI.value  then
        glyph.height = heightUI.value

        local f = display.font
        local iH = f.imageHeight

        glyph.y2 = glyph.y1 + (glyph.height/iH)
        glyph.y1c = glyph.y1*iH + 0.5
        glyph.y2c = glyph.y2*iH - 0.5

        display.glyphDirty = true
        display.fontDirty = true
        display.layoutDirty = true
    end



    -- Update the test string plaintext
    if  display.testStringDirty  then
        display.testStringDirty = false
        display.testStringPlaintext = string.gsub(display.testString, "[<>]", function(a)
            if  a=="<"  then
                return "<lt>"
            else
                return "<gt>"
            end
        end)

        local parsed = textplus.parse(display.testStringPlaintext, {font=uiFont, xscale=2, yscale=2})
        testStringField.layout = textplus.layout(parsed)

        display.layoutDirty = true
    end

    -- Text entry field interactivity
    testStringField.buffer:clear(100)
    local stringFieldPos = vector(display.bounds.left+48, display.bounds.top-38)
    local stringFieldSize = vector(display.bounds.w-64, 28)

    local stringFieldAdd = ""

    local testStringFieldWasActive = testStringField.active
    if   cursor.left == KEYS_PRESSED  then
        testStringField.active = (cursor.x > stringFieldPos.x
                             and  cursor.x < stringFieldPos.x + stringFieldSize.x
                             and  cursor.y > stringFieldPos.y
                             and  cursor.y < stringFieldPos.y + stringFieldSize.y)
        
        if  not testStringFieldWasActive  and  testStringField.active  then
            testStringField:scrollToEnd()
        end
    end

    if  testStringField.active  then

        if  math.ceil(testStringField.blinkSpeed * lunatime.time())%2 == 0  then
            stringFieldAdd = "|"
        end

        -- Scroll horizontally
        if  player.rawKeys.left == KEYS_DOWN  then
            testStringField.scroll = math.max(0, testStringField.scroll - 10)
        end
        if  player.rawKeys.right == KEYS_DOWN  then
            testStringField.scroll = math.min(testStringField:getMaxScroll(), testStringField.scroll + 10)
        end

        -- Jump to start/end
        if  player.rawKeys.down == KEYS_DOWN  then
            testStringField:scrollToEnd()
        end
        if  player.rawKeys.up == KEYS_DOWN  then
            testStringField:scrollToStart()
        end
    end


    -- Labels
    local basegameFontAdd = ""
    if  display.index > localCount  then
        basegameFontAdd = "(BASEGAME) "
    end

    labels.about.visible = modeUI.value == "About"
    labels.testString.text = display.testStringPlaintext..stringFieldAdd

    for  _,k in ipairs(labelList)  do
        local v = labels[k]

        if  v.visible  then
            textplus.print {
                font = uiFont,
                xscale = 2,
                yscale = 2,
                x = v.x,
                y = v.y,
                text = v.text,
                limit = v.limit,
                target = v.target
            }
        end
    end

    -- Text entry field rendering
    Graphics.drawBox{
        x=stringFieldPos.x-2, y=stringFieldPos.y-2,
        w=stringFieldSize.x+4, h=stringFieldSize.y+4,
        color = Color.black
    }
    Graphics.drawBox{
        x=stringFieldPos.x, y=stringFieldPos.y,
        w=stringFieldSize.x, h=stringFieldSize.y,
        color = Color.darkgray
    }
    Graphics.drawBox{
        x=stringFieldPos.x+2, y=stringFieldPos.y,
        w=stringFieldSize.x-4, h=stringFieldSize.y,
        sourceWidth = stringFieldSize.x-4,
        sourceHeight = stringFieldSize.y,
        sourceX = testStringField.scroll,
        sourceY = 0,
        texture = testStringField.buffer
    }


    -- Buttons
    if  cursor.left == KEYS_UP  then
        buttonScroll.startTick = lunatime.tick()
    end

    local frame
    local scrollTick
    for  _,k in ipairs(buttonList)  do
        v = buttons[k]

        v.sprite.x =      v.x  or  v.sprite.x
        v.sprite.y =      v.y  or  v.sprite.y
        v.sprite.width =  v.w  or  v.sprite.width
        v.sprite.height = v.h  or  v.sprite.height

        v.x1 = v.sprite.x - v.w
        v.x2 = v.sprite.x + v.w
        v.y1 = v.sprite.y - v.h
        v.y2 = v.sprite.y + v.h

        -- Render if not flagged as invisible
        if  v.visible ~= false  then
            frame = 1


            -- Disable
            if  v.enabled == false  then
                frame = 4

            -- If inside the button bounds
            elseif  cursor.x > v.x1  and  cursor.x < v.x2  and  cursor.y > v.y1  and  cursor.y < v.y2  then
                frame = 2
                if  cursor.left == KEYS_DOWN  then
                    frame = 3
                    if  v.onHold  then
                        v:onHold()
                    end
                end
                if  cursor.left == KEYS_PRESSED  and  v.onPress  then
                    v:onPress()
                end

                -- Update the scrolling
                if  buttonScroll.button ~= k  then
                    buttonScroll.button = k
                    buttonScroll.startTick = lunatime.tick()
                end
                scrollTick = lunatime.tick()-buttonScroll.startTick

                if  scrollTick%8 == 0  and  scrollTick > 20  and  v.onScroll  then
                    v:onScroll()
                end
            end

            v.sprite:draw{
                color = Color.white,
                frame = frame,
                sceneCoords = false,
                priority = 0
            }
        end
    end


    -- Refresh the current font in case it changed
    currentFont, fontName = display:getCurrentFont()


    -- Update layout, scroll limits, and buffer
    local displaySize = vector(display.bounds.w, display.bounds.h)

    if  display.layoutDirty  then
        display.layoutDirty = false
        local parsed = textplus.parse("<color "..string.lower(colorUI.value).."><wave "..waveUI.value.."><glitch "..glitchUI.value..">"..display.testString.."</glitch></wave></color>", {font=currentFont, xscale=display.scale*display.xscale, yscale=display.scale*display.yscale})
        display.layout = textplus.layout(parsed)

        display.scrollMax = vector(
            math.max(0, display.layout.width + 20 - display.bounds.w),
            math.max(0, display.layout.height + 20 - display.bounds.h)
        )
        display.scrollPos = vector(
            math.min(display.scrollMax.x, display.scrollPos.x),
            math.min(display.scrollMax.y, display.scrollPos.y)
        )

        if  display.scrollMax.x > 0  then
            displaySize.y = displaySize.y-32
        end
        if  display.scrollMax.y > 0  then
            displaySize.x = displaySize.x-32
        end

        display.buffer = CaptureBuffer(display.layout.width+20,display.layout.height+20)

        buttons.displayLeft.visible = display.scrollMax.x > 0
        buttons.displayRight.visible = display.scrollMax.x > 0
        buttons.displayUp.visible = display.scrollMax.y > 0
        buttons.displayDown.visible = display.scrollMax.y > 0
    end
    buttons.displayRight.x = display.bounds.left + displaySize.x - 16
    buttons.displayDown.y = display.bounds.top + displaySize.y - 16


    -- Scrollbars
    local scrollPercent = vector(math.invlerp(0,display.scrollMax.x, display.scrollPos.x), math.invlerp(0,display.scrollMax.y, display.scrollPos.y))

    -- horizontal
    if  display.scrollMax.x > 0  then

        -- Bar
        Graphics.drawBox{
            x=display.bounds.left, y=display.bounds.bottom-32,
            w=displaySize.x, h=32,
            color = Color.darkgray,
            priority=-3
        }
        Graphics.drawBox{
            x=display.bounds.left+2, y=display.bounds.bottom-30,
            w=displaySize.x-4, h=28,
            color = Color.gray,
            priority=-2
        }

        -- Box
        Graphics.drawBox{
            x=display.bounds.left+32 + math.lerp(0,displaySize.x-92, scrollPercent.x), y=display.bounds.bottom-30,
            w=28, h=28,
            color = Color.lightgray,
            priority=-1
        }
    end

    -- vertical
    if  display.scrollMax.y > 0  then

        -- Bar
        Graphics.drawBox{
            x=display.bounds.right-32, y=display.bounds.top,
            w=32, h=displaySize.y,
            color = Color.darkgray,
            priority=-3
        }
        Graphics.drawBox{
            x=display.bounds.right-30, y=display.bounds.top+2,
            w=28, h=displaySize.y-4,
            color = Color.gray,
            priority=-2
        }

        -- Box
        Graphics.drawBox{
            x=display.bounds.right-30, y=display.bounds.top+32 + math.lerp(0,displaySize.y-92, scrollPercent.y),
            w=28, h=28,
            color = Color.lightgray,
            priority=-1
        }
    end


    -- Scrollbar dragging
    if  cursor.click  then
        -- Horz drag
        if   cursor.x > display.bounds.left+32
        and  cursor.x < display.bounds.left + displaySize.x - 32
        and  cursor.y > display.bounds.bottom-32
        and  cursor.y < display.bounds.bottom
        and  display.scrollMax.x > 0
        then
					  display.horizantalGrab = true
        end
        -- Vert drag
        if   cursor.x > display.bounds.right-32
        and  cursor.x < display.bounds.right
        and  cursor.y > display.bounds.top+32
        and  cursor.y < display.bounds.top + displaySize.y - 32
        and  display.scrollMax.y > 0
        then
					display.verticalGrab = true
        end
		elseif cursor.left == KEYS_RELEASED then
			display.horizantalGrab = false
display.verticalGrab = false
    end
		if display.horizantalGrab then
			local percent = math.invlerp(display.bounds.left+48,display.bounds.left + displaySize.x-48, cursor.x)
			display.scrollPos.x = display.scrollMax.x*math.clamp(percent,0,1)
		end


		if display.verticalGrab then
			local percent = math.invlerp(display.bounds.top+48,display.bounds.top + displaySize.y-48, cursor.y)
			display.scrollPos.y = display.scrollMax.y*math.clamp(percent,0,1)
		end


    -- Display the preview text
    display.buffer:clear(100)
    if  currentFont ~= nil  then

        textplus.render{
            layout = display.layout,
            x = 10, y=10, sceneCoords = false,
            target = display.buffer
        }
    end

    Graphics.drawBox{
        x=display.bounds.left, y=display.bounds.top,
        w=displaySize.x,
        h=displaySize.y,
        color = Color.darkgray
    }
    Graphics.drawBox{
        x=display.bounds.left+2, y=display.bounds.top+2,
        w=displaySize.x-4,
        h=displaySize.y-4,
        sourceWidth = display.bounds.w-4,
        sourceHeight = display.bounds.h-4,
        sourceX = display.scrollPos.x,
        sourceY = display.scrollPos.y,
        texture = display.buffer
    }


    -- exposed table integration
    fontviewer.text = display.testString
end
