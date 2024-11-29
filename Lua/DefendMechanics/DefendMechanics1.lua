---ROOT---
local Root = require(script.Parent.Parent)

---[ OTHERS ]---
local UI = Root.LocalPlayer.PlayerGui.UI

local CenterFrame = UI.Frames
local HUDFrame = UI.HUD
local ProtectCrystalFrame = CenterFrame.ProtectCrystal

local UIActivated = false

---[ SCRIPT ]---
local module = {}

module.Update = function(ProtectCrystalTable, InProtectCrystal)
	if not ProtectCrystalTable then return end
	
	ProtectCrystalFrame.Start.Visible = if ProtectCrystalTable.Owner ~= nil then false else true
	ProtectCrystalFrame.Join.Visible = if ProtectCrystalTable.Owner ~= nil then true else false
	
	local CalculateTimeLeft = (if ProtectCrystalTable.Started then 1860 else 15) - (os.time() - ProtectCrystalTable.WaveTick)
	
	HUDFrame.ProtectCrystal.Room.Text = 'Wave ' .. ProtectCrystalTable.Wave
	HUDFrame.ProtectCrystal.Time.Title.Text = Root.Utils.Number:Time2(CalculateTimeLeft) or 0
	HUDFrame.ProtectCrystal.Container.Health.Text = ProtectCrystalTable.Health .. '/10'
	HUDFrame.ProtectCrystal.Container.Health.UID.Text = HUDFrame.ProtectCrystal.Container.Health.Text
	
	if UIActivated then
		if not InProtectCrystal then
			UIActivated = false
			
			HUDFrame.ProtectCrystal.Visible = false
		end
	elseif not UIActivated then
		if InProtectCrystal then
			UIActivated = true
			
			HUDFrame.ProtectCrystal.Visible = true
		end
	end
	
	Root.LocalPlayer:SetAttribute('InProtectCrystal', InProtectCrystal)
end

---[ BUTTONS ]---
ProtectCrystalFrame.Start.Buttons.Friends.MouseButton1Click:Connect(function()
	Root.Bridge:Fire('Enemies', 'Bridge', {
		Module = 'ProtectCrystal',
		FunctionName = 'Start',
		Args = 'Friend',
	})
end)

ProtectCrystalFrame.Start.Buttons.Public.MouseButton1Click:Connect(function()
	Root.Bridge:Fire('Enemies', 'Bridge', {
		Module = 'ProtectCrystal',
		FunctionName = 'Start',
		Args = 'Public',
	})
end)

ProtectCrystalFrame.Start.Buttons.Close.MouseButton1Click:Connect(function()
	local FrameTable = Root.Utils.Frame:Get(ProtectCrystalFrame)
	if not FrameTable then return end
	
	FrameTable:Close()
end)

ProtectCrystalFrame.Join.Buttons.Join.MouseButton1Click:Connect(function()
	Root.Bridge:Fire('Enemies', 'Bridge', {
		Module = 'ProtectCrystal',
		FunctionName = 'Join',
		Args = '',
	})
end)

ProtectCrystalFrame.Join.Buttons.Close.MouseButton1Click:Connect(function()
	local FrameTable = Root.Utils.Frame:Get(ProtectCrystalFrame)
	if not FrameTable then return end
	
	FrameTable:Close()
end)

return module