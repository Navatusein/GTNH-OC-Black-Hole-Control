local keyboard = require("keyboard")

local programLib = require("lib.program-lib")
local guiLib = require("lib.gui-lib")

local scrollList = require("lib.gui-widgets.scroll-list")

package.loaded.config = nil
local config = require("config")

local version = require("version")

local repository = "Navatusein/GTNH-OC-Black-Hole-Control"
local archiveName = "BlackHoleControl"

local program = programLib:new(config.logger, config.enableAutoUpdate, version, repository, archiveName)
local gui = guiLib:new(program)

local logo = {
" ____  _            _      _   _       _         ____            _             _ ",
"| __ )| | __ _  ___| | __ | | | | ___ | | ___   / ___|___  _ __ | |_ _ __ ___ | |",
"|  _ \\| |/ _` |/ __| |/ / | |_| |/ _ \\| |/ _ \\ | |   / _ \\| '_ \\| __| '__/ _ \\| |",
"| |_) | | (_| | (__|   <  |  _  | (_) | |  __/ | |__| (_) | | | | |_| | | (_) | |",
"|____/|_|\\__,_|\\___|_|\\_\\ |_| |_|\\___/|_|\\___|  \\____\\___/|_| |_|\\__|_|  \\___/|_|"
}

local mainTemplate = {
  width = 60,
  background = gui.palette.black,
  foreground = gui.palette.white,
  widgets = {
    logsScrollList = scrollList:new("logsScrollList", "logs", keyboard.keys.up, keyboard.keys.down)
  },
  lines = {
    "Status: $state$",
    "Timer: $currentTimer$ ($currentCycleTimer$)",
    "Cycle: $currentCycle$",
    "",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#",
    "#logsScrollList#"
  }
}

local function init()
  gui:setTemplate(mainTemplate)
  os.sleep(0.1)
  config.controller:init()
end

local function loop()
  while true do
    config.controller:loop()
    os.sleep(1)
  end
end

local function guiLoop()
  local currentTimer, currentCycleTimer, currentCycle = config.controller:getState()

  gui:render({
    state = config.controller.stateMachine.currentState ~= nil and config.controller.stateMachine.currentState.name or "nil",
    logs = config.logger.handlers[3]["logs"].list,
    currentTimer = currentTimer,
    currentCycleTimer = currentCycleTimer,
    currentCycle = currentCycle
  })
end

local function errorButtonHandler()
  config.controller:resetError()
end

local function clearErrorList()
  ---@type ScrollListLoggerHandler|LoggerHandler
  local logger = config.logger.handlers[3]
  logger:clearList()
end

local function dump()
  ---@type ScrollListLoggerHandler|LoggerHandler
  local logger = config.logger.handlers[3]

  local file = assert(io.open("debug-logs.txt", "w"))

  for i = 1, #logger.logs.list, 1 do
    file:write(logger.logs.list[i].."\n")
  end

  file:close()
end

program:registerLogo(logo)
program:registerInit(init)
program:registerThread(loop)
program:registerTimer(guiLoop, math.huge)
program:registerKeyHandler(keyboard.keys.enter, errorButtonHandler)
program:registerKeyHandler(keyboard.keys.d, dump)
program:registerKeyHandler(keyboard.keys.delete, clearErrorList)
program:start()