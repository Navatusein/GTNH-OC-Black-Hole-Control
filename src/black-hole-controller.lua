local event = require("event")
local computer = require("computer")
local term = require("term")

local classBuilder = require("lib.class-builder.index")
local componentDiscover = require("lib.component-discover.index")
local stateMachineBuilder = require("lib.state-machine-builder.index")

---@class BlackHoleControllerData
---@field spaceTimePerCraftCount integer
---@field currentCycle integer
---@field currentTimer integer
---@field currentCycleTimer integer
---@field notifyNotEnoughSpaceTime boolean
---@field requestCount integer
---@field startTime? number
---@field cycleStartTime? number
---@field errorMessage? string

---Convert number to string with commas
---@param number number
---@return string
local function numWithCommas(number)
  return tostring(math.floor(number)):reverse():gsub("(%d%d%d)","%1,"):gsub(",(%-?)$","%1"):reverse()
end

---@class BlackHoleController
---@field stateMachine StateMachine<BlackHoleControllerData>
---@field blackHoleSeedsTransposerAddress string
---@field blackHoleSeedInputBusSide integer
---@field ioPortTransposerAddress string
---@field meDriveSide integer
---@field meIoPortSide integer
---@field meInterfaceAddress string
---@field saveRecipeMode boolean
---@field maxCyclesCount integer
---@field maxTimer integer
---@field maxCycleTimer integer
---@field controllerProxy gt_machine
---@field craftingInputsProxies gt_machine[]
---@field blackHoleSeedsTransposerProxy transposer
---@field ioPortTransposerProxy transposer
---@field meInterfaceProxy fluid_interface
---@field databaseProxy database
---@field transposerItems table<string, TransposerItemStorageDescriptor>
---@field fakeRecipeName string
local blackHoleController = {}

---Constructor
---@param blackHoleSeedsTransposerAddress string
---@param blackHoleSeedInputBusSide integer
---@param ioPortTransposerAddress string
---@param meDriveSide integer
---@param meIoPortSide integer
---@param meInterfaceAddress string
---@param saveRecipeMode boolean
---@param maxCyclesCount integer
---@return BlackHoleController
function blackHoleController:constructor(
  blackHoleSeedsTransposerAddress,
  blackHoleSeedInputBusSide,
  ioPortTransposerAddress,
  meDriveSide,
  meIoPortSide,
  meInterfaceAddress,
  saveRecipeMode,
  maxCyclesCount
)
  self.blackHoleSeedsTransposerAddress = blackHoleSeedsTransposerAddress
  self.blackHoleSeedInputBusSide = blackHoleSeedInputBusSide
  self.ioPortTransposerAddress = ioPortTransposerAddress
  self.meDriveSide = meDriveSide
  self.meIoPortSide = meIoPortSide
  self.meInterfaceAddress = meInterfaceAddress
  self.saveRecipeMode = saveRecipeMode
  self.maxCyclesCount = maxCyclesCount

  self.maxTimer = 85
  self.maxCycleTimer = 25

  self.transposerItems = {}
  self.fakeRecipeName = ""

  self.stateMachine = stateMachineBuilder.stateMachine:new()

  return self
end

---Init
function blackHoleController:init()
  term.clear()

  term.write("Init components: ")
  self:initComponents()
  term.write("ok\n")

  term.write("Reset to idle state: ")
  self:resetToIdleState()
  term.write("ok\n")

  term.write("Init state machine: ")
  self:initStateMachine()
  term.write("ok\n")
end

---Loop
function blackHoleController:loop()
  if self.stateMachine.data.startTime ~= nil then
    self.stateMachine.data.currentTimer = self:getCurrentTimerTime(self.stateMachine.data.startTime)
  end

  if self.stateMachine.data.cycleStartTime ~= nil then
    self.stateMachine.data.currentCycleTimer = self:getCurrentTimerTime(self.stateMachine.data.cycleStartTime)
  end

  self.stateMachine:loop()
end

---Get current state
---@return string
function blackHoleController:getCurrentState()
  return self.stateMachine:getCurrentStateName()
