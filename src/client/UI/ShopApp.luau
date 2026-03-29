--!strict
-- ShopApp.luau
-- Quản lý tất cả cửa sổ shop (Upgrade, Pet, Skill, Quest, Rebirth)
-- Cấu trúc: Nhận trạng thái từ UIController (Centralized State)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local ShopUpgrade = require(script.Parent.components.ShopUpgrade)
local PetInventory = require(script.Parent.components.PetInventory)
local SkillInventory = require(script.Parent.components.SkillInventory)
local QuestMenu = require(script.Parent.components.QuestMenu)

local ShopApp = {}

type ShopAppProps = {
	OpenWindow: string?,
	OnClose: () -> (),
	Data: any,
}

local function ShopAppComponent(props: ShopAppProps)
	local openWindow = props.OpenWindow
	local data = props.Data or {}

	-- Conditional rendering để ngăn lỗi ở một shop làm hỏng các shop khác
	local currentWindow = nil
	if openWindow == "Shop" then
		currentWindow = React.createElement(ShopUpgrade, {
			Visible = true,
			OnClose = props.OnClose,
			Data = data,
		})
	elseif openWindow == "Pet" then
		currentWindow = React.createElement(PetInventory, {
			Visible = true,
			OnClose = props.OnClose,
			Data = data,
		})
	elseif openWindow == "Skill" then
		currentWindow = React.createElement(SkillInventory, {
			Visible = true,
			OnClose = props.OnClose,
			Data = data,
		})
	elseif openWindow == "Quest" then
		currentWindow = React.createElement(QuestMenu, {
			Visible = true,
			OnClose = props.OnClose,
			Data = data,
		})

	end

	return React.createElement("ScreenGui", {
		Name = "ShopApp",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 150,
		Enabled = (openWindow ~= nil)
	}, {
		-- Chỉ render window thực sự cần thiết
		Content = currentWindow
	})
end

ShopApp.Component = ShopAppComponent


return ShopApp
