--[[
Hi-Hint — инструмент для луа-разработчиков, упрощяющий дебаг-логгирование
Был разработан специально для меня (github: thelifestorm), однако может быть использован и вами

ВАЖНАЯ АННОТАЦИЯ!!!
Если вы хотите использовать разные настройки для нескольких проектов одновременно, знайте, что
ввиду глобальности переменной HINT, её конфиг распространяется на все файлы и является единым.
Если вы хотите менять настройки, то добавьте в ваш скрипт/проект подгрузку конфига, указав
все переменные (кроме цветовых таблиц), даже если их использование необязательно!!!

Этот модуль изначально является плагином.
--]]

HINT = HINT or {}
HINT.Debug = true; -- для активации дополнения, нужно будет указать статус (true) в любом фрагменте кода

HINT.Workspace = ""; -- название проекта (ОБЯЗАТЕЛЬНО ДЛЯ ЛОГИРОВАНИЯ В ФАЙЛ)
HINT.LogFile = ""; -- дефолтное название файла для логирования. Если не указали отдельный файл при создании, заюзается он (ОБЯЗАТЕЛЬНО ДЛЯ ЛОГИРОВАНИЯ В ФАЙЛ)
HINT.LogEverything = false; -- логирование каждой строчки в файл
HINT.LogOnlyCriticalBugs = false; -- логировать критические

-- цветовая таблица
HINT.ColorInfo = Color(51, 153, 204); -- для подсказок (info)
HINT.ColorBug = Color(255, 0, 0); -- для багов (bug)
HINT.ColorCBug = Color(204, 0, 0); -- для критических багов (cbug)
HINT.ColorSelf = Color(153, 153, 153); -- для отрисовки сообщений дополнения

-- напоминание о том, что на сервере врублен дебаг-режим
if (SERVER) and (HINT.Debug) then
	MsgC(HINT.ColorBug, "[HINT]: Debug mode is actually enabled! Be careful.\n")
	MsgC(HINT.ColorBug, "[HINT]: Debug mode is actually enabled! Be careful.\n")
	MsgC(HINT.ColorBug, "[HINT]: Debug mode is actually enabled! Be careful.\n")
end

--[[
* name - название логгера (отображение в формате)
* hint_type - тип (bug/cbug/info)
* message - сообщение к логгеру
* workspace (НЕОБЯЗАТЕЛЬНО) - для раздельного логирования. Можно указать ИНОЕ от HINT.LogFile название файла. Таким
образом лог ошибки будет сохранён в файл, название которого будет указано в функции (или создаст его)

AddServer выводит подсказку в консоли сервера
AddClient выводит подсказку в консоли клиента
AddShared выводит везде /по возможности/
--]]
local currentpath = ""; -- необходимо для вывода пути файла

function HINT:AddServer(name, hint_type, message, workspace)
	if (SERVER) and (HINT.Debug) then
		current_path = debug.getinfo(1).source -- получаем директорию исполняемого файла
		hint_type = string.lower(hint_type)
		
		-- валидация подсказки
		if (!HINT:IsValid(name, hint_type, message)) then
			if (name == "") or (!name) then name = "Unknown Hint" end
			MsgC(HINT.ColorSelf, "[HINT]: Validation failed for «" .. name .. "» [" .. current_path .. "]. Ignoring.\n")
			return false;
		end
		
		-- отрисовка + логирование
		if (hint_type == "bug") then
			MsgC(HINT.ColorBug, "[BUG » " .. current_path .. "]: " .. message .. "\n")
			if (HINT.LogEverything) and (HINT.LogOnlyCriticalBugs != true) then
				HINT:LogToFile(name, workspace or HINT.LogFile, "[BUG » " .. current_path .. "]: " .. message .. "\n")
			end
		elseif (hint_type == "cbug") then
			MsgC(HINT.ColorCBug, "[CRIT-BUG » " .. current_path .. "]: " .. message .. "\n")
			if (HINT.LogEverything) or (HINT.LogOnlyCriticalBugs) then
				HINT:LogToFile(name, workspace or HINT.LogFile, "[CRIT-BUG » " .. current_path .. "]: " .. message .. "\n")
			end
		elseif (hint_type == "info") then
			MsgC(HINT.ColorInfo, "[NOTE » " .. current_path .. "]: " .. message .. "\n")
			if (HINT.LogEverything) and (HINT.LogOnlyCriticalBugs != true) then
				HINT:LogToFile(name, workspace or HINT.LogFile, "[NOTE » " .. current_path .. "]: " .. message .. "\n")
			end
		end
	end
end

