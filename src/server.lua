local HOSTNAME = "test_host"
local PROTOCOL = "t8s_server"
local CLIENT_PROTOCOL = "t8s_client"

local modem = peripheral.find("modem") or error "no modem attached"
rednet.open(peripheral.getName(modem))
rednet.host(PROTOCOL, HOSTNAME)

-- TODO: filter out clients so we do not accidentally use another person's turtles
local function getClients()
  return { rednet.lookup(CLIENT_PROTOCOL) }
end

-- installs client.lua as startup.lua along with main.lua
local function installClientOnDrive()
  while true do
    for i, drive in ipairs { peripheral.find "drive" } do
      local mountPath = drive.getMountPath()
      if mountPath then
        local driveStartupPath = mountPath .. '/' .. "startup.lua"
        fs.delete(driveStartupPath)
        fs.copy("client/client.lua", driveStartupPath)

        local driveigpsPath = mountPath .. '/' .. "igps.lua"
        fs.delete(driveigpsPath)
        fs.copy("client/igps.lua", driveigpsPath)
      end
    end
  end
  sleep(0.2)
end

-- {functionName = "ping"}
local function callClientfunction(clientID, name, args)
  args = args or {}
  if name then args.functionName = name end
  rednet.send(clientID, args, PROTOCOL)
  return rednet.receive(CLIENT_PROTOCOL)
end

local function loop()
  local history = {}
  while true do
    local input = read(nil, history)
    history[#history + 1] = input
    for _, clientID in ipairs(getClients()) do
      local senderID, message = callClientfunction(clientID, nil, textutils.unserialise(input))
      print(textutils.serialise(message))
    end
    sleep(0.01)
  end
end

parallel.waitForAny(installClientOnDrive, loop)
