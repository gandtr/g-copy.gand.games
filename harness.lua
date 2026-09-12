-- harness.lua — screenshot harness for agent-driven LÖVE development.
--
-- Lets an agent (or CI) run the game, capture frames, and exit — so changes can
-- be *seen* instead of guessed at. Zero-cost when LOVE_SHOT is unset: the module
-- returns immediately and no callbacks are wrapped.
--
-- Follows the SS_AUTOTEST / SS_BOOT_CHECK env-var convention already used here.
--
--   LOVE_SHOT=120           capture at frame 120
--   LOVE_SHOT=2s            capture at 2 seconds
--   LOVE_SHOT=60,180,300    several frames
--   LOVE_SHOT=1s,3s,5s      several times (may be mixed with frames)
--   LOVE_SHOT_DIR=shots     output directory        (default: screenshots)
--   LOVE_SHOT_NAME=boot     filename prefix         (default: shot)
--   LOVE_SHOT_QUIT=0        stay open after capture (default: quit)
--
-- Install: `require("harness")` as the LAST line of main.lua, so every
-- love.* callback it wraps is already defined.
--
-- Writes via io.open rather than love.filesystem so files land in the project
-- directory (relative to CWD) instead of LÖVE's save directory, where an agent
-- would have to go hunting for them.

local spec = os.getenv("LOVE_SHOT")
if not spec or spec == "" then return end

local dir      = os.getenv("LOVE_SHOT_DIR") or "screenshots"
local prefix   = os.getenv("LOVE_SHOT_NAME") or "shot"
local autoquit = os.getenv("LOVE_SHOT_QUIT") ~= "0"

-- Split the spec into frame triggers (bare integers) and time triggers (Ns).
local frames, times = {}, {}
for token in tostring(spec):gmatch("[^,%s]+") do
  local seconds = token:match("^([%d%.]+)s$")
  if seconds then
    times[#times + 1] = tonumber(seconds)
  elseif tonumber(token) then
    frames[#frames + 1] = math.floor(tonumber(token))
  else
    print("[harness] ignoring unparseable LOVE_SHOT token: " .. token)
  end
end
table.sort(frames)
table.sort(times)

if #frames == 0 and #times == 0 then
  print("[harness] LOVE_SHOT set but no valid triggers parsed; harness disabled")
  return
end

local frame, elapsed = 0, 0
local nextFrame, nextTime = 1, 1
local startTime, pending, quitAtFrame = nil, 0, nil

local function ensureDir()
  if package.config:sub(1, 1) == "\\" then
    os.execute('mkdir "' .. dir .. '" 2>nul')
  else
    os.execute("mkdir -p '" .. dir .. "'")
  end
end

local function capture(label)
  pending = pending + 1
  -- The callback fires after this frame is presented, not inline.
  love.graphics.captureScreenshot(function(imageData)
    local ok, err = pcall(function()
      ensureDir()
      local path = string.format("%s/%s-%s.png", dir, prefix, label)
      local file = assert(io.open(path, "wb"))
      file:write(imageData:encode("png"):getString())
      file:close()
      print(string.format("[harness] wrote %s (%dx%d)",
        path, imageData:getWidth(), imageData:getHeight()))
    end)
    if not ok then
      print("[harness] capture failed: " .. tostring(err))
    end
    pending = pending - 1
  end)
end

local originalDraw = love.draw

love.draw = function(...)
  -- Quit only once every scheduled shot has actually been written to disk;
  -- captureScreenshot callbacks land a frame or more after they are requested.
  if quitAtFrame and frame >= quitAtFrame and pending == 0 then
    love.event.quit()
    return
  end

  if originalDraw then originalDraw(...) end

  startTime = startTime or love.timer.getTime()
  frame = frame + 1
  elapsed = love.timer.getTime() - startTime

  while nextFrame <= #frames and frame >= frames[nextFrame] do
    capture("f" .. frames[nextFrame])
    nextFrame = nextFrame + 1
  end

  while nextTime <= #times and elapsed >= times[nextTime] do
    capture(string.format("t%gs", times[nextTime]))
    nextTime = nextTime + 1
  end

  if autoquit and not quitAtFrame
     and nextFrame > #frames and nextTime > #times then
    quitAtFrame = frame + 2
  end
end
