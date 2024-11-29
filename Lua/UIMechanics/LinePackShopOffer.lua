local MAX_LINE_ITEM = 40
local LINEPACK_VISIBLE_DURATION = 3 * 24 * 3600

local LinePackArrow: ImageLabel = LinePack.Gamepasses.Content.Passes.arrow
local ItemPackTemplate: Frame = LinePack.Gamepasses.Content.Passes.Template
local LinePackParent = LinePack.Gamepasses.Content.Passes
local LineConfig = require(script.LineConfig)

local CurrentLineItem = Root.Data.LineItem
local canShow = true

local function getLocalDateTime()
    local localTime = DateTime.now():ToLocalTime()
    return DateTime.fromLocalTime(
        localTime.Year, localTime.Month, localTime.Day,
        localTime.Hour, localTime.Minute, localTime.Second
    )
end

local function calculateDateDifferenceInSeconds(dateString1)
    local dateTime1
    local localTime = getLocalDateTime()

    if not dateString1 or dateString1 == '' or dateString1 == 0 then
        dateTime1 = localTime:AddDays(3)
        Root.Bridge:Fire('LimitedOffer', 'OnPlayerJoinLinePack', localTime)
    else
        dateTime1 = DateTime.fromUniversalTime(
            dateString1.Year, dateString1.Month, dateString1.Day + 3,
            dateString1.Hour, dateString1.Minute, dateString1.Second
        )
    end

    return math.abs(dateTime1.UnixTimestamp - localTime.UnixTimestamp)
end

local function startTimer(duration)
    task.spawn(function()
        local remainingTime = duration

        while remainingTime > 0 do
            remainingTime = remainingTime - task.wait(1)

            local hours = math.floor(remainingTime / 3600)
            local minutes = math.floor((remainingTime % 3600) / 60)
            local seconds = math.floor(remainingTime % 60)

            LinePack.Gamepasses.Timer.UID.Text =
                "end in " .. string.format("%02d:%02d:%02d", hours, minutes, seconds)
        end

        canShow = false
        LinePack.Visible = false
    end)
end

local function setupPetItem(item, config)
    local PetInfo = Root.SharedModules.Pets[config.PetName]
    local WorldFolder = Root.GameServices.ReplicatedStorage.Pets:FindFirstChild(PetInfo.World)
    local PetModel = WorldFolder and WorldFolder:FindFirstChild(config.PetName)

    local Template = script.Pet:Clone()
    if PetModel then
        PetModel = PetModel:Clone()
        PetModel.Parent = Template.Frame.ViewportFrame
        PetModel.HumanoidRootPart.Anchored = true

        local Camera = Instance.new('Camera', Template.Frame.ViewportFrame)
        Camera.CameraSubject = PetModel
        Camera.CFrame = PetModel.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(-180), 0) * CFrame.new(0, 1, 3.6)

        Template.Frame.ViewportFrame.CurrentCamera = Camera
    end

    item.Icon.Image = config.imageId
end

local function setupItem(item, config, isCurrent)
    item.BuyButton.Visible = not config.free
    item.FreeButton.Visible = config.free

    item.BuyButton.Interactable = isCurrent
    item.FreeButton.Interactable = isCurrent

    if config.Price and not config.free then
        item.BuyButton.Price.Text = config.Price
    end

    if config.Name then
        item.Title.Text = config.Name
    end

    if config.Type == "Pet" then
        setupPetItem(item, config)
    else
        item.Icon.Image = config.imageId
    end

    if config.count and config.count > 0 then
        item.Count.Text = "x" .. config.count
    end
end

local function destroyItem(item)
    LinePackParent[tostring(item)]:Destroy()
    LinePackParent[tostring(item) .. "a"]:Destroy()
end

local function updateNextItemButtons(nextItem)
    local nextPass = LinePackParent[tostring(nextItem)]
    if nextPass then
        nextPass.BuyButton.Interactable = true
        nextPass.FreeButton.Interactable = true
    end
end

module.ShowShop = function()
    if CurrentLineItem >= MAX_LINE_ITEM then return end

    local timeDifference = calculateDateDifferenceInSeconds(Root.Data.OnPlayerJoinLinePack)
    startTimer(timeDifference)

    if not canShow then return end

    LinePack.Visible = true
end

module.HideLinePackItem = function(item)
    if Root.Data.LineItem > MAX_LINE_ITEM then
        LinePack.Gamepasses.Finish.Visible = true
        return
    end

    destroyItem(item)
    updateNextItemButtons(item + 1)

    if Root.Data.LineItem == MAX_LINE_ITEM then
        LinePack.Gamepasses.Finish.Visible = true
    end
end

for i = CurrentLineItem, MAX_LINE_ITEM do
    local item: Frame = ItemPackTemplate:Clone()
    item.Parent = LinePackParent
    item.LayoutOrder = i + 1
    item.Visible = true
    item.Name = tostring(i)

    local newArrow = LinePackArrow:Clone()
    newArrow.LayoutOrder = i + 2
    newArrow.Parent = LinePackParent
    newArrow.Visible = true
    newArrow.Name = tostring(i) .. "a"

    setupItem(item, LineConfig[i], CurrentLineItem == i)

    item.BuyButton.MouseButton1Click:Connect(function()
        Root.Bridge:Fire('Marketplace', 'Product', { Name = LineConfig[i].BuyId })
    end)

    item.FreeButton.MouseButton1Click:Connect(function()
        Root.Bridge:Fire('LinePackServer', 'GetItem', i)
    end)
end