function HINT:AddClient(name, hint_type, message, workspace)
	if (CLIENT) and (HINT.Debug) then
		current_path = debug.getinfo(1).source -- получаем директорию исполняемого файла
		hint_type = string.lower(hint_type)
		
		-- валидация подсказки
		if (!HINT:IsValid(name, hint_type, message)) then
			if (name == "") or (!name) then name = "Unknown Hint" end
			MsgC(HINT.ColorSelf, "[HINT]: Validation failed for «" .. name .. "» [" .. current_path .. "]. Ignoring.\n")
			return false;
		end
		
		-- отрисовка + логирование
		if (hint_type == "bug") then
			MsgC(HINT.ColorBug, "[BUG » " .. current_path .. "]: " .. message .. "\n")
			if (HINT.LogEverything) and (HINT.LogOnlyCriticalBugs != true) then
				HINT:LogToFile(name, workspace or HINT.LogFile, "[BUG » " .. current_path .. "]: " .. message .. "\n")
			end
		elseif (hint_type == "cbug") then
			MsgC(HINT.ColorCBug, "[CRIT-BUG » " .. current_path .. "]: " .. message .. "\n")
			if (HINT.LogEverything) or (HINT.LogOnlyCriticalBugs) then
				HINT:LogToFile(name, workspace or HINT.LogFile, "[CRIT-BUG » " .. current_path .. "]: " .. message .. "\n")
			end
		elseif (hint_type == "info") then
			MsgC(HINT.ColorInfo, "[NOTE » " .. current_path .. "]: " .. message .. "\n")
			if (HINT.LogEverything) and (HINT.LogOnlyCriticalBugs != true) then
				HINT:LogToFile(name, workspace or HINT.LogFile, "[NOTE » " .. current_path .. "]: " .. message .. "\n")
			end
		end
	end
end

function HINT:AddShared(name, hint_type, message, workspace)
	if (HINT.Debug) then
		current_path = debug.getinfo(1).source -- получаем директорию исполняемого файла
		hint_type = string.lower(hint_type)
		
		-- валидация подсказки
		if (!HINT:IsValid(name, hint_type, message)) then
			if (name == "") or (!name) then name = "Unknown Hint" end
			MsgC(HINT.ColorSelf, "[HINT]: Validation failed for «" .. name .. "» [" .. current_path .. "]. Ignoring.\n")
			return false;
		end
		
		-- отрисовка + логирование
		if (hint_type == "bug") then
			MsgC(HINT.ColorBug, "[BUG » " .. current_path .. "]: " .. message .. "\n")
			if (HINT.LogEverything) and (HINT.LogOnlyCriticalBugs != true) then
				HINT:LogToFile(name, workspace or HINT.LogFile, "[BUG » " .. current_path .. "]: " .. message .. "\n")
			end
		elseif (hint_type == "cbug") then
			MsgC(HINT.ColorCBug, "[CRIT-BUG » " .. current_path .. "]: " .. message .. "\n")
			if (HINT.LogEverything) or (HINT.LogOnlyCriticalBugs) then
				HINT:LogToFile(name, workspace or HINT.LogFile, "[CRIT-BUG » " .. current_path .. "]: " .. message .. "\n")
			end
		elseif (hint_type == "info") then
			MsgC(HINT.ColorInfo, "[NOTE » " .. current_path .. "]: " .. message .. "\n")
			if (HINT.LogEverything) and (HINT.LogOnlyCriticalBugs != true) then
				HINT:LogToFile(name, workspace or HINT.LogFile, "[NOTE » " .. current_path .. "]: " .. message .. "\n")
			end
		end
	end
end

------[[ ФУНКЦИИ ДЛЯ ПРОВЕРКИ НА ВАЛИДНОСТЬ ]]------
function HINT:IsValid(name, hint_type, message)
	if (!name) or (string.len(name) < 3) then return false end
	if (hint_type != "bug") and (hint_type != "cbug") and (hint_type != "info") then return false end
	if (!message) or (string.len(message) < 3) then return false end
	
	return true;
end

------[[ ФУНКЦИИ ДЛЯ СОХРАНЕНИЯ ЛОГОВ В ФАЙЛЫ ]]------
function HINT:LogToFile(name, filename, line)
	file.CreateDir("hint") -- создаёт если не существует
	
	if (string.len(tostring(HINT.Workspace)) > 3) then
		file.CreateDir("hint/" .. HINT.Workspace)
	else
		MsgC(HINT.ColorSelf, "[HINT]: You did not specify Workspace Name. Logging «" .. name .. "» [" .. current_path .. "] to file is not available. Ignoring.\n")
		return false;
	end
	
	if (string.len(tostring(HINT.LogFile)) < 3) then
		MsgC(HINT.ColorSelf, "[HINT]: You did not specify Default Log FileName. Logging «" .. name .. "» [" .. current_path .. "] to file is not available. Ignoring.\n")
		return false;
	end
	
	if (string.len(tostring(filename)) > 3) then
		file.Append( "hint/" .. HINT.Workspace .. "/" .. filename .. ".txt", line)
	else
		MsgC(HINT.ColorSelf, "[HINT]: Save log line to file validation failed for «" .. name .. "» [" .. current_path .. "]. Ignoring.\n")
		return false;
	end
end