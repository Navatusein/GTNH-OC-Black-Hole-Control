local keyboard = require("keyboard")

local configManager = require("lib.config-manager.index")
local programController = require("lib.program-controller.index")
local simpleGui = require("lib.simple-gui.index")

local configTemplate = require("src.config-template")
local scrollList = require("src.gui-widgets.scroll-list")

package.loaded.config = nil
local config = require("config")
local version = require("version")

---@type Config
local config = configManager.manager:new(configTemplate):build(config)

local repository = "Navatusein/GTNH-OC-Black-Hole-Control"
local archiveName = "BlackHoleControl"

local program = programController.program:new(config.enableAutoUpdate, version, repository, archiveName)
local gui = simpleGui.gui:new(program)

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
    logsScrollList = scrollList:new("logs", keyboard.keys.up, keyboard.keys.down)
  },
  lines = {
    "Status: $state$",
    "Require Space Time: $spaceTimePerCraftCount:n,,%0.f$",
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
    "#logsScrollList#"
  }
}

local function init()
  gui:setTemplate(mainTemplate)
  config.controller:init()
end

local function loop()
  while true do
    config.controller:loop()
    os.sleep(1)
  end
end

local function guiLoop()
  local currentTimer, currentCycleTimer, currentCycle = config.controller:getTimers()

  gui:render({
    state = config.controller:getCurrentState(),
    logs = config.logger.handlers["scrollList"]:getLogs(),
    spaceTimePerCraftCount = config.controller.stateMachine.data.spaceTimePerCraftCount,
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
  local logger = config.logger.handlers["scrollList"]
  logger:clearLogs()
end

local function dump()
  ---@type ScrollListLoggerHandler|LoggerHandler
  local logger = config.logger.handlers["scrollList"]

  local logs = logger:getLogs()
  local file = assert(io.open("debug-logs.txt", "w"))

  for i = 1, #logs, 1 do
    file:write(logs[i].."\n")
  end

  file:close()
end

program:registerLogo(logo)
program:registerOnInit(init)
program:registerThread(loop)
program:registerTimer(guiLoop, math.huge, 1)
program:registerKeyHandler(keyboard.keys.enter, errorButtonHandler)
program:registerKeyHandler(keyboard.keys.d, dump)
program:registerKeyHandler(keyboard.keys.delete, clearErrorList)
program:start()