end

---Get controller timers
---@return number
---@return number
---@return number
function blackHoleController:getTimers()
  return self.stateMachine.data.currentTimer, self.stateMachine.data.currentCycleTimer, self.stateMachine.data.currentCycle
end

---Reset error state
function blackHoleController:resetError()
  if self.stateMachine:getCurrentStateKey() == "error" then
    self.stateMachine:setState("waitEnd")
  end
end

---Init components
---@private
function blackHoleController:initComponents()
  self.controllerProxy = componentDiscover.gtMachine("multimachine.blackholecompressor")

  if self.controllerProxy == nil then
    error("Pseudostable Black Hole Containment Field not found")
  end

  self.craftingInputsProxies = componentDiscover.gtMachineList("hatch.crafting_input")

  if next(self.craftingInputsProxies) == nil then
    error("Crafting inputs not found")
  end

  self.blackHoleSeedsTransposerProxy = componentDiscover.proxy(self.blackHoleSeedsTransposerAddress, "transposer", "Black hole seed transposer")
  self.ioPortTransposerProxy = componentDiscover.proxy(self.ioPortTransposerAddress, "transposer", "ME IO Port Transposer")
  self.meInterfaceProxy = componentDiscover.proxy(self.meInterfaceAddress, "fluid_interface", "ME fluid interface")

  self.databaseProxy = componentDiscover.component("database", "Database")

  self.fakeRecipeName = "Fake recipe "..self.databaseProxy.address:sub(0, 8)

  self.databaseProxy.set(1, "minecraft:paper", 0, "{display:{Name:\""..self.fakeRecipeName.."\"}}")

  self:findTransposerItem(self.blackHoleSeedsTransposerProxy, {"Black Hole Seed", "Black Hole Collapser"})
end

