# GTNH-OC-Black-Hole-Control 

## Content

- [Information](#information)
- [Installation](#installation)
- [Setup](#setup)
- [Configuration](#configuration)

<a id="information"></a>

## Information

The program is designed to automate Black Hole. The program is able to add Space Time 
to keep the stability, also has Save Recipe Mode which will add just the right 
amount of spacetime to keep the recipe from being voided.

#### Controls

<kbd>Q</kbd> - Closing the program

<kbd>Delete</kbd> - Clear scroll list

<kbd>Arrow Up</kbd> - Scroll list up

<kbd>Arrow Down</kbd> - Scroll list down

#### Interface

![Interface](/docs/interface.png)

<a id="installation"></a>

> [!CAUTION]
> If you are using 8 java, the installer will not work for you. 
> The only way to install the program is to manually transfer it to your computer.
> The problem is on the java side.

To install program, you need a computer with:
- Graphics Card (Tier 3): 1
- Central Processing Unit (CPU) (Tier 3): 1
- Memory (Tier 3.5): 2
- Hard Disk Drive (Tier 3) (4MB): 1
- EEPROM (Lua BIOS): 1
- Internet Card: 1

![Computer setup](/docs/computer.png)

Install the basic Open OS on your computer.
Then run the command to start the installer.

```shell
pastebin run ESUAMAGx
``` 

Then select the Black Hole Control  program in the installer.
If you wish you can add the program to auto download, for manual start write a command.

```shell
main
```

> [!NOTE]  
> For convenient configuration you can use the web configurator.
> [GTNH-OC-Web-Configurator](https://navatusein.github.io/GTNH-OC-Web-Configurator/#/configurator?url=https%3A%2F%2Fraw.githubusercontent.com%2FNavatusein%2FGTNH-OC-Black-Hole-Control%2Fmain%2Fconfig-descriptor.yml)

<a id="setup"></a>

## Setup

To build a setup, you will need:

- Transposer: 2
- Adapter: 3
- MFU: 2
- Database: 1

You need to make a separate subnet for this set-up further than the black hole subnet (It is red in the diagrams). 
It should see Space Time from the main network (It is green in the diagrams), it should also contain 
“Fluid Discretizer” and CPU with “Crafting Monitor”. The number of CPUs is 
equal to the number of black holes connected to the subnet.

![Black hole subnet setup](/docs/black-hole-subnet.png)

To add a Space Time, you need to make one more mini subnet further than the input subnet 
(It is purple on the diagram). The program adds a Space Time by ordering a fake recipe. 
This is done because there is no easier way to add a large number of Space Time. 
The mini subsystem consists of: “ME Dual Interface”, ‘ME Drive’, 
‘Stocking Input Hatch (ME)’. In the “ME Drive” you need to put a fluid cell. 
Also in this part there is a transposer and “ME IO Port”. This part is needed to drain 
the Space Time residue into the black hole subsystem. 
You should also put “Database Upgrade (Tier 3)” in the adapter.

> [!CAUTION]
> To work properly, you need to put any liquid сraft template (which is pink) in the interface.

![Input subnet setup](/docs/input-subnet.png)

To feed the seeds, you must install a trasposer from the interfaces in which the seeds are configured. 
The trasposer transfers the seeds to the bus input on which it is installed.

![Seeds trasposer](/docs/seeds-transposer.png)

You must also connect the “Crafting Input Buffer (ME)” or “Crafting Input Bus (ME)” or “Crafting Input Proxy” 
to the computer via the MFU. The MFU is placed in the adapter.

![Inputs mfu](/docs/input-mfu.png)

Also, the black hole controller must be connected via MFU to the adapter.

![Controller mfu](/docs/controller-mfu.png)

## Configuration

> [!NOTE]  
> For convenient configuration you can use the web configurator.
> [GTNH-OC-Web-Configurator](https://navatusein.github.io/GTNH-OC-Web-Configurator/#/configurator?url=https%3A%2F%2Fraw.githubusercontent.com%2FNavatusein%2FGTNH-OC-Black-Hole-Control%2Fmain%2Fconfig-descriptor.yml)

General configuration in file `config.lua`

Enable auto update when starting the program.

```lua
enableAutoUpdate = true, -- Enable auto update on start
```

In the `timeZone` field you can specify your time zone.

In the `discordWebhookUrl` field, you can specify the Discord Webhook link so that the program sends messages to the discord about emergency situations.
[How to Create a Discord Webhook?](https://www.svix.com/resources/guides/how-to-make-webhook-discord/)

```lua
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
      logsListSize = 32
    }),
  }
}),
```

In the `blackHoleSeedsTransposerAddress` field you specify address of the transposer witch provide black hole seeds.

In the `blackHoleSeedInputBusSide` field you specify side of the transposer witch connected to seeds input bus.

In the `ioPortTransposerAddress` field you specify address of the transposer witch connected to ME Drive and ME IO Port.

In the `meDriveSide` field you specify side of the transposer witch connected to ME Drive.

In the `meIoPortSide` field you specify side of the transposer witch connected to ME IO Port.

In the `meInterfaceAddress` field you specify address of the me interface witch connected to input subnet.

In the `saveRecipeMode` field you specify enable save recipe mode that will add just the right amount of spacetime to keep the recipe from being voided.

In the `maxCyclesCount` field you specify number of spacetime addition cycles. Each cycle is 30 seconds. Use the calculator to calculate consumption. [Link to calculator](https://www.desmos.com/calculator/yrnt694v3h)

> [!CAUTION]
> For a stable “Superdense Magnetohydrodynamically Constrained Star Matter Plate” 
> craft, specify 27 cycles in the `maxCyclesCount` field.


```lua
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
```