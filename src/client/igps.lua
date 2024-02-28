--[[GLOBALS:
x, y, z : number
direction : string
minX, maxX, minY ,maxY, minZ, maxZ : number
]]

local assert = assert
local turtle = turtle
assert(turtle, "internal GPS only works for turtles")
local turtle_forward, turtle_back, turtle_turnLeft, turtle_turnRight, turtle_up, turtle_down, turtle_dig, turtle_digUp, turtle_digDown, turtle_place, turtle_placeUp, turtle_placeDown =
    turtle.forward,
    turtle.back, turtle.turnLeft, turtle.turnRight,
    turtle.up, turtle.down, turtle.dig, turtle.digUp, turtle.digDown, turtle.place, turtle.placeUp, turtle.placeDown

local peripheral_find = peripheral.find
local gps_locate = gps.locate

local NORTH, EAST, SOUTH, WEST = "North", "East", "South", "West"
local GPS_ERROR, MODEM_ERROR, POSITION_ERROR, DIRECTION_ERROR, OOB_MOVE_ERROR, OOB_DIG_ERROR, OOB_PLACE_ERROR =
    "GPS not available",
    "position not calibrated", "modem not attached",
    "direction not calibrated", "attempt to move out of bounds", "attempt to dig out of bounds",
    "attempt to place out of bounds"

local function setPosition(nx, ny, nz)
  x, y, z = nx, ny, nz
end

local function getPosition()
  return x,y,z
end

local function setBoundary(nMinX, nMaxX, nMinY, nMaxY, nMinZ, nMaxZ)
  -- swap min and max if min is greater than max, and not nil on eihter side
  if nMinX and nMaxX and nMinX > nMaxX then nMinX, nMaxX = nMaxX, nMinX end
  if nMinY and nMaxY and nMinY > nMaxY then nMinY, nMaxY = nMaxY, nMinY end
  if nMinZ and nMaxZ and nMinZ > nMaxZ then nMinZ, nMaxZ = nMaxZ, nMinZ end
  minX, maxX, minY, maxY, minZ, maxZ = nMinX, nMaxX, nMinY, nMaxY, nMinZ, nMaxZ
end

-- calibrates the x, y, and z of the turtle using the GPS api
local function calibratePosition()
  if not peripheral_find "modem" then return false, MODEM_ERROR end
  local x, y, z = gps_locate()
  if not x then return false, GPS_ERROR end
  setPosition(x, y, z)
  return true
end

--- Calibrates the direction of the turtle
local function calibrateDirection()
  if not (x and y and z) then return false, POSITION_ERROR end
  local ok, message
  for _ = 1, 4 do
    ok, message = turtle_forward()
    if not ok then turtle_turnRight() else break end
  end
  if not ok then return false, message end
  local nx, _, nz = gps_locate()
  if not nx then return false, GPS_ERROR end
  local dx, dz = x - nx, z - nz

  if dx == -1 then
    direction = EAST
  elseif dx == 1 then
    direction = WEST
  elseif dz == -1 then
    direction = SOUTH
  else -- dz == 1
    direction = NORTH
  end

  return turtle_back()
end

function init()
  assert(calibratePosition())
  assert(calibrateDirection())
end

local function turnLeft()
  if direction and turtle_turnLeft() then
    if direction == NORTH then
      direction = WEST
    elseif direction == EAST then
      direction = NORTH
    elseif direction == SOUTH then
      direction = EAST
    else
      direction = SOUTH
    end
  else
    return false, DIRECTION_ERROR
  end
  return true
end

local function turnRight()
  if direction and turtle_turnRight() then
    if direction == NORTH then
      direction = EAST
    elseif direction == EAST then
      direction = SOUTH
    elseif direction == SOUTH then
      direction = WEST
    else
      direction = NORTH
    end
  else
    return false, DIRECTION_ERROR
  end
  return true
end

local function turnNorth()
  if not direction then return false, DIRECTION_ERROR end
  if direction == WEST then
    turtle_turnRight()
  elseif direction == EAST then
    turtle_turnLeft()
  elseif direction == SOUTH then
    turtle_turnLeft()
    turtle_turnLeft()
  end
  direction = NORTH
  return true
end

local function turnEast()
  if not direction then return false, DIRECTION_ERROR end
  if direction == NORTH then
    turtle_turnRight()
  elseif direction == SOUTH then
    turtle_turnLeft()
  elseif direction == WEST then
    turtle_turnLeft()
    turtle_turnLeft()
  end
  direction = EAST
  return true
end

local function turnSouth()
  if not direction then return false, DIRECTION_ERROR end
  if direction == EAST then
    turtle_turnRight()
  elseif direction == WEST then
    turtle_turnLeft()
  elseif direction == NORTH then
    turtle_turnLeft()
    turtle_turnLeft()
  end
  direction = SOUTH
  return true
end

local function turnWest()
  if not direction then return false, DIRECTION_ERROR end
  if direction == SOUTH then
    turtle_turnRight()
  elseif direction == NORTH then
    turtle_turnLeft()
  elseif direction == EAST then
    turtle_turnLeft()
    turtle_turnLeft()
  end
  direction = WEST
  return true
end

local function forward()
  if not x and z then return false, POSITION_ERROR end
  local nx = x + (direction == EAST and 1 or direction == WEST and -1 or 0)
  if minX and nx < minX or maxY and nx > maxX then return false, OOB_MOVE_ERROR end
  local nz = z + (direction == SOUTH and 1 or direction == NORTH and -1 or 0)
  if minZ and nz < minZ or maxZ and nz > maxZ then return false, OOB_MOVE_ERROR end
  local ok, message = turtle_forward()
  if not ok then return false, message end
  x = nx
  z = nz
  return true
end

local function back()
  if not x and z then return false, POSITION_ERROR end
  local nx = x + (direction == EAST and -1 or direction == WEST and 1 or 0)
  if minX and nx < minX or maxX and nx > maxX then return false, OOB_MOVE_ERROR end
  local nz = z + (direction == SOUTH and -1 or direction == NORTH and 1 or 0)
  if minZ and nz < minZ or maxZ and nz > maxZ then return false, OOB_MOVE_ERROR end
  local ok, message = turtle_back()
  if not ok then return false, message end
  x = nx
  z = nz
  return true
end

local function up()
  if not y then return false, POSITION_ERROR end
  local ny = y + 1
  if maxY and ny > maxY then return false, OOB_MOVE_ERROR end
  local ok, message = turtle_up()
  if not ok then return false, message end
  y = ny
  return true
end

local function down()
  if not y then return false, POSITION_ERROR end
  local ny = y - 1
  if minY and ny < minY then return false, OOB_MOVE_ERROR end
  local ok, message = turtle_down()
  if not ok then return false, message end
  y = ny
  return true
end

local function moveNorth()
  if not z then return false, POSITION_ERROR end
  local ok, message = turnNorth()
  if not ok then return false, message end
  local nz = z - 1
  if minZ and nz < minZ then return false, OOB_MOVE_ERROR end
  ok, message = turtle_forward()
  if not ok then return false, message end
  z = nz
  return true
end

local function moveEast()
  if not x then return false, POSITION_ERROR end
  local ok, message = turnEast()
  if not ok then return false, message end
  local nx = x + 1
  if maxX and nx > maxX then return false, OOB_MOVE_ERROR end
  ok, message = turtle_forward()
  if not ok then return false, message end
  x = nx
  return true
end

local function moveSouth()
  if not z then return false, POSITION_ERROR end
  local ok, message = turnSouth()
  if not ok then return false, message end
  local nz = z + 1
  if maxZ and nz > maxZ then return false, OOB_MOVE_ERROR end
  if not ok then return false, message end
  ok, message = turtle_forward()
  if not ok then return false, message end
  z = nz
  return true
end

local function moveWest()
  if not x then return false, POSITION_ERROR end
  local ok, message = turnWest()
  if not ok then return false, message end
  local nx = x - 1
  if minX and nx < minX then return false, OOB_MOVE_ERROR end
  if not ok then return false, message end
  ok, message = turtle_forward()
  if not ok then return false, message end
  x = nx
  return true
end

local function dig()
  local nx = x + (direction == EAST and 1 or direction == WEST and -1 or 0)
  if minX and nx < minX or maxX and nx > maxX then return false, OOB_DIG_ERROR end
  local nz = z + (direction == SOUTH and 1 or direction == NORTH and -1 or 0)
  if minZ and nz < minZ or maxZ and nz > maxZ then return false, OOB_DIG_ERROR end
  return turtle_dig()
end

local function digUp()
  if maxY and (y + 1) > maxY then return false, OOB_DIG_ERROR end
  return turtle_digUp()
end

local function digDown()
  if minY and (y - 1) < minY then return false, OOB_DIG_ERROR end
  return turtle_digDown()
end

local function place()
  local nx = x + (direction == EAST and 1 or direction == WEST and -1 or 0)
  if minX and nx < minX or maxX and nx > maxX then return false, OOB_PLACE_ERROR end
  local nz = z + (direction == SOUTH and 1 or direction == NORTH and -1 or 0)
  if minZ and nz < minZ or maxZ and nz > maxZ then return false, OOB_PLACE_ERROR end
  return turtle_place()
end

local function placeUp()
  if maxY and (y + 1) > maxY then return false, OOB_PLACE_ERROR end
  return turtle_placeUp()
end

local function placeDown()
  if minY and (y - 1) < minY then return false, OOB_PLACE_ERROR end
  return turtle_placeDown()
end

-- inspecting and detecting blocks is allowed out of bounds, though this may be changed in the future

--testing
local switch = {
  north = turnNorth,
  east = turnEast,
  south = turnSouth,
  west = turnWest,
  forward = forward,
  back = back,
  pl=place,
  pup=placeUp,
  pdn=placeDown,

}

--[[ init()
while true do
  print(x, y, z, direction)
  local input = read()
  print(switch[input]())
end ]]

local igps = {
  turnLeft = turnLeft,
  turnRight = turnRight,
  turnNorth = turnNorth,
  turnEast = turnEast,
  turnSouth = turnSouth,
  turnWest = turnWest,
  forward = forward,
  back = back,
  up = up,
  down = down,
  moveNorth = moveNorth,
  moveEast = moveEast,
  moveSouth = moveSouth,
  moveWest = moveWest,
  dig = dig,
  digUp = digUp,
  digDown = digDown,
  place = place,
  placeUp = placeUp,
  placeDown = placeDown,
}

for k,v in pairs(turtle) do
  if not igps[k] then igps[k] = v end
end