---Init state machine
---@private
function blackHoleController:initStateMachine()
  self.stateMachine.data.spaceTimePerCraftCount = self:calculateSpaceTimeCount(self.maxCyclesCount)

  self.stateMachine:createState("idle", "Idle", {
    onInit = function ()
      self.stateMachine.data.startTime = nil
      self.stateMachine.data.cycleStartTime = nil
      self.stateMachine.data.currentCycle = 0
      self.stateMachine.data.currentTimer = 0
      self.stateMachine.data.currentCycleTimer = 0
      self.stateMachine.data.notifyNotEnoughSpaceTime = false

      if self.saveRecipeMode == true or self.maxCyclesCount ~= 0 then
        self:removeExcessSpacetime()
      end
    end,
    onUpdate = function ()
      if self.controllerProxy.getWorkMaxProgress() == 0 then
        if self:hasItems() == true and self.controllerProxy.isWorkAllowed() then
          if self:hasSeeds() == true then
            if self:hasEnoughSpacetime(self.stateMachine.data.spaceTimePerCraftCount) then
              self.stateMachine:setState("openBlackHole")
              return
            elseif self.stateMachine.data.notifyNotEnoughSpaceTime == false then
              self.stateMachine.data.notifyNotEnoughSpaceTime = true
              event.push("log_warning", "Not enough Space Time for craft. Need: "..numWithCommas(self.stateMachine.data.spaceTimePerCraftCount))
            end

            os.sleep(3)
          end
        end
      end
    end
  })

  self.stateMachine:createState("openBlackHole", "Open Black Hole", {
    onInit = function ()
      self:openBlackHole()
    end,
    onUpdate = function ()
      if self.blackHoleSeedsTransposerProxy.getSlotStackSize(self.blackHoleSeedInputBusSide, 1) == 0 then
        self.stateMachine.data.startTime = computer.uptime() - 1
        self.stateMachine.data.currentCycle = 0
        self.stateMachine:setState("waitFreeCraft")
      end
    end
  })

  self.stateMachine:createState("waitFreeCraft", "Wait Free Craft", {
    onUpdate = function ()
      if self.stateMachine.data.currentTimer >= self.maxTimer then
        if self.maxCyclesCount ~= 0 and (self:hasItems() == true or self:getCraftTimeRemained() ~= 0) then
          self.stateMachine:setState("addSpaceTime")
        else
          if self:getCraftTimeRemained() > self:getStabilityTimeRemained() and self.saveRecipeMode == true then
            self.stateMachine:setState("saveRecipe")
          else
            self.stateMachine:setState("collapseBlackHole")
          end
        end
      end
    end
  })

  self.stateMachine:createState("addSpaceTime", "Add Space Time", {
    onInit = function ()
      self.stateMachine.data.cycleStartTime = computer.uptime()
      self.stateMachine.data.currentCycleTimer = 0
      self.stateMachine.data.currentCycle = self.stateMachine.data.currentCycle + 1

      local spacetimeCount = self:calculateSpaceTimeByCycleCount(self.stateMachine.data.currentCycle)
      self.stateMachine.data.requestCount = self:encodePattern(spacetimeCount)
    end,
    onUpdate = function ()
      if self:requestFakeRecipe(self.stateMachine.data.requestCount) == true or self:hasFakeRecipe() == true then
        self.stateMachine:setState("waitSpaceTime")
      else
        self.stateMachine.data.errorMessage = "Cant request craft: "..self.fakeRecipeName
        self.stateMachine:setState("error")
      end
    end,
    onExit = function ()
      while self:tryCancelFakeRecipe() == false do
        os.sleep(0.1)
      end
    end
  })

  self.stateMachine:createState("waitSpaceTime", "Wait Space Time", {
    onUpdate = function ()
      if self.controllerProxy.getWorkMaxProgress() == 0 and self:hasItems() == false then
        self.stateMachine:setState("collapseBlackHole")
      elseif self.stateMachine.data.currentCycleTimer >= self.maxCycleTimer or self.stateMachine.data.currentCycle == self.maxCyclesCount then
        if self.stateMachine.data.currentCycle < self.maxCyclesCount then
          self.stateMachine:setState("addSpaceTime")
        elseif self.saveRecipeMode == true and self:getCraftTimeRemained() > self:getStabilityTimeRemained() then
          self.stateMachine:setState("saveRecipe")
        else
          self.stateMachine:setState("collapseBlackHole")
        end
      end
    end
  })

  self.stateMachine:createState("saveRecipe", "Save Recipe", {
    onInit = function ()
      local secondsRemained = math.floor(self:getCraftTimeRemained() - self:getStabilityTimeRemained())

      local needCycles = math.floor(secondsRemained / 30) + self.stateMachine.data.currentCycle
      local needTime = math.floor(secondsRemained % 30)

      local needSpaceTime = 0

      if needCycles ~= self.stateMachine.data.currentCycle then
        needSpaceTime = needSpaceTime + self:calculateSpaceTimeCount(needCycles, self.stateMachine.data.currentCycle)
      end

      needSpaceTime = needSpaceTime + self:calculateSpaceTimeByCycleCount(needCycles + 1, needTime)

      event.push("log_info", "[Save mode] Need:"..secondsRemained.." Added spacetime: "..numWithCommas(needSpaceTime))

      self.stateMachine.data.requestCount = self:encodePattern(needSpaceTime)
    end,
    onUpdate = function ()
      if self:requestFakeRecipe(self.stateMachine.data.requestCount) == true or self:hasFakeRecipe() == true then
        self.stateMachine:setState("collapseBlackHole")
      else
        self.stateMachine.data.errorMessage = "Cant request craft: "..self.fakeRecipeName
        self.stateMachine:setState("error")
      end
    end,
    onExit = function ()
      while self:tryCancelFakeRecipe() == false do
        os.sleep(0.1)
      end
    end
  })

  self.stateMachine:createState("collapseBlackHole", "Collapse Black Hole", {
    onInit = function ()
      self:collapseBlackHole()
      self.stateMachine:setState("waitEnd")
    end
  })

  self.stateMachine:createState("waitEnd", "Wait end", {
    onUpdate = function ()
      if self.controllerProxy.getWorkMaxProgress() == 0 then
        self.stateMachine:setState("idle")
      end
    end
  })

  self.stateMachine:createState("error", "Error", {
    onInit = function ()
      self:collapseBlackHole()

      self.stateMachine.data.startTime = nil
      self.stateMachine.data.cycleStartTime = nil

      while self:tryCancelFakeRecipe() == false do
        os.sleep(0.1)
      end

      event.push("log_error", self.stateMachine.data.errorMessage)
      event.push("log_info","&red;Press Enter to confirm")

      self.stateMachine.data.errorMessage = nil
    end
  })

  self.stateMachine:setState("idle")
