local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local ShopUpgrade = require(script.Parent.components.ShopUpgrade)
local PetInventory = require(script.Parent.components.PetInventory)
local SkillInventory = require(script.Parent.components.SkillInventory)
local QuestMenu = require(script.Parent.components.QuestMenu)
local RebirthMenu = require(script.Parent.components.RebirthMenu)

local ShopApp = {}
local _setOpenWindow: any = nil

local function ShopAppComponent(props: any)
	local openWindow, setOpenWindow = React.useState(nil)
	local data, setData = React.useState({})

	-- Handle global state access
	React.useEffect(function()
		_setOpenWindow = setOpenWindow
		return function()
			_setOpenWindow = nil
		end
	end, {})

	-- Data syncing
	React.useEffect(function()
		local connection
		local function check()
			task.spawn(function()
				local DataController = require(script.Parent.Parent.Controllers.DataController)
				if DataController and DataController.OnDataChanged then
					setData(DataController.GetData() or {})
					connection = DataController.OnDataChanged(function(key, val)
						setData(function(prev)
							if key == "__all__" then return val end
							local d = table.clone(prev)
							d[key] = val
							return d
						end)
					end)
				end
			end)
		end
		check()
		return function()
			if connection then connection:Disconnect() end
		end
	end, {})

	local function close()
		setOpenWindow(nil)
	end

	return React.createElement("ScreenGui", {
		Name = "ShopApp",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 100,
	}, {
		Upgrade = React.createElement(ShopUpgrade, {
			Visible = (openWindow == "Shop"),
			OnClose = close,
			Data = data,
		}),
		Pet = React.createElement(PetInventory, {
			Visible = (openWindow == "Pet"),
			OnClose = close,
			Data = data,
		}),
		Skill = React.createElement(SkillInventory, {
			Visible = (openWindow == "Skill"),
			OnClose = close,
			Data = data,
		}),
		Quest = React.createElement(QuestMenu, {
			Visible = (openWindow == "Quest"),
			OnClose = close,
			Data = data,
		}),
		Rebirth = React.createElement(RebirthMenu, {
			Visible = (openWindow == "Rebirth"),
			OnClose = close,
			Data = data,
		}),
	})
end

ShopApp.Component = ShopAppComponent

function ShopApp.OpenWindow(windowName: any)
	if _setOpenWindow then
		_setOpenWindow(windowName)
	end
end

return ShopApp
