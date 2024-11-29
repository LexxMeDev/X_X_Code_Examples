local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local MainQuestConfig = require(game:GetService("ReplicatedStorage").Configs.MainQuestConfig)

local MainQuest = {}


local function getQuestService()
	return Knit.GetService("QuestService")
end

local function getQuestProgress(player: Player)
	return getQuestService():GetQuestProgress(player, "Quests.Progress.MainQuest")
end

local function setQuestProgress(player: Player, progress)
	return getQuestService():SetQuestProgress(player, "Quests.Progress.MainQuest", progress)
end

function MainQuest:IsCompleted(player)
	local progress = getQuestProgress(player)
	return progress.World1 >= MainQuestConfig.Objectives.ItemsToFind.World1 and
		progress.World2 >= MainQuestConfig.Objectives.ItemsToFind.World2 and
		progress.World3 >= MainQuestConfig.Objectives.ItemsToFind.World3
end

function MainQuest:IsActive(player)
	return true
end

function MainQuest:HasOptionalObjectives(player)
	return true
end

function MainQuest:AreOptionalObjectivesCompleted(player)
	local itemData = getQuestProgress(player)
	local totalItemsFound = itemData.World1 + itemData.World2 + itemData.World3
	return totalItemsFound >= MainQuestConfig.Objectives.ItemsToFind.Additional.TotalItems
end

function MainQuest:GetObjectivesStatus(player)
	local progress = getQuestProgress(player)
	return {
		World1 = progress.World1,
		World2 = progress.World2,
		World3 = progress.World3,
		CollectedItems = progress.CollectedItems
	}
end

function MainQuest:CollectItem(player, worldId, itemId)
	local QuestService = getQuestService()
	local progress = getQuestProgress(player)
	table.insert(progress.CollectedItems, itemId)
	if worldId == 1 then
		progress.World1 = progress.World1 + 1
	elseif worldId == 2 then
		progress.World2 = progress.World2 + 1
	elseif worldId == 3 then
		progress.World3 = progress.World3 + 1
	end	
	
	local totalItemsFound = progress.World1 + progress.World2 + progress.World3

	local badgeIndex = totalItemsFound
	local badge = MainQuestConfig.Rewards.Badges[badgeIndex]
	
	setQuestProgress(player, progress)
	QuestService:CallUpdatedQuestsDataEvent(player)
	
	if badge and not progress.BadgesGiven[badge.ID] then
		progress.BadgesGiven[badge.ID] = true
	end

	QuestService:CheckReadyQuestReward(player)
end

function MainQuest:RewardClaimed(player)
	local playerData = getQuestService():GetQuestsData(player)
	return playerData.RewardsClaimed and playerData.RewardsClaimed.MainQuest or false
end

function MainQuest:ClaimReward(player)	
	local QuestService = getQuestService()
	local progress = getQuestProgress(player)

	local gemsReward = MainQuestConfig.Rewards.Gems
	
	local totalItems = progress.World1 + progress.World2 + progress.World3
	
	if totalItems >= MainQuestConfig.Objectives.ItemsToFind.Additional.TotalItems then
		gemsReward = MainQuestConfig.Rewards.AdditionalGems
	end

	QuestService:AddGems(player, gemsReward):expect()
	QuestService:CallUpdatedQuestsDataEvent(player)
	QuestService:CallClaimedQuestReward(player, "MainQuest")
end

function MainQuest:CalculateReward(player)
	local progress = getQuestProgress(player)

	local gemsReward = MainQuestConfig.Rewards.Gems

	local totalItems = progress.World1 + progress.World2 + progress.World3

	if totalItems >= MainQuestConfig.Objectives.ItemsToFind.Additional.TotalItems then
		gemsReward = MainQuestConfig.Rewards.AdditionalGems
	end
	
	return gemsReward
end

return MainQuest
