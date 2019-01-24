--[[
	Unknown stuff by Magicks
	https://gist.github.com/Mehgugs/fea6b9a9c5cb1314ca415d2c31c8fa74
]]--
local proxymt = {}
function new_proxy(name)
   return setmetatable({name = name}, proxymt)
end

function proxymt:__index(key)
	local exists = world.sendEntityMessage(player.id(), "can_call", self.name, key):result()
	local existsTech = world.sendEntityMessage(player.id(), "can_callTech", self.name, key):result()
	local existsItem = world.sendEntityMessage(player.id(), "can_callItem", self.name, key):result()
	if exists then 
		self[key] = function(...) return world.sendEntityMessage(player.id(), "call_fn", self.name, key, ...):result() end 
		return self[key]
	elseif existsTech then
		self[key] = function(...) return world.sendEntityMessage(player.id(), "call_fnTech", self.name, key, ...):result() end 
		return self[key]		
	elseif existsItem then
		self[key] = function(...) return world.sendEntityMessage(player.id(), "call_fnItem", self.name, key, ...):result() end 
		return self[key]		
	end
end
local parent = _ENV
local lookup = {}

local LOAD_ENV = setmetatable({}, lookup)

function lookup:__index(key)
	if parent[key] then 
		self[key] = parent[key]
		return self[key]
    end
	local exists = world.sendEntityMessage(player.id(), "can_call", key):result()
	local existsTech = world.sendEntityMessage(player.id(), "can_callTech", key):result()
	local existsItem = world.sendEntityMessage(player.id(), "can_callItem", key):result()
	if exists or existsTech or existsItem then 
		self[key] = new_proxy(key)
		return self[key]
	end
end

--[[
	Normal code
]]--

function init()
	clear()
	widget.registerMemberCallback("codeScrollArea.lineList", "deleteLine", deleteLine)
	self.keywordColors = {
		-- lua keywords --
		['and'] = "^#8CFFFF;",
		['break'] = "^#8CFFFF;",
		['do'] = "^#8CFFFF;",
		['else'] = "^#8CFFFF;",
		['elseif'] = "^#8CFFFF;",
		['end'] = "^#8CFFFF;",
		['false'] = "^#8CFFFF;",
		['for'] = "^#8CFFFF;",
		['function'] = "^#8CFFFF;",
		['if'] = "^#8CFFFF;",
		['in'] = "^#8CFFFF;",
		['local'] = "^#8CFFFF;",
		['nil'] = "^#8CFFFF;",
		['not'] = "^#8CFFFF;",
		['or'] = "^#8CFFFF;",
		['repeat'] = "^#8CFFFF;",
		['return'] = "^#8CFFFF;",
		['then'] = "^#8CFFFF;",
		['true'] = "^#8CFFFF;",
		['until'] = "^#8CFFFF;",
		['while'] = "^#8CFFFF;",
		-- lua libraries --
		['string'] = "^#FF9BDC;",
		['math'] = "^#FF9BDC;",
		['table'] = "^#FF9BDC;",
		['error'] = "^#FF9BDC;",
		['require'] = "^#FF9BDC;",
		['self'] = "^#FF9BDC;",
		-- starbound tables --
		['world'] = "^#B6FF00;",
		['mcontroller'] = "^#B6FF00;",
		['widget'] = "^#B6FF00;",
		['root'] = "^#B6FF00;",
		['message'] = "^#B6FF00;",
		['status'] = "^#B6FF00;",
		['tech'] = "^#B6FF00;",
		['monster'] = "^#B6FF00;",
		['pane'] = "^#B6FF00;",
		['activeItem'] = "^#B6FF00;",
		['localanimator'] = "^#B6FF00;",
		['animator'] = "^#B6FF00;",
		['player'] = "^#B6FF00;",
		['sb'] = "^#B6FF00;"
	}
	widget.focus("codeTextBox")
end

function addLine()
	local li = ""
	local textToAdd = widget.getText("codeTextBox")
	if not self.selectedLine then
		li = widget.addListItem("codeScrollArea.lineList")
		table.insert(self.lines, {key = li, value = textToAdd})
	else
		li = self.selectedLine
		self.lines[index(li)] = {key = li, value = textToAdd}
	end
	widget.setText("codeScrollArea.lineList." .. li .. ".codeLine", colorText(textToAdd))
	widget.setData("codeScrollArea.lineList." .. li .. ".codeLine", textToAdd)
	widget.setText("codeTextBox", "")
	widget.focus("codeTextBox")
	
	-- Starbound: we'll repopulate the whole list because we can't just unselect one entry from it :saferoll: --
	repopulateTheSameListBecauseSBIsAmazing()
end

