local sides = require("sides")

local config = {
  enableAutoUpdate = true, -- Enable auto update on start

  logger = {
    name = "Black Hole Control",
    timeZone = 3, -- Your time zone
    handlers = {
      ["discord"] = {
        type = "discord",
        logLevel = "warning",
        messageFormat = "{Time:%d.%m.%Y %H:%M:%S} [{LogLevel}]: {Message}",
        discordWebhookUrl = "" -- Discord Webhook URL
      },
      ["file"] = {
        type = "file",
        logLevel = "info",
        messageFormat = "{Time:%d.%m.%Y %H:%M:%S} [{LogLevel}]: {Message}",
        filePath = "logs.log"
      },
      ["scrollList"] = {
        type = "scrollList",
        logLevel = "debug",
        logsListSize = 128
      },
    }
  },

  controller = {
    blackHoleSeedsTransposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", -- Address of transposer which provide black hole seeds.
    blackHoleSeedInputBusSide = sides.south, -- Side of transposer which connected to seeds input bus.
    ioPortTransposerAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", -- Address of transposer which connected to ME Drive and ME IO Port.
    meDriveSide = sides.west, -- Side of transposer which connected to ME Drive.
    meIoPortSide = sides.east, -- Side of transposer which connected to ME IO Port.
    meInterfaceAddress = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", -- Address of ME Interface.
    saveRecipeMode = true, -- Recipe save mode.
    maxCyclesCount = 0, -- Maximum number of cycles. For calculation use: https://www.desmos.com/calculator/yrnt694v3h
  }
}

return config
