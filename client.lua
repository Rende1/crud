loadstring(exports.dgs:dgsImportFunction())()
local screenW, screenH = guiGetScreenSize()
local crud = {}

crud.ui = {}
crud.dataBase = {}
crud.countUsers = 0
crud.page = 1
crud.maxPages = 1

crud.createWindow = function ()
	crud.ui.main = dgsCreateWindow(screenW/2-700/2, screenH/2-400/2, 700, 400, "CRUD", false)
	dgsWindowSetCloseButtonEnabled(crud.ui.main, false)
	dgsWindowSetSizable(crud.ui.main, false)


	crud.ui.list = dgsCreateGridList(0, 0, 500, 400-25, false, crud.ui.main)
	dgsGridListAddColumn(crud.ui.list, "ID", 0.25)
	dgsGridListAddColumn(crud.ui.list, "Имя", 0.25)
	dgsGridListAddColumn(crud.ui.list, "Фамилия", 0.25)
	dgsGridListAddColumn(crud.ui.list, "Адрес", 0.25)

	crud.ui.editName = dgsCreateEdit(700-190, 10, 180, 25, "Имя", false, crud.ui.main)
	crud.ui.editSurname = dgsCreateEdit(700-190, 40, 180, 25, "Фамилия", false, crud.ui.main)
	crud.ui.editAddres = dgsCreateEdit(700-190, 70, 180, 25, "Адрес", false, crud.ui.main)

	crud.ui.add = dgsCreateButton(700-190, 110, 180, 25, "Добавить", false, crud.ui.main)
	crud.ui.update = dgsCreateButton(700-190, 140, 180, 25, "Изменить", false, crud.ui.main)
	crud.ui.delete = dgsCreateButton(700-190, 170, 180, 25, "Удалить", false, crud.ui.main)

	crud.ui.editSearch = dgsCreateEdit(700-190, 220, 180, 25, "...", false, crud.ui.main)
	crud.ui.buttonSearch = dgsCreateButton(700-190, 250, 180, 25, "Найти", false, crud.ui.main)

	crud.ui.refresh = dgsCreateButton(700-190, 300, 180, 25, "Обновить", false, crud.ui.main)


	crud.ui.prev = dgsCreateButton(700-175, 340, 35, 25, "<", false, crud.ui.main)
	crud.ui.next = dgsCreateButton(700-55, 340, 35, 25, ">", false, crud.ui.main)
	crud.ui.page = dgsCreateLabel(700-145, 340, 100, 25, "1/1", false, crud.ui.main)
	dgsLabelSetHorizontalAlign(crud.ui.page, "center")
	dgsLabelSetVerticalAlign(crud.ui.page, "center")
 
	showCursor(true)

	crud.refreshGrid()

	addEventHandler("onDgsMouseClick", root, crud.onClick)
	addEventHandler("onDgsEditAccepted", crud.ui.editSearch, crud.startSearch)

	guiSetInputMode("no_binds_when_editing")
end

crud.onClick = function (btn, state)
	if btn == "left" and state == "down" then
		if crud.ui.messageWindow and isElement(crud.ui.messageWindow) then dgsCloseWindow(crud.ui.messageWindow) end
		if source == crud.ui.delete then
			local selected = dgsGridListGetSelectedItem(crud.ui.list)
			if selected ~= -1 then
				local ID = dgsGridListGetItemText(crud.ui.list, selected, 1)
				crud.showAccepted("Вы уверены что хотите удалить строчку #"..ID.."?", function ()
					triggerServerEvent("deleteUser", resourceRoot, crud.page, ID)
				end)
			else
				crud.showMessage("Пожалуйста, выберите строчку!!")
			end
		elseif source == crud.ui.next then
			if crud.page == crud.maxPages then return end
			crud.page = math.min(crud.page+1, crud.maxPages)
			crud.startRefreshUsers()
		elseif source == crud.ui.prev then
			if crud.page == 1 then return end
			crud.page = math.max(crud.page-1, 1)
			crud.startRefreshUsers()
		elseif source == crud.ui.add then
			local name = dgsGetText(crud.ui.editName)
			local surname = dgsGetText(crud.ui.editSurname)
			local address = dgsGetText(crud.ui.editAddres)
			if name == "Имя" or utf8.len(name) < 4 then
				return crud.showMessage("Имя введено неверно!!")
			end
			if name == "Фамилия" or utf8.len(name) < 4 then
				return crud.showMessage("Фамилия введена неверно!!")
			end
			if name == "Адрес" or utf8.len(name) < 4 then
				return crud.showMessage("Адрес введен неверно!!")
			end
			triggerServerEvent("onUserCreated", resourceRoot, crud.page, name, surname, address)
		elseif source == crud.ui.update then
			local selected = dgsGridListGetSelectedItem(crud.ui.list)
			if selected ~= -1 then 
				local ID = dgsGridListGetItemText(crud.ui.list, selected, 1)
				local name = dgsGetText(crud.ui.editName)
				local surname = dgsGetText(crud.ui.editSurname)
				local address = dgsGetText(crud.ui.editAddres)
				if name == "Имя" or utf8.len(name) < 4 then
					return crud.showMessage("Имя введено неверно!!")
				end
				if name == "Фамилия" or utf8.len(name) < 4 then
					return crud.showMessage("Фамилия введена неверно!!")
				end
				if name == "Адрес" or utf8.len(name) < 4 then
					return crud.showMessage("Адрес введен неверно!!")
				end
				triggerServerEvent("onUserUpdated", resourceRoot, crud.page, ID, name, surname, address)
			else
				crud.showMessage("Пожалуйста, выберите строчку!!")
			end
		elseif source == crud.ui.refresh then
			crud.startRefreshUsers()
		elseif source == crud.ui.buttonSearch then
			crud.startSearch()
		elseif source == crud.ui.list then
			local selected = dgsGridListGetSelectedItem(crud.ui.list)
			if selected ~= -1 then 
				dgsSetText(crud.ui.editName, dgsGridListGetItemText(crud.ui.list, selected, 2))
				dgsSetText(crud.ui.editSurname, dgsGridListGetItemText(crud.ui.list, selected, 3))
				dgsSetText(crud.ui.editAddres, dgsGridListGetItemText(crud.ui.list, selected, 4))
			else
				dgsSetText(crud.ui.editName, "Имя")
				dgsSetText(crud.ui.editSurname, "Фамилия")
				dgsSetText(crud.ui.editAddres, "Адрес")
			end
		end
	end
