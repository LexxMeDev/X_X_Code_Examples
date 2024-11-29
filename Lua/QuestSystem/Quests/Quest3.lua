local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Quest3Config = require(game:GetService("ReplicatedStorage").Configs.Quest3Config)
local Quest3 = {}

local function getQuestService()
	return Knit.GetService("QuestService")
end

local function getQuestProgress(player: Player, questSaveId)
	questSaveId = questSaveId or "Quests.Progress.Quest3"
	return getQuestService():GetQuestProgress(player, questSaveId)
end

local function setQuestProgress(player: Player, progress)
	return getQuestService():SetQuestProgress(player, "Quests.Progress.Quest3", progress)
end

function Quest3:IsCompleted(player)
	local progress = getQuestProgress(player)
		
	return progress.EventPets >= Quest3Config.Objectives.EventPets and
		progress.ReachedIceWorld == Quest3Config.Objectives.ReachedIceWorld and
		progress.Rebirth == Quest3Config.Objectives.Additional.Rebirth
end

function Quest3:IsActive(player)
	local questData = getQuestService():GetQuestsData(player)
	return questData.CurrentQuest == 3
end

function Quest3:HasOptionalObjectives(player)
	return true
end

function Quest3:AreOptionalObjectivesCompleted(player)
	local progress = getQuestProgress(player)
	return progress.Rebirth == true
end

function Quest3:GetObjectivesStatus(player)
	local progress = getQuestProgress(player)

	return {
		EventPets = progress.EventPets,
		ReachedIceWorld = progress.ReachedIceWorld,
		Rebirth = progress.Rebirth,
		OptionalRebirth = progress.Rebirth,
	}
end

function Quest3:RewardClaimed(player)
	local playerData = getQuestService():GetQuestsData(player)
	return playerData.RewardsClaimed and playerData.RewardsClaimed.Quest3 or false
end

function Quest3:ClaimReward(player)	
	local QuestService = getQuestService()
	
	local gemsReward = Quest3Config.Rewards.Gems
	
	local QuestHelperService = Knit.GetService("QuestHelperService")
	local doRibirth = QuestHelperService:CheckQuest3Do1AdditionalRebirth(player)
	
	if doRibirth then
		gemsReward = Quest3Config.Rewards.AdditionalGems
	end
	
	QuestService:AddGems(player, gemsReward):expect()
	QuestService:CallUpdatedQuestsDataEvent(player)
	QuestService:CallClaimedQuestReward(player, "Quest3")
end

function Quest3:CalculateReward(player)	
	local gemsReward = Quest3Config.Rewards.Gems

	local QuestHelperService = Knit.GetService("QuestHelperService")
	local doRibirth = QuestHelperService:CheckQuest3Do1AdditionalRebirth(player)

	if doRibirth then
		gemsReward = Quest3Config.Rewards.AdditionalGems
	end
	
	return gemsReward
end

function Quest3:CollectItem(player, itemType)
	if not self:IsActive(player) then
		return
	end

	local QuestService = getQuestService()

	local progress = getQuestProgress(player)
	if itemType == "EventPet" then
		progress.EventPets = progress.EventPets + 1
	elseif itemType == "ReachedIceWorld" then
		progress.ReachedIceWorld = true
	elseif itemType == "Rebirth" then
		progress.Rebirth = true
	end
	
	setQuestProgress(player, progress)
	QuestService:CallUpdatedQuestsDataEvent(player)
	QuestService:CheckReadyQuestReward(player)
end


return Quest3