function repopulateTheSameListBecauseSBIsAmazing()
	widget.clearListItems("codeScrollArea.lineList")
	self.selectedLine = nil
	
	for k, _ in ipairs(self.lines) do
		local li = widget.addListItem("codeScrollArea.lineList")
		self.lines[k].key = li
		widget.setText("codeScrollArea.lineList." .. li .. ".codeLine", colorText(self.lines[k].value))
		widget.setData("codeScrollArea.lineList." .. li .. ".codeLine", self.lines[k].value)
	end
end

function index(key)
	for k, v in ipairs(self.lines) do
		if v.key == key then
			return k
		end
	end
	return #self.lines + 1
end

function lineSelected()
	local li = widget.getListSelected("codeScrollArea.lineList")
	if li then
		widget.setText("codeTextBox", widget.getData("codeScrollArea.lineList." .. li .. ".codeLine"))
		widget.focus("codeTextBox")
		self.selectedLine = li
	else
		self.selectedLine = nil
	end
end

function runScript()
	local success, result = proceedCode(self.lines)
	if not success then
		local errLine = result:match("%]%:(%d+)%:")
		if tonumber(errLine) then
			widget.setImage("codeScrollArea.lineList." .. self.lines[tonumber(errLine)].key .. ".background", "/interface/customConsole/errorline.png")
		end
	end
	widget.setFontColor("returnLabel", success and "white" or "red")
	widget.setText("returnLabel", sb.print(result))
end

function proceedCode(codeLines)
	local code = ""
	for _, line in ipairs(codeLines) do
		code = code .. line.value .. "\n"
	end
	code = code:sub(1, -2)
	
	if not load then
		return false, "Could not proceed script: check if safeScript is set to false"
	end
	
	local f, err = load(code, _, _, LOAD_ENV)

	if err then return false, err end
	
	return pcall(f)
end

function deleteLine()
	if self.selectedLine then
		local ind = index(self.selectedLine)
		table.remove(self.lines, ind)
		widget.removeListItem("codeScrollArea.lineList", ind - 1)
		widget.setText("codeTextBox", "")
		widget.focus("codeTextBox")
		self.selectedLine = nil
	end
end

function clear()
	widget.clearListItems("codeScrollArea.lineList")
	self.selectedLine = nil
	self.lines = {}
	widget.setText("codeTextBox", "")
	widget.setText("returnLabel", "")
end

function colorText(text)
	text = text:gsub("(%d+)", "^#FFA700;%1^reset;")
	text = text:gsub("\"(.+)\"", "^#AFAFAF;\"%1\"^reset;")
	text = text:gsub("(%a+)([^%.])", function(w1, g) if self.keywordColors[w1] then return self.keywordColors[w1] .. w1 .. "^reset;" .. g end end)
	text = text:gsub("(%a+)%.(%a+)", function(w1, w2) if self.keywordColors[w1] then return self.keywordColors[w1] .. w1 .. "." .. w2 .. "^reset;" end end)
	return text
end

function saveFile()
	local fileName = widget.getText("codeTextBox")
	-- Safe file --
	if not io then
		return false, "Could not proceed script: check if safeScript is set to false"
	end
	
	local file, error = io.open(fileName, "w")
	if not file then
		widget.setFontColor("returnLabel", "red")
		widget.setText("returnLabel", "Invalid file name")
		return
	end
	for _, code in ipairs(self.lines) do
		file:write(code.value, "\n")
	end
	file:close()
	
	-- Open filebase --
	local filebase = io.open("scriptsdb.db", "a+")
	if not filebase then
		widget.setFontColor("returnLabel", "red")
		widget.setText("returnLabel", "Could not create the filebase")
		return
	end
	
	-- Check whether the file is already in the filebase --
	for line in filebase:lines() do
		if line == fileName then
			return
		end
	end
	
	-- Add file to filebase --
	filebase:write(fileName, "\n")
	filebase:close()
	
	widget.setFontColor("returnLabel", "white")
	widget.setText("returnLabel", "File " .. fileName .. " saved successfully")
end

function loadFile()
	if not io then
		return false, "Could not proceed script: check if safeScript is set to false"
	end
	local file = io.open(widget.getText("codeTextBox"), "r")
	if not file then
		-- Open filebase for suggestions --
		widget.setFontColor("returnLabel", "red")
		
		local filebase = io.open("scriptsdb.db", "r")
		if not filebase then
			widget.setText("returnLabel", "Could not open the filebase")
			return
		end
		local availableText = "Known files:"
		for line in filebase:lines() do
			availableText = availableText .. "\n" .. line
		end
		widget.setText("returnLabel", availableText)
		filebase:close()
		return
	end
	
	clear()
	-- Read the file --
	for line in file:lines() do
		widget.setText("codeTextBox", line)
		addLine()
	end
	file:close()
end