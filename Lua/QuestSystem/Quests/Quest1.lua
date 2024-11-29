local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Quest1Config = require(game:GetService("ReplicatedStorage").Configs.Quest1Config)
local Quest1 = {}

local function getQuestService()
	return Knit.GetService("QuestService")
end

local function getQuestProgress(player: Player)
	return getQuestService():GetQuestProgress(player, "Quests.Progress.Quest1")
end

local function setQuestProgress(player: Player, progress)
	return getQuestService():SetQuestProgress(player, "Quests.Progress.Quest1", progress)
end

function Quest1:IsCompleted(player)
	local progress = getQuestProgress(player)

	return progress.Stars >= Quest1Config.Objectives.Stars and
		progress.Eggs >= Quest1Config.Objectives.Eggs and
		progress.Jumps >= Quest1Config.Objectives.Jumps
end

function Quest1:IsActive(player)
	local playerQuests = getQuestService():GetQuestsData(player)
	return playerQuests.CurrentQuest == 1
end

function Quest1:HasOptionalObjectives(player)
	return true
end

function Quest1:AreOptionalObjectivesCompleted(player)
	local progress = getQuestProgress(player)
	return progress.Stars >= Quest1Config.Objectives.Additional.Stars
end

function Quest1:GetObjectivesStatus(player)
	local progress = getQuestProgress(player)

	return {
		Stars = progress.Stars,
		Eggs = progress.Eggs,
		Jumps = progress.Jumps,
		OptionalStars = progress.Stars
	}
end

function Quest1:RewardClaimed(player)
	local playerData = getQuestService():GetQuestsData(player)
	return playerData.RewardsClaimed and playerData.RewardsClaimed.Quest1 or false
end

function Quest1:ClaimReward(player)
	local QuestService = getQuestService()
	
	local progress = getQuestProgress(player)
	local gemsReward = Quest1Config.Rewards.Gems

	if progress.Stars >= Quest1Config.Objectives.Additional.Stars then
		gemsReward = Quest1Config.Rewards.AdditionalGems
	end
		
	QuestService:AddGems(player, gemsReward):expect()
	QuestService:CallUpdatedQuestsDataEvent(player)
	QuestService:CallClaimedQuestReward(player, "Quest1")
end

function Quest1:CalculateReward(player)
	local progress = getQuestProgress(player)
	local gemsReward = Quest1Config.Rewards.Gems

	if progress.Stars >= Quest1Config.Objectives.Additional.Stars then
		gemsReward = Quest1Config.Rewards.AdditionalGems
	end
	
	return gemsReward
end

function Quest1:CollectItem(player, itemType, count)
	local QuestService = getQuestService()

	count = count or 1
	
	local progress = getQuestProgress(player)

	if itemType == "Stars" then
		progress.Stars = progress.Stars + count
	elseif itemType == "Eggs" then
		progress.Eggs = progress.Eggs + 1
	elseif itemType == "Jumps" then
		progress.Jumps = progress.Jumps + 1
	end
	
	setQuestProgress(player, progress):expect()
	QuestService:CallUpdatedQuestsDataEvent(player)
	QuestService:CheckReadyQuestReward(player)
end

return Quest1