end

---Reset setup state for idle state
---@private
function blackHoleController:resetToIdleState()
  self:clearPattern()
end

---Find transposer item
---@param proxy transposer
---@param itemLabels string[]
---@private
function blackHoleController:findTransposerItem(proxy, itemLabels)
  local result, skipped = componentDiscover.transposerItemStoragesByLabels(proxy, itemLabels, {self.blackHoleSeedInputBusSide})

  if #skipped ~= 0 then
    error("Can't find items: "..table.concat(skipped, ", "))
  end

  for key, value in pairs(result) do
    self.transposerItems[key] = value
  end
end

---Clear inputs and outputs of the fake pattern
---@private
function blackHoleController:clearPattern()
  local pattern = self.meInterfaceProxy.getInterfacePattern(1)

  if pattern == nil then
    error("No pattern in Interface")
  end

  self.meInterfaceProxy.setInterfacePatternOutput(1, 1, self.databaseProxy.address, 1, 1)
  self.meInterfaceProxy.setInterfacePatternInput(1, 1, self.databaseProxy.address, 1, 1)

  for key, _ in pairs(pattern.outputs) do
    if key ~= 1 then
      self.meInterfaceProxy.clearInterfacePatternOutput(1, key)
    end
  end

  for key, _ in pairs(pattern.inputs) do
    if key ~= 1 then
      self.meInterfaceProxy.clearInterfacePatternInput(1, key)
    end
  end
end

---Check if crafting inputs has items for craft
---@return boolean
---@private
function blackHoleController:hasItems()
  for _, proxy in pairs(self.craftingInputsProxies) do
    local sensorInformation = proxy.getSensorInformation()

    if sensorInformation[2] ~= nil then
      local startIndex = string.match(sensorInformation[2], "Internal Inventory:") ~= nil and 3 or 4
      local endIndex = #sensorInformation

      for i = startIndex, endIndex, 1 do
        if string.match(sensorInformation[i], "GT5U.infodata.hatch.internal_inventory.slot") == nil then
          return true
        end
      end
    end
  end

  return false
end

---Check if interface has seeds to craft
---@return boolean
---@private
function blackHoleController:hasSeeds()
  for _, value in pairs(self.transposerItems) do
    local slot = self.blackHoleSeedsTransposerProxy.getStackInSlot(value.side, value.slot)

    if slot == nil or slot.size < 1 then
      return false
    end
  end

  return true
end

---Check if ae has enough space time for craft
---@param spaceTimeCount integer
---@return boolean
---@private
function blackHoleController:hasEnoughSpacetime(spaceTimeCount)
  local fluids = self.meInterfaceProxy.getFluidsInNetwork()

  for _, value in pairs(fluids) do
    if value.name == "molten.spacetime" and value.amount >= spaceTimeCount then
      return true
    end
  end

  return false
end

---Calculate timer time
---@param timer number
---@return integer
---@private
function blackHoleController:getCurrentTimerTime(timer)
  return math.floor(computer.uptime() - timer)
end

---Get craft remained time
---@return integer
---@private
function blackHoleController:getCraftTimeRemained()
  local craftTime = self.controllerProxy.getWorkProgress() / 20
  local maxCraftTime = self.controllerProxy.getWorkMaxProgress() / 20

  return maxCraftTime - craftTime
end

---Get stability remained time
---@return integer
---@private
function blackHoleController:getStabilityTimeRemained()
  return (95 + 30 * self.maxCyclesCount) - self.stateMachine.data.currentTimer
end

---Calculates space time consumption per cycle
---@param cycle integer
---@param time? integer
---@return integer
---@private
function blackHoleController:calculateSpaceTimeByCycleCount(cycle, time)
  time = time or 30

  return math.ceil(time * 2 ^ (cycle - 1))
end

---Calculates space time consumption for cycles
---@param cycles integer
---@param startCycle? integer
---@return integer
---@private
function blackHoleController:calculateSpaceTimeCount(cycles, startCycle)
  startCycle = startCycle ~= 0 and startCycle or 1

  local count = 0

  for i = startCycle, cycles, 1 do
    count = count + self:calculateSpaceTimeByCycleCount(i)
  end

  return math.ceil(count)
end

---Encode fake pattern
---@param spaceTimeCount number
---@return integer
---@private
function blackHoleController:encodePattern(spaceTimeCount)
  local requests = 1

  local a = spaceTimeCount

  while spaceTimeCount > 2000000000 do
    spaceTimeCount = math.ceil(spaceTimeCount / 2)
    requests = requests * 2
  end

  if (spaceTimeCount * requests) ~= a then
    event.push("log_debug", "Too much: "..numWithCommas((spaceTimeCount * requests) - a).." / "..numWithCommas(a).." / "..numWithCommas(spaceTimeCount * requests))
  end

  self.meInterfaceProxy.setInterfacePatternInput(1, 1, {name = "molten.spacetime", size = spaceTimeCount}, "fluid")

  return requests
end

---Request fake pattern
---@param requestCount integer
---@return boolean
---@private
function blackHoleController:requestFakeRecipe(requestCount)
  local recipe = self.meInterfaceProxy.getCraftables({label = self.fakeRecipeName})[1]
  local craft = recipe.request(requestCount)

  while craft.isComputing() == true do
    os.sleep(0.1)
  end

  return craft.hasFailed() == false
end

---Try cancel craft of the faker pattern
---@return boolean
---@private
function blackHoleController:tryCancelFakeRecipe()
  local cpus = self.meInterfaceProxy.getCpus()

  for _, value in pairs(cpus) do
    if value.cpu.isBusy() == true then
      local output = value.cpu.finalOutput()

      if output == nil then
        return false
      end

      if output.label == self.fakeRecipeName then
        local isCanceled = value.cpu.cancel()
        return isCanceled
      end
    end
  end

  return true
end

---Check if craft of the fake pattern is failed
---@return boolean
---@private
function blackHoleController:hasFakeRecipe()
  local cpus = self.meInterfaceProxy.getCpus()

  for _, value in pairs(cpus) do
    if value.cpu.isBusy() == true then
      local output = value.cpu.finalOutput()

      if output ~= nil and output.label == self.fakeRecipeName then
        return true
      end
    end
  end

  return false
end

---Remove excess spacetime from black hole
---@private
function blackHoleController:removeExcessSpacetime()
  self.ioPortTransposerProxy.transferItem(self.meDriveSide, self.meIoPortSide, 1)

  while self.ioPortTransposerProxy.getSlotStackSize(self.meIoPortSide, 7) ~= 1 do
    os.sleep(0.1)
  end

  self.ioPortTransposerProxy.transferItem(self.meIoPortSide, self.meDriveSide, 1)
end

---Put seed to open black hole
---@private
function blackHoleController:openBlackHole()
  self.blackHoleSeedsTransposerProxy.transferItem(
    self.transposerItems["Black Hole Seed"].side,
    self.blackHoleSeedInputBusSide,
    1,
    self.transposerItems["Black Hole Seed"].slot)
end

---Put seed to collapse black hole
---@private
function blackHoleController:collapseBlackHole()
  self.blackHoleSeedsTransposerProxy.transferItem(
    self.transposerItems["Black Hole Collapser"].side,
    self.blackHoleSeedInputBusSide,
    1,
    self.transposerItems["Black Hole Collapser"].slot)
end

return classBuilder.createClass(blackHoleController, blackHoleController.constructor, "BlackHoleController")
