local configManager = require("lib.config-manager.index")
local logger = require("lib.oc-logger.index")

local blackHoleController = require("src.black-hole-controller")

---@class Config
---@field enableAutoUpdate boolean
---@field logger Logger
---@field controller BlackHoleController

local configTemplate = {
  enableAutoUpdate = configManager.validators.boolean:new(),

  logger = configManager.validators.object:new(
    {
      template = {
        name = configManager.validators.string:new(),
        timeZone = configManager.validators.number:new({
          isInteger = {value = true}
        }),
        handlers = configManager.validators.typedObjectList:new({
          templates = {
            ["discord"] = configManager.validators.object:new(
              {
                template = {
                  logLevel = configManager.validators.enum:new({
                    "debug", "info", "warning", "error"
                  }),
                  messageFormat = configManager.validators.string:new(),
                  discordWebhookUrl = configManager.validators.string:new({
                    isNullable = {value = true}
                  }),
                },
                objectFactory = function (value)
                  return logger.handlers.discord:new(value.logLevel, value.messageFormat, value.discordWebhookUrl)
                end
              }
            ),
            ["file"] = configManager.validators.object:new(
              {
                template = {
                  logLevel = configManager.validators.enum:new({
                    "debug", "info", "warning", "error"
                  }),
                  messageFormat = configManager.validators.string:new(),
                  filePath = configManager.validators.string:new(),
                },
                objectFactory = function (value)
                  return logger.handlers.file:new(value.logLevel, value.messageFormat, value.filePath)
                end
              }
            ),
            ["scrollList"] = configManager.validators.object:new(
              {
                template = {
                  logLevel = configManager.validators.enum:new({
                    "debug", "info", "warning", "error"
                  }),
                  logsListSize = configManager.validators.number:new({
                    min = {value = 16}
                  }),
                },
                objectFactory = function (value)
                  return logger.handlers.scrollList:new(value.logLevel, value.logsListSize)
                end
              }
            ),
          }
        }),
      },
      objectFactory = function (value)
        return logger.logger:new(value.name, value.timeZone, value.handlers)
      end
    }
  ),

  controller = configManager.validators.object:new({
    template = {
      blackHoleSeedsTransposerAddress = configManager.validators.address:new(),
      blackHoleSeedInputBusSide = configManager.validators.side:new(),
      ioPortTransposerAddress = configManager.validators.address:new(),
      meDriveSide = configManager.validators.side:new(),
      meIoPortSide = configManager.validators.side:new(),
      meInterfaceAddress = configManager.validators.address:new(),
      saveRecipeMode = configManager.validators.boolean:new(),
      maxCyclesCount = configManager.validators.number:new({
        isInteger = {value = true},
        min = {value = 0}
      }),
    },
    objectFactory = function (value)
      return blackHoleController:new(
        value.blackHoleSeedsTransposerAddress,
        value.blackHoleSeedInputBusSide,
        value.ioPortTransposerAddress,
        value.meDriveSide,
        value.meIoPortSide,
        value.meInterfaceAddress,
        value.saveRecipeMode,
        value.maxCyclesCount
      )
    end
  })
}

return configTemplate
