local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local LAUNCHERS_CONSTANTS = require(game:GetService("ReplicatedStorage").Util.Balance.Launchers)

local Quest2Config = require(game:GetService("ReplicatedStorage").Configs.Quest2Config)
local Quest2 = {}

local function getQuestService()
	return Knit.GetService("QuestService")
end

local function getQuestProgress(player: Player)
	return getQuestService():GetQuestProgress(player, "Quests.Progress.Quest2")
end

local function setQuestProgress(player: Player, progress)
	return getQuestService():SetQuestProgress(player, "Quests.Progress.Quest2", progress)
end

function Quest2:IsCompleted(player)
	local progress = getQuestProgress(player)

	return progress.LauncherLevel >= Quest2Config.Objectives.LauncherLevel and
		progress.ReachedMoon == Quest2Config.Objectives.ReachedMoon
end

function Quest2:IsActive(player)
	local playerQuests = getQuestService():GetQuestsData(player)
	return playerQuests.CurrentQuest == 2
end

function Quest2:HasOptionalObjectives(player)
	return true
end

function Quest2:AreOptionalObjectivesCompleted(player)
	local progress = getQuestProgress(player)
	return progress.LauncherLevel >= Quest2Config.Objectives.Additional.LauncherLevel
end

function Quest2:GetObjectivesStatus(player)
	local progress = getQuestProgress(player)
	
	local DataService = Knit.GetService("DataService")
	local launcherType: string = DataService:GetKey(player, "currentLauncherType"):expect()
	local launcherLevel: string =DataService:GetKey(player, "currentLauncherLevel"):expect()
	progress.LauncherLevel = LAUNCHERS_CONSTANTS[launcherType][launcherLevel].TotalLevel
	
	return {
		LauncherLevel = progress.LauncherLevel,
		ReachedMoon = progress.ReachedMoon,
		OptionalLauncherLevel = progress.LauncherLevel
	}
end

function Quest2:RewardClaimed(player)
	local playerData = getQuestService():GetQuestsData(player)
	return playerData.RewardsClaimed and playerData.RewardsClaimed.Quest2 or false
end

function Quest2:ClaimReward(player)
	local QuestService = getQuestService()

	local progress = getQuestProgress(player)
	local gemsReward = Quest2Config.Rewards.Gems
	
	local DataService = Knit.GetService("DataService")
	local launcherType: string = DataService:GetKey(player, "currentLauncherType"):expect()
	local launcherLevel: string = DataService:GetKey(player, "currentLauncherLevel"):expect()
	local actualLauncherLevel = LAUNCHERS_CONSTANTS[launcherType][launcherLevel].TotalLevel
	
	if actualLauncherLevel >= Quest2Config.Objectives.Additional.LauncherLevel then
		gemsReward = Quest2Config.Rewards.AdditionalGems
	end
	
	QuestService:AddGems(player, gemsReward):expect()
	QuestService:CallUpdatedQuestsDataEvent(player)
	QuestService:CallClaimedQuestReward(player, "Quest2")
end

function Quest2:CalculateReward(player)
	local progress = getQuestProgress(player)
	local gemsReward = Quest2Config.Rewards.Gems
	
	local DataService = Knit.GetService("DataService")
	local launcherType: string = DataService:GetKey(player, "currentLauncherType"):expect()
	local launcherLevel: string = DataService:GetKey(player, "currentLauncherLevel"):expect()
	local actualLauncherLevel = LAUNCHERS_CONSTANTS[launcherType][launcherLevel].TotalLevel

	if actualLauncherLevel >= Quest2Config.Objectives.Additional.LauncherLevel then
		gemsReward = Quest2Config.Rewards.AdditionalGems
	end
	return gemsReward	
end

function Quest2:SetLauncherLevel(player, level)
	local progress = getQuestProgress(player)
	
	local DataService = Knit.GetService("DataService")

	local launcherType: string = DataService:GetKey(player, "currentLauncherType"):expect()
	local launcherLevel: string =DataService:GetKey(player, "currentLauncherLevel"):expect()
	progress.LauncherLevel = LAUNCHERS_CONSTANTS[launcherType][launcherLevel].TotalLevel

	setQuestProgress(player, progress):expect()
	getQuestService():CallUpdatedQuestsDataEvent(player)
end

function Quest2:CollectItem(player, itemType)
	local QuestService = getQuestService()
	local progress = getQuestProgress(player)

	if itemType == "LauncherLevel" then
		progress.LauncherLevel = progress.LauncherLevel + 1
	elseif itemType == "ReachedMoon" then
		progress.ReachedMoon = true
	end

	setQuestProgress(player, progress):expect()
	QuestService:CallUpdatedQuestsDataEvent(player)
	QuestService:CheckReadyQuestReward(player)
end

return Quest2
