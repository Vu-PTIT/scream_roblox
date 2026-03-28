--!strict
-- SimplePath.luau
-- A simple pathfinding wrapper for Roblox.
-- Original by V33R-S, adapted for Luau.

local PathfindingService = game:GetService("PathfindingService")

local SimplePath = {}
SimplePath.__index = SimplePath

export type SimplePathInstance = {
	Model: Model,
	Humanoid: Humanoid,
	RootPart: BasePart,
	Path: Path,
	Status: string,
	Target: Vector3?,
	VisualWaypoints: { Part },
	_Waypoints: { PathWaypoint },
	_CurrentIndex: number,
	_Moving: boolean,
	_Disposed: boolean,
	_MovingLoop: thread?,
	
	-- Events
	Reached: BindableEvent,
	WaypointReached: BindableEvent,
	Blocked: BindableEvent,
	Error: BindableEvent,
	
	Run: (self: SimplePathInstance, target: Vector3) -> boolean,
	Stop: (self: SimplePathInstance) -> (),
	Destroy: (self: SimplePathInstance) -> (),
	_Update: (self: SimplePathInstance) -> (),
}

function SimplePath.new(model: Model, agentParams: { [string]: any }?)
	local self = setmetatable({}, SimplePath) :: any
	
	self.Model = model
	self.Humanoid = model:FindFirstChildOfClass("Humanoid")
	self.RootPart = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
	
	if not self.RootPart then
		error("SimplePath: Model must have a PrimaryPart or HumanoidRootPart")
	end
	
	self.Path = PathfindingService:CreatePath(agentParams or {
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
	})
	
	self.Status = "Idle"
	self.Target = nil
	self.VisualWaypoints = {}
	self._Waypoints = {}
	self._CurrentIndex = 0
	self._Moving = false
	self._Disposed = false
	self._MovingLoop = nil
	
	-- Events
	self.Reached = Instance.new("BindableEvent")
	self.WaypointReached = Instance.new("BindableEvent")
	self.Blocked = Instance.new("BindableEvent")
	self.Error = Instance.new("BindableEvent")
	
	-- Cleanup on destroy
	model.AncestryChanged:Connect(function(_, parent)
		if not parent then
			self:Destroy()
		end
	end)
	
	-- Handle blockages
	self.Path.Blocked:Connect(function(blockedIndex)
		if blockedIndex >= self._CurrentIndex then
			self.Blocked:Fire()
			if self._Moving and self.Target then
				self:Run(self.Target) -- Recalculate
			end
		end
	end)
	
	return self
end

function SimplePath.Run(self: SimplePathInstance, target: Vector3)
	if self._Disposed then return false end
	
	-- Optimization: Don't recompute if target is nearly the same and we are already moving
	if self.Target and (target - self.Target).Magnitude < 5 and self._Moving then
		return true
	end
	
	self.Target = target
	
	local success, _ = pcall(function()
		self.Path:ComputeAsync(self.RootPart.Position, target)
	end)
	
	if success and self.Path.Status == Enum.PathStatus.Success then
		local wps = self.Path:GetWaypoints()
		if #wps > 0 then
			self._Waypoints = wps
			self._CurrentIndex = 1
			self._Moving = true
			self.Status = "Moving"
			
			-- Trigger first MoveTo (ignore the first one if it's too close/behind)
			local firstWp = self._Waypoints[1]
			if firstWp and (self.RootPart.Position - firstWp.Position).Magnitude < 3 then
				self._CurrentIndex = 2
			end
			
			local currentWp = self._Waypoints[self._CurrentIndex]
			if currentWp and self.Humanoid then
				self.Humanoid:MoveTo(currentWp.Position)
			end

			-- Start a heartbeat loop for continuous movement if not already running
			if not self._MovingLoop then
				local loopThread = task.spawn(function()
					while self._Moving and not self._Disposed do
						self._Update(self)
						task.wait()
					end
					self._MovingLoop = nil
				end)
				self._MovingLoop = loopThread :: any
			end
			return true
		end
	end
	
	self.Status = "Error"
	self.Error:Fire("ComputationFailed")
	return false
end

function SimplePath.Stop(self: SimplePathInstance)
	self._Moving = false
	self.Status = "Idle"
	if self.Humanoid then
		self.Humanoid:Move(Vector3.new(0, 0, 0))
	end
end

function SimplePath._Update(self: SimplePathInstance)
	if not self._Moving or self._Disposed or #self._Waypoints == 0 then return end
	
	if self._CurrentIndex > #self._Waypoints then
		self._Moving = false
		self.Status = "Idle"
		self.Reached:Fire()
		return
	end
	
	local waypoint = self._Waypoints[self._CurrentIndex]
	local dist = (self.RootPart.Position - waypoint.Position).Magnitude
	
	-- If close enough to waypoint, move to next
	if dist < 2.5 then
		self._CurrentIndex += 1
		self.WaypointReached:Fire(self._CurrentIndex - 1)
		
		-- Immediately call MoveTo for the next waypoint if it exists
		if self._CurrentIndex <= #self._Waypoints then
			local nextWp = self._Waypoints[self._CurrentIndex]
			if self.Humanoid then
				self.Humanoid:MoveTo(nextWp.Position)
				if nextWp.Action == Enum.PathWaypointAction.Jump then
					self.Humanoid.Jump = true
				end
			end
		end
		return
	end
	
	-- Only call MoveTo if waypoints just changed or every ~0.2s for reliability
	-- MoveTo is already called when CurrentIndex changes above.
	
	if not self.Humanoid then
		-- Teleport or use CFrame for Non-Humanoid
		self.RootPart.CFrame = self.RootPart.CFrame:Lerp(CFrame.new(waypoint.Position), 0.1)
	end
end

function SimplePath.Destroy(self: SimplePathInstance)
	self:Stop()
	self._Disposed = true
	self.Reached:Destroy()
	self.WaypointReached:Destroy()
	self.Blocked:Destroy()
	self.Error:Destroy()
	for _, v in ipairs(self.VisualWaypoints) do
		v:Destroy()
	end
end

return SimplePath
