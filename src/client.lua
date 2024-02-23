if not turtle then error"Turtlenetes client can only be installed on a turtle" end

local HOSTNAME = "test_host"
local PROTOCOL = "t8s_client"
local SERVER_PROTOCOL = "t8s_server"

settings.define("t8s_group",{description = "the group this turtle belongs to"})

local group = settings.get"t8s_group"

local modem = peripheral.find"modem" or error"no modem attached"
rednet.open(peripheral.getName(modem))
rednet.host(PROTOCOL,tostring(os.getComputerID()))

local server = rednet.lookup(SERVER_PROTOCOL,HOSTNAME) or error(("could not connect to %s://%s"):format(SERVER_PROTOCOL,HOSTNAME))

local main = loadfile("main.lua")

local receiverSwitch = {
  ping = "pong",
  getLocation = gps.locate,
  getInventory = function ()
    local inventory = {}
    for i = 1, 16 do
      inventory[i] = turtle.getItemDetail(i)
    end
    return inventory
  end,
  getType = function ()
    return term.isColor() and "advanced" or "basic"
  end,
  getGroup = function ()
    return group
  end,
  setGroup = function (t)
    group = t.group
    settings.set("t8s_group", group)
  end,
  setMainFile = function (t)
    local file = fs.open("main.lua", "w")
    file.write(t.contents)
    file.flush()
    file.close()
  end,
  reboot = os.reboot,
  evaluate = function (t)
    return pcall(function() load(t.chunk)() end)
  end
}

function recieverLoop()
  local result
  while true do
    local id, message = rednet.receive(SERVER_PROTOCOL)

    if id == server then

      print(textutils.serialise(message))
      local case = type(message) == "table" and receiverSwitch[message.functionName]
      if case then
        if type(case) == "function" then
          result = {case(message)}
        else
          result = case
        end
      end

      print(result)
      rednet.send(server, result, PROTOCOL)

    end
  end
end

function saveTimer()
  while true do
    sleep(5)
    settings.save()
  end
end

parallel.waitForAny(recieverLoop, saveTimer, main)