end

crud.showMessage = function (text)
	crud.ui.messageWindow = dgsCreateWindow(screenW/2-300/2, screenH/2-150/2, 300, 150, "Уведомление", false)
	dgsWindowSetCloseButtonEnabled(crud.ui.messageWindow, false)
	dgsWindowSetSizable(crud.ui.messageWindow, false)
	dgsWindowSetMovable(crud.ui.messageWindow, false)

	crud.ui.messageLabel = dgsCreateLabel(0, 0, 300, 125, text, false, crud.ui.messageWindow)
	dgsLabelSetHorizontalAlign(crud.ui.messageLabel, "center")
	dgsLabelSetVerticalAlign(crud.ui.messageLabel, "center")
end

crud.showAccepted = function (text, funct1, funct2)
	crud.ui.acceptedWindow = dgsCreateWindow(screenW/2-300/2, screenH/2-150/2, 300, 150, "Внимание!", false)
	dgsWindowSetCloseButtonEnabled(crud.ui.acceptedWindow, false)
	dgsWindowSetSizable(crud.ui.acceptedWindow, false)
	dgsWindowSetMovable(crud.ui.acceptedWindow, false)

	crud.ui.acceptedLabel = dgsCreateLabel(0, 0, 300, 100, text, false, crud.ui.acceptedWindow)
	dgsLabelSetHorizontalAlign(crud.ui.acceptedLabel, "center")
	dgsLabelSetVerticalAlign(crud.ui.acceptedLabel, "center")

	crud.ui.acceptedYes = dgsCreateButton(25, 85, 100, 25, "Да", false, crud.ui.acceptedWindow)
	crud.ui.acceptedNo = dgsCreateButton(175, 85, 100, 25, "Нет", false, crud.ui.acceptedWindow)

	crud.onClickAccepted = function (btn, state)
		if btn == "left" and state=="down" then
			if source == crud.ui.acceptedYes then
				if funct1 then
					funct1()
				end
				dgsCloseWindow(crud.ui.acceptedWindow)
				removeEventHandler("onDgsMouseClick", root, crud.onClickAccepted)
			elseif source == crud.ui.acceptedNo then
				if funct2 then
					funct2()
				end
				dgsCloseWindow(crud.ui.acceptedWindow)
				removeEventHandler("onDgsMouseClick", root, crud.onClickAccepted)
			else
				dgsCloseWindow(crud.ui.acceptedWindow)
				removeEventHandler("onDgsMouseClick", root, crud.onClickAccepted)
			end
		end
	end
	addEventHandler("onDgsMouseClick", root, crud.onClickAccepted)
end

crud.startSearch = function ()
	local text = dgsGetText(crud.ui.editSearch)
	crud.refreshGrid(text)
end

crud.destroyWindow = function ()
	removeEventHandler("onDgsMouseClick", root, crud.onClick)
	removeEventHandler("onDgsEditAccepted", crud.ui.editSearch, crud.startSearch)

	for i,v in pairs(crud.ui) do
		if isElement(v) then
			destroyElement(v)
		end
	end
	crud.ui = {}

	showCursor(false)
end

crud.refreshGrid = function (filter)
	if crud.ui.main and isElement(crud.ui.main) then
		if not filter then filter = "" end
		dgsGridListClear(crud.ui.list)

		dgsSetText(crud.ui.page, crud.page.."/"..crud.maxPages)

		for i,v in pairs(crud.dataBase) do
			if string.find(string.lower(v.ID),  string.lower(filter)) or string.find(string.lower(v.name),  string.lower(filter)) or string.find(string.lower(v.surname),  string.lower(filter)) or string.find(string.lower(v.address),  string.lower(filter)) then
				local row = dgsGridListAddRow(crud.ui.list)
				dgsGridListSetItemText(crud.ui.list, row, 1, tostring(v.ID))
				dgsGridListSetItemText(crud.ui.list, row, 2, tostring(v.name))
				dgsGridListSetItemText(crud.ui.list, row, 3, tostring(v.surname))
				dgsGridListSetItemText(crud.ui.list, row, 4, tostring(v.address))
			end
		end
	end
end

crud.startRefreshUsers = function ()
	triggerServerEvent("getUsers", resourceRoot, crud.page)
end
addEvent("startRefreshUsers", true)
addEventHandler("startRefreshUsers", resourceRoot, crud.startRefreshUsers)

addEvent("refreshUsersDatabase", true)
addEventHandler("refreshUsersDatabase", resourceRoot, function (data, count)
	crud.dataBase = data
	crud.countUsers = count
	crud.maxPages = math.floor(crud.countUsers/20) + 1
	crud.refreshGrid()
end)


addEventHandler("onClientResourceStart", resourceRoot, function ()
	crud.startRefreshUsers()

	bindKey("L", "down", function ()
		if crud.ui.main and isElement(crud.ui.main) then
			crud.destroyWindow()
		else
			crud.createWindow()
		end
	end)
end)