local sides = require("sides")

local loggerLib = require("lib.logger-lib")
local discordLoggerHandler = require("lib.logger-handler.discord-logger-handler-lib")
local fileLoggerHandler = require("lib.logger-handler.file-logger-handler-lib")
local scrollListLoggerHandler = require("lib.logger-handler.scroll-list-logger-handler-lib")

local blackHoleController = require("src.black-hole-controller")

local config = {
  enableAutoUpdate = true, -- Enable auto update on start

  logger = loggerLib:newFormConfig({
    name = "Black Hole Control",
    timeZone = 3, -- Your time zone
    handlers = {
      discordLoggerHandler:newFormConfig({
        logLevel = "warning",
        messageFormat = "{Time:%d.%m.%Y %H:%M:%S} [{LogLevel}]: {Message}",
        discordWebhookUrl = "" -- Discord Webhook URL
      }),
      fileLoggerHandler:newFormConfig({
        logLevel = "info",
        messageFormat = "{Time:%d.%m.%Y %H:%M:%S} [{LogLevel}]: {Message}",
        filePath = "logs.log"
      }),
      scrollListLoggerHandler:newFormConfig({
        logLevel = "debug",
        logsListSize = 128
      }),
    }
  }),

  controller = blackHoleController:newFormConfig({
    blackHoleSeedsTransposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", -- Address of transposer which provide black hole seeds.
    blackHoleSeedInputBusSide = sides.south, -- Side of transposer which connected to seeds input bus.
    ioPortTransposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", -- Address of transposer which connected to ME Drive and ME IO Port.
    meDriveSide = sides.west, -- Side of transposer which connected to ME Drive.
    meIoPortSide = sides.east, -- Side of transposer which connected to ME IO Port.
    meInterfaceAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", -- Address of ME Interface.
    saveRecipeMode = true, -- Recipe save mode.
    maxCyclesCount = 0, -- Maximum number of cycles. For calculation use: https://www.desmos.com/calculator/yrnt694v3h
  })
}

return config