---ROOT---
local Root = require(script.Parent.Parent.Parent.Parent)

---[ OTHERS ]---
local EnemiesFolder = Root.GameServices.Workspace:WaitForChild('Server'):WaitForChild('ProtectCrystal'):WaitForChild('Enemies')
local TweenService = game:GetService("TweenService")
local PetRender = require(script.Parent.Parent.Parent.PetRender)

---[ SCRIPT ]---
local module = {}

module.HealthUI = function(Bar : Frame, Label : TextLabel, Health : number, MaxHealth : number)
	local Percentage = math.clamp((Health / MaxHealth), 0, 1)

	local PercentageColor = Color3.new(0.329412, 0.85098, 0.247059)
	if Percentage < 0.5 and Percentage > 0.25 then
		PercentageColor = Color3.new(0.85098, 0.584314, 0.207843)
	elseif Percentage < 0.25 then
		PercentageColor = Color3.new(0.85098, 0.270588, 0.192157)
	end

	Bar.BackgroundColor3 = PercentageColor

	Label.Text = Root.Utils.Number:Format(Health) .. '/' .. Root.Utils.Number:Format(MaxHealth)

	Bar:TweenSize(UDim2.fromScale(Percentage, 1), Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 0.5, true)
end

module.ClearEnemies = function()
	for EnemyID, EnemyTable in next, Root.Cache.Enemies.ProtectCrystal do
		for _, Connection in next, EnemyTable.Connections do
			Connection:Disconnect()
		end

		if EnemyTable.Model then
			EnemyTable.Model:Destroy()
		end

		if EnemyTable.Cache.Wood then
			EnemyTable.Cache.Wood:Destroy()
		end
		
		Root.Cache.Enemies.ProtectCrystal[EnemyID] = nil
	end
end

module.CreateEnemy = function(Map : string, Enemy : BasePart)
	local EnemyInfo = Root.SharedModules.Enemies.World[Map] and Root.SharedModules.Enemies.World[Map][Enemy.Name]
	if not EnemyInfo then return end

	local EnemyID = Enemy:GetAttribute('ID')
	local EnemyTable = {
		['Name'] = Enemy.Name;
		['ID'] = EnemyID;
		['Info'] = EnemyInfo;
		['Object'] = Enemy;
		['Connections'] = {};
		['Animations'] = {};
		['Cache'] = {};
	}

	EnemyTable.Model = Root.GameServices.ReplicatedStorage.Enemies.World:FindFirstChild(Map) and Root.GameServices.ReplicatedStorage.Enemies.World[Map]:FindFirstChild(Enemy.Name)
	if not EnemyTable.Model then return end EnemyTable.Model = EnemyTable.Model:Clone()

	Root.Utils.Collisions:Set('Enemy', EnemyTable.Model)

	EnemyTable.Model.Name = EnemyID
	EnemyTable.Model.HumanoidRootPart.Anchored = false
	
	EnemyTable.Weld = Instance.new('Weld', EnemyTable.Model.HumanoidRootPart)
	EnemyTable.Weld.Part0 = Enemy
	EnemyTable.Weld.Part1 = EnemyTable.Model.HumanoidRootPart
	EnemyTable.Weld.C0 = if EnemyInfo.Height then CFrame.new(0, EnemyInfo.Height, 0) else CFrame.new(0, 2.5, 0)
	
	EnemyTable.Model.Parent = if Enemy:GetAttribute('Died') then Root.GameServices.ReplicatedStorage.Enemies_Cache.ProtectCrystal else Root.GameServices.Workspace.Client.Enemies.ProtectCrystal
	
	EnemyTable.HUD = script:WaitForChild('HUD'):Clone()
	
	EnemyTable.HUD.Frame.EnemyName.Text = EnemyInfo.Name
	EnemyTable.HUD.Frame.Difficult.Text = EnemyInfo.Type
	EnemyTable.HUD.Frame.Difficult.TextColor3 = Root.Utils.Colors:GetDifficultColor3(EnemyInfo.Type)
	
	EnemyTable.HUD.Size = if EnemyInfo.HUD then EnemyInfo.HUD else UDim2.new(5, 0, 1.5, 0)
	EnemyTable.HUD.StudsOffsetWorldSpace = if EnemyInfo.Studs then EnemyInfo.Studs else Vector3.new(0, 3.6, 0)
	EnemyTable.HUD.Enabled = true
	EnemyTable.HUD.Parent = EnemyTable.Model.HumanoidRootPart
	
	if EnemyInfo.Type == 'Boss' then
		EnemyTable.Model:ScaleTo(2)
		EnemyTable.Weld.C0 = CFrame.new(0, 5.5, 0)
		EnemyTable.HUD.Size = UDim2.new(10, 0, 3, 0)
		EnemyTable.HUD.StudsOffsetWorldSpace = Vector3.new(0, 6.5, 0)
	elseif EnemyInfo.Type == 'Insane' then
		EnemyTable.Model:ScaleTo(1.5)
		EnemyTable.Weld.C0 = CFrame.new(0, (2.5 * 1.5), 0)
	end
	
	EnemyTable.Animations.Idle = EnemyTable.Model.Humanoid.Animator:LoadAnimation(script.Animation.Idle)
	EnemyTable.Animations.Hit = EnemyTable.Model.Humanoid.Animator:LoadAnimation(script.Animation.Hit)
	EnemyTable.Animations.HitPets = EnemyTable.Model.Humanoid.Animator:LoadAnimation(script.Animation.HitPets)
	EnemyTable.Animations.Idle:Play()
	
	module.HealthUI(EnemyTable.HUD.Frame.Health.Bar, EnemyTable.HUD.Frame.Health.Amount, Enemy:GetAttribute('Health'), Enemy:GetAttribute('MaxHealth'))
	
	EnemyTable.Connections.Health = Enemy:GetAttributeChangedSignal('Health'):Connect(function()
		module.HealthUI(EnemyTable.HUD.Frame.Health.Bar, EnemyTable.HUD.Frame.Health.Amount, Enemy:GetAttribute('Health'), Enemy:GetAttribute('MaxHealth'))
		
		EnemyTable.HUD.Enabled = if Enemy:GetAttribute('Health') > 0 then true else false
	end)

	Enemy.AncestryChanged:Connect(function(_, Parent)
		if Parent == nil then
			for _, Connection in next, EnemyTable.Connections do
				Connection:Disconnect()
			end

			if EnemyTable.Model then				
				PetRender.StopAttackingEnemy(EnemyTable.Object)
				EnemyTable.Model:Destroy()
			end

			if EnemyTable.Cache.Wood then
				EnemyTable.Cache.Wood:Destroy()
			end

			Root.Cache.Enemies.ProtectCrystal[EnemyID] = nil
		end
	end)
	
	Root.Cache.Enemies.ProtectCrystal[EnemyID] = EnemyTable
end

EnemiesFolder.ChildAdded:Connect(function(Child)
	Child.Transparency = 1
	
	module.CreateEnemy(Child:GetAttribute('World'), Child)
end)

module.Hit = function(Enemy : BasePart, Amount : number, IsCritical, IsPlayer)

	if not Enemy then return end

	local EnemyTable = Root.Cache.Enemies.ProtectCrystal[Enemy:GetAttribute('ID')]
	if not EnemyTable or not EnemyTable.Animations.Hit then return end

	if math.random(1, 2) == 1 then
		if IsPlayer then
			if EnemyTable.Animations.Hit.IsPlaying == false then
				EnemyTable.Animations.Hit:Play()
			end
		else
			if EnemyTable.Animations.HitPets.IsPlaying == false then
				EnemyTable.Animations.HitPets:Play()
			end
		end
	else
		if IsPlayer then
			if EnemyTable.Animations.HitPets.IsPlaying == false then
				EnemyTable.Animations.HitPets:Play()
			end
		else
			if EnemyTable.Animations.Hit.IsPlaying == false then
				EnemyTable.Animations.Hit:Play()
			end
		end
	end

	if Amount then
		if not IsPlayer then
			if not Root.GameServices.Workspace.Debris:FindFirstChild("HitVFXClone") then
				local HitVFXClone = script.HitVFX:Clone()
				HitVFXClone.Parent = Root.GameServices.Workspace.Debris
				HitVFXClone.Name = "HitVFXClone"
				HitVFXClone.CFrame = CFrame.new(Enemy.Position + Vector3.new(0, 2.5, 0))

				task.spawn(function()
					wait(0.5)
					HitVFXClone:Destroy()
				end)
			end
		end

		local DamageTemplate = script.Damage:Clone()
		DamageTemplate.Parent = Root.GameServices.Workspace.Debris		

		DamageTemplate.CFrame = Enemy.CFrame * CFrame.new(0, Enemy.Size.Y / 2, 0)
		DamageTemplate.Frame.Amount.Text = '-' .. Root.Utils.Number:Format(Amount)

		local TweenTime = 0.6
		local SizeMultiplier = 1
		local TextColor = Color3.new(1, 1, 1)
		local dugaVector = Vector3.new(0, 15, 0)

		local startPos = DamageTemplate.CFrame.Position
		local endPos = startPos + Vector3.new(math.random(-5, 5), -5, math.random(-5, 5))

		if IsCritical then
			if IsPlayer then
				TextColor = Color3.new(0.686275, 0.184314, 1)
				SizeMultiplier = 8
				TweenTime = TweenTime * 1.2 * 1.2
				dugaVector = Vector3.new(0, 24, 0)
				DamageTemplate.Frame.Amount.ZIndex = 5
			else
				TextColor = Color3.new(0.329412, 0.909804, 1)
				TweenTime = TweenTime * 1.2 * 1.2
				SizeMultiplier = 4
				dugaVector = Vector3.new(0, 24, 0)
				DamageTemplate.Frame.Amount.ZIndex = 3
			end
		elseif IsPlayer then
			TextColor = Color3.new(1, 0, 0.0156863)
			SizeMultiplier = 5
		else
			TextColor = Color3.new(0.862745, 0.862745, 0.862745)
			SizeMultiplier = 1.1
			endPos = startPos + Vector3.new(math.random(-4, 4), -4, math.random(-4, 4))
			dugaVector = Vector3.new(0, 13, 0)
			DamageTemplate.Frame.Amount.UIStroke.Thickness = 1
		end

		DamageTemplate.Frame.Amount.TextColor3 = TextColor
		DamageTemplate.Frame.Size = UDim2.new(SizeMultiplier, 0, SizeMultiplier, 0)

		local uiStroke = DamageTemplate.Frame.Amount:FindFirstChildOfClass("UIStroke")

		local startSize = UDim2.new(0, 0, 0, 0)
		local endSize = DamageTemplate.Frame.Size
		local appearTime = TweenTime / 5
		local disappearTime = TweenTime / 4

		DamageTemplate.Frame.Size = startSize

		local appearTweenInfo = TweenInfo.new(appearTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local disappearTweenInfo = TweenInfo.new(disappearTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

		local appearTween = game:GetService("TweenService"):Create(DamageTemplate.Frame, appearTweenInfo, {Size = endSize})
		appearTween:Play()

		local midPos = (startPos + endPos) / 2 + dugaVector

		local bezierTweenInfo = TweenInfo.new(TweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

		local function BezierTween(startPos, midPos, endPos, time)
			local startTime = tick()
			local bezierCFrame = Instance.new("CFrameValue")
			bezierCFrame.Value = DamageTemplate.CFrame

			local tween = game:GetService("TweenService"):Create(bezierCFrame, bezierTweenInfo, {Value = CFrame.new(endPos)})
			tween:Play()

			local connection
			connection = game:GetService("RunService").RenderStepped:Connect(function()
				local elapsed = tick() - startTime
				local alpha = elapsed / time
				if alpha > 1 then alpha = 1 end
				local a = startPos:Lerp(midPos, alpha)
				local b = midPos:Lerp(endPos, alpha)
				DamageTemplate.CFrame = CFrame.new(a:Lerp(b, alpha))
				if alpha == 1 then
					connection:Disconnect()
				end
			end)

			tween.Completed:Connect(function()
				DamageTemplate:Destroy()
				bezierCFrame:Destroy()
			end)
		end

		BezierTween(startPos, midPos, endPos, TweenTime)

		task.delay(TweenTime - disappearTime, function()
			local frame = DamageTemplate:FindFirstChild("Frame")
			if frame then
				local amount = frame:FindFirstChild("Amount")
				if amount then
					local disappearTextTween = TweenService:Create(amount, disappearTweenInfo, {TextTransparency = 1})
					disappearTextTween:Play()

					if uiStroke then
						local disappearStrokeTween = TweenService:Create(uiStroke, disappearTweenInfo, {Transparency = 1, Thickness = 0})
						disappearStrokeTween:Play()
					end

					disappearTextTween.Completed:Wait()
					DamageTemplate:Destroy()
				else
					warn("Amount is not a valid member of Frame")
				end
			else
				warn("Frame is not a valid member of DamageTemplate")
			end
		end)
	end
end


module.Died = function(Enemy : BasePart)	
	if not Enemy then return end

	local EnemyTable = Root.Cache.Enemies.ProtectCrystal[Enemy:GetAttribute('ID')]
	if not EnemyTable or not EnemyTable.Model then return end
	
	EnemyTable.Model.Parent = Root.GameServices.ReplicatedStorage.Enemies_Cache.ProtectCrystal
	
	local Wood = script.Wood:Clone()
	Wood.Parent = workspace.Debris

	local Weld = Instance.new('Weld', Wood.PrimaryPart)
	Weld.Part0 = Wood.PrimaryPart
	Weld.Part1 = Enemy
	Weld.C0 = CFrame.new(0.800000012, 0, 0, -4.37113883e-08, -1, 0, 1, -4.37113883e-08, 0, 0, 0, 1)

	EnemyTable.Cache.Wood = Wood

	Root.Utils.Particles:Emit(Wood)
end

module.Respawn = function(Enemy : BasePart)
	if not Enemy then return end

	local EnemyTable = Root.Cache.Enemies.ProtectCrystal[Enemy:GetAttribute('ID')]
	if not EnemyTable or not EnemyTable.Model then return end
	
	warn("respawn")
	
	if EnemyTable.Cache.Wood then
		EnemyTable.Cache.Wood:Destroy()
		Root.Cache.Enemies.ProtectCrystal[Enemy:GetAttribute('ID')].Cache.Wood = nil
	end

	local Smoke = script.Smoke:Clone()
	Smoke.Parent = workspace.Debris

	Root.Utils.Particles:Emit(Smoke)
	
	EnemyTable.Model.Parent = Root.GameServices.Workspace.Client.Enemies.ProtectCrystal
end

return module