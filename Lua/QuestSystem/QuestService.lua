local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local PETS_CONFIGS = require(ReplicatedStorage.Util.Balance.Pets)

local RemoteFunctions = Instance.new("Folder", ReplicatedStorage)
RemoteFunctions.Name = "RemoteFunctions"

local QuestService = Knit.CreateService { 
	Name = "QuestService", 
	Client = {
		UpdatedQuestsData = Knit.CreateSignal(),
		MainQuestItemCollected = Knit.CreateSignal(),
		CollectedPet = Knit.CreateSignal(),
		ReadyQuestReward = Knit.CreateSignal(),
		ClaimedQuestReward = Knit.CreateSignal(),
	},
	
	QUESTS = {
		MainQuest = require(ReplicatedStorage.Configs.MainQuestConfig),
		Quest1 = require(ReplicatedStorage.Configs.Quest1Config),
		Quest2 = require(ReplicatedStorage.Configs.Quest2Config),
		Quest3 = require(ReplicatedStorage.Configs.Quest3Config),
	},

	QuestModules = {
		MainQuest = require(script.MainQuest),
		Quest1 = require(script.Quest1),
		Quest2 = require(script.Quest2),
		Quest3 = require(script.Quest3),
	}
}

local DataService
local QuestHelperService

function QuestService:KnitInit()
	DataService = Knit.GetService("DataService")
	QuestHelperService = Knit.GetService("QuestHelperService")

	self.Client.MainQuestItemCollected:Connect(function(player: Player, worldId: number, itemId: number)
		self.QuestModules.MainQuest:CollectItem(player, worldId, itemId)
	end)

	self.Client.CollectedPet:Connect(function(player: Player, collectedPets: {string}?)
		if not collectedPets then
			return
		end

		for _, pet in ipairs(collectedPets) do
			local petConfig = PETS_CONFIGS[pet]
    		if petConfig and petConfig.IsSummerPet then
				self.QuestModules.Quest3:CollectItem(player, "EventPet")
    		end
		end
	end)
end

function QuestService:KnitStart()
	for _, player in pairs(Players:GetPlayers()) do
		self:InitializePlayer(player)
	end

	Players.PlayerAdded:Connect(function(player)
		self:InitializePlayer(player)
	end)
end

function QuestService:GetQuestsData(player: Player)
	local playerQuests = DataService:GetKey(player, "Quests"):expect()
	if not playerQuests then
		playerQuests = { CurrentQuest = 1, Progress = {}, RewardsClaimed = {} }
		self:SetQuestsData(player, playerQuests)
	end
	return playerQuests 
end

function QuestService.Client:GetQuestsData(player: Player)
	return self.Server:GetQuestsData(player)
end

function QuestService:SetQuestsData(player, data)
	--if not data then return end
	return DataService:SetKey(player, "Quests", data)
end

function QuestService:GetQuestProgress(player: Player, questName: string)
	local DataService = Knit.GetService("DataService")
	local progress = DataService:GetKey(player, questName):expect()
	
	if not progress then
		if questName == "Quests.Progress.MainQuest" then
			progress = { World1 = 0, World2 = 0, World3 = 0, CollectedItems = {}, BadgesGiven = {} }
		elseif questName == "Quests.Progress.Quest1" then
			progress = { Stars = 0, Eggs = 0, Jumps = 0 }
		elseif questName == "Quests.Progress.Quest2" then
			progress = { LauncherLevel = 0, ReachedMoon = false }
		elseif questName == "Quests.Progress.Quest3" then
			progress = { EventPets = 0, ReachedIceWorld = false, Rebirth = false }
		end
	end

	return progress
end

function QuestService:SetQuestProgress(player: Player, questName: string, progress)
	local DataService = Knit.GetService("DataService")
	return DataService:SetKey(player, questName, progress)
end

function QuestService:InitializePlayer(player)
	local playerQuests = self:GetQuestsData(player)
	
	for questName, _ in pairs(self.QUESTS) do
		local progress = self:GetQuestProgress(player, "Quests.Progress." .. questName)
		
		if questName == "MainQuest" then
			local collectedItems = progress.World1 + progress.World2 + progress.World3
			
			for badgeIndex = 1, collectedItems do
				local badge = self.QuestModules.QUESTS[questName].Rewards.Badges[badgeIndex]
				self:AwardBadge(player, badge.ID)
			end
			continue
		end
		
		if playerQuests.RewardsClaimed[questName] then
			local badge = self.QuestModules.QUESTS[questName].Rewards.Badge.ID
			self:AwardBadge(player, badge.ID)
		end
	end
end

function QuestService.Client:GetQuestStatus(player: Player, questName)		
	return self.Server:GetQuestStatus(player, questName)
end

function QuestService:ClaimReward(player, questName)	
	local playerQuests = self:GetQuestsData(player)
	local questModule = self.QuestModules[questName]
	
	playerQuests.RewardsClaimed[questName] = true
	questModule:ClaimReward(player)

	if questName == "Quest1" then
		playerQuests.CurrentQuest = 2
	elseif questName == "Quest2" then
		playerQuests.CurrentQuest = 3
	end

	self:SetQuestsData(player, playerQuests)
end

function QuestService.Client:ClaimMainQuestReward(player)
	return self.Server:ClaimReward(player, "MainQuest")
end

function QuestService.Client:ClaimQuest1Reward(player)
	return self.Server:ClaimReward(player, "Quest1")
end

function QuestService.Client:ClaimQuest2Reward(player)
	return self.Server:ClaimReward(player, "Quest2")
end

function QuestService.Client:ClaimQuest3Reward(player)
	return self.Server:ClaimReward(player, "Quest3")
end


function QuestService:CalculateReward(player, questName)
	local questModule = self.QuestModules[questName]
	return questModule:CalculateReward(player)
end

function QuestService.Client:CalculateMainQuestReward(player)
	return self.Server:CalculateReward(player, "MainQuest")
end

function QuestService.Client:CalculateQuest1Reward(player)
	return self.Server:CalculateReward(player, "Quest1")
end

function QuestService.Client:CalculateQuest2Reward(player)
	return self.Server:CalculateReward(player, "Quest2")
end

function QuestService.Client:CalculateQuest3Reward(player)
	return self.Server:CalculateReward(player, "Quest3")
end

function QuestService:GetQuestStatus(player, questName)
	local questModule = self.QuestModules[questName]
	return {
		IsActive = questModule:IsActive(player),
		IsCompleted = questModule:IsCompleted(player),
		ObjectivesStatus = questModule:GetObjectivesStatus(player),
		RewardClaimed = questModule:RewardClaimed(player)
	}
end

function QuestService:CheckReadyQuestReward(player: Player)
	local isReady = QuestHelperService:CheckCompletedQuests(player)
	if isReady == false then return end
	self.Client.ReadyQuestReward:Fire(player)
end

function QuestService:CallClaimedQuestReward(player: Player, questId: string)
	self.Client.ClaimedQuestReward:Fire(player, questId)
end

function QuestService:CallUpdatedQuestsDataEvent(player: Player)
	self.Client.UpdatedQuestsData:Fire(player)
end

function QuestService:GetKey(player, key)
	return DataService:GetKey(player, key):expect()
end

function QuestService:SetKey(player, key, value)
	return DataService:SetKey(player, key, value)
end


function QuestService:AwardBadge(player: Player, badgeId)
	local success, badgeInfo = pcall(function()
		return BadgeService:GetBadgeInfoAsync(badgeId)
	end)

	if success then
		if badgeInfo.IsEnabled then
			local successCheckHasBadge, hasBadge = pcall(function()
				return BadgeService:UserHasBadgeAsync(player.UserId, badgeId)
			end)

			if successCheckHasBadge == false or hasBadge then
				print('User have this badge: ' .. tostring(badgeId))
				return
			end

			-- Award badge
			local awardSuccess, result = pcall(function()
				return BadgeService:AwardBadge(player.UserId, badgeId)
			end)

			if not awardSuccess then
				warn("Error while awarding badge:", result)
			elseif not result then
				warn("Failed to award badge.")
			end
		end
	else
		warn("Error while fetching badge info: " .. badgeInfo)
	end
end

function QuestService:AddGems(player: Player, addGems)
	local balance = DataService:GetKey(player, "gems"):expect()
	return DataService:SetKey(player, "gems", (balance or 0) + addGems)
end

return QuestService
