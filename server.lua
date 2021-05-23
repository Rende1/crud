local connection = nil
local blockTimer = nil

addEventHandler("onResourceStart", resourceRoot, function ()
    connection = dbConnect( "mysql", "dbname=test; host=localhost", "root", "")
    if not connection then
        outputDebugString("Error MySQL")
    else
        outputDebugString("Success MySQL")
    end
end)

isRequestBlocked = function ()
	if isTimer(blockTimer) then
		return true
	else
		blockTimer = setTimer(function()
			blockTimer = nil
		end, 5000, 1)
		return false
	end
end

addUser = function (page, name, surname, address)
	if isRequestBlocked() then 
		return outputChatBox("Слишком частые запросы!", client, 255, 0, 0, true)
	end
	dbExec(connection, "INSERT INTO users (name, surname, address) VALUES (?, ?, ?)", name, surname, address)

	getUsers(client, page)
end
addEvent("onUserCreated", true)
addEventHandler("onUserCreated", resourceRoot, addUser)

onUserUpdated = function (page, ID, name, surname, address)
	if isRequestBlocked() then 
		return outputChatBox("Слишком частые запросы!", client, 255, 0, 0, true)
	end
    dbExec(connection, "UPDATE users SET name = ?, surname = ?, address = ? WHERE ID = ?", name, surname, address, ID)

    getUsers(client, page)
end
addEvent("onUserUpdated", true)
addEventHandler("onUserUpdated", resourceRoot, onUserUpdated)

deleteUser = function (page, ID)
	if isRequestBlocked() then 
		return outputChatBox("Слишком частые запросы!", client, 255, 0, 0, true)
	end
    dbExec(connection, "DELETE FROM users WHERE ID = ?", tonumber(ID))

    getUsers(client, page)
end
addEvent("deleteUser", true)
addEventHandler("deleteUser", resourceRoot, deleteUser)

--================ REFRESH =================
addEvent("getUsers", true)
addEventHandler("getUsers", resourceRoot, function (page)
	getUsers(client, page)
end)


getUsers = function (player, page)
	page = page or 1
    dbQuery(getUsersCount, {player}, connection, "SELECT * FROM users LIMIT ??, 20", (page-1)*20)
end

getUsersCount = function (q, player)
	local users = dbPoll(q, 0)

	dbQuery(refreshUsers, {player, users}, connection, "SELECT COUNT(*) FROM users")
end

refreshUsers = function (q, player, users)
    local count = dbPoll(q, 0)
    count = count[1]["COUNT(*)"]
    triggerClientEvent(player, "refreshUsersDatabase", resourceRoot, users, count)
end    
--==========================================