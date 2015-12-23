AStar = class("AStar")

function AStar:ctor()
	self:createScene()
end

function AStar:createScene()
	local sceneLayer = self:getParentCom():getSceneLayer()
	self:createShow()
end

function AStar:createShow()
	self.ConstX = 21
	self.ConstY = 14
	local sceneLayer = self:getParentCom():getSceneLayer()
	local data = {}
	for y = 1, self.ConstY do
		for x = 1, self.ConstX do
			
			local sp = nil
			if x == 10 and y >= 0 and y <= 4 then
				-- 创建障碍物
				sp = UICard:create(2)
			else
				sp = UICard:create()
			end
			sp:setPosition(cc.p((x-1)*50+25, (y-1)*50+25))
			sceneLayer:addChild(sp)
			data[(y-1)*self.ConstX + x] = {
				view 	= sp,
				x		= x,
				y		= y,
				g		= 0,
				f		= 0
			}
		end
	end
	self.STEP = 10
	self.OBLIQUE = 14
	self.MazeArray = data
	self.OpenList 	= {}
	self.CloseList 	= {}
	local point = self:FindPath(cc.p(1, 1), cc.p(15, 5))
	
	while point do
		self.MazeArray[(point.y-1)*self.ConstX + point.x].view:setSel()
		point = point.ParentPoint
	end
end

function AStar:FindPath(posSrc, posDet)
	posSrc.G = 0
	posSrc.H = self:CalcH(posDet, posSrc)
	posSrc.F = posSrc.G + posSrc.H
	table.insert(self.OpenList, posSrc)
	while #self.OpenList ~= 0 do
		local tempStart = self:MinPoint()
		table.remove(self.OpenList, 1)
		table.insert(self.CloseList, tempStart)
		--找出它相邻的点
		local surroundPoints = self:SurrroundPoints(tempStart);
		for _, point in pairs(surroundPoints) do
			local opPoint = nil
			for _, pos in pairs(self.OpenList) do
				if pos.x == point.x and pos.y == point.y then
					opPoint = pos
				end
			end
			if opPoint then
				--计算G值, 如果比原来的大, 就什么都不做, 否则设置它的父节点为当前点,并更新G和F
				self:FoundPoint(tempStart, opPoint);
			else
				--如果它们不在开始列表里, 就加入, 并设置父节点,并计算GHF
				self:NotFoundPoint(tempStart, posDet, point);
			end
		end
		for _, point in pairs(self.OpenList) do
			if point.x == posDet.x and point.y == posDet.y then
				return point
			end
		end
	end
end

--获取某个点周围可以到达的点
function AStar:SurrroundPoints(point)
	local surroundPoints = {};
	for x = point.x-1, point.x+1 do
		for y = point.y-1, point.y+1 do
			-- print("11	", x, y)
			if x > 0 and y > 0 and x <= self.ConstX and y <=self.ConstY and self:CanReach(point,x, y) then
				local pos = cc.p(x, y)
				pos.ParentPoint = point
				table.insert(surroundPoints, pos)
			end
		end
	end
	return surroundPoints;
end

function AStar:FoundPoint(tempStart, point)
	local G = self:CalcG(tempStart, point);
	if G < point.G then
		point.ParentPoint = tempStart;
		point.G = G;
		point.F = point.G + point.H;
	end
end

function AStar:NotFoundPoint(tempStart, posDet, point)
	point.ParentPoint = tempStart;
	point.G = self:CalcG(tempStart, point);
	point.H = self:CalcH(posDet, point);
	point.F = point.G + point.H;
	table.insert(self.OpenList, point)
end

--在二维数组对应的位置不为障碍物
function AStar:CanReachTo(x, y)
	return 2 ~= self.MazeArray[(y-1)*self.ConstX + x].view:getType();
end

function AStar:CanReach(start, x, y)
	local bCloseListHave = false
	for _, point in pairs(self.CloseList) do
		if point.x == x and point.y == y then
			bCloseListHave = true
		end
	end
	if not self:CanReachTo(x, y) or bCloseListHave then
		return false;
	else
		if math.abs(x - start.x) + math.abs(y - start.y) == 1 then
			return true;
		--如果是斜方向移动, 判断是否 "拌脚"
		else
			if (x - 1) > 0 and (x - 1) <= self.ConstX and (y - 1) > 0 and (y - 1) <= self.ConstY and self:CanReachTo(math.abs(x - 1), y) and self:CanReachTo(x, math.abs(y - 1)) then
				return true;
			else
				return false;
			end
		end
	end
end

-- 查看某个节点是否存在openlist
function AStar:ExistsInOpenList(point)
	for _, pos in pairs(self.OpenList) do
		if pos.x == point.x and pos.y == point.y then
			return true
		end
	end
	return false
end

function AStar:CalcG(start, point)
	local G = 10
	if math.abs(point.x - start.x) + math.abs(point.y - start.y) == 2 then
		G = 14
	end
	local parentG = 0
	if point.ParentPoint then
		parentG = point.ParentPoint.G
	end
	return G + parentG;
end

function AStar:CalcH(posDet, point)
	return math.sqrt((math.abs(point.x - posDet.x) + math.abs(point.y - posDet.y)))*10
end

function AStar:getBestNode(tbOpened)
	tbOpened:sort(function(x, y) return x.f > y.f end)
	return tbOpened[1]
end

function AStar:MinPoint()
	table.sort(self.OpenList, function(x, y) return x.F < y.F end)
	return self.OpenList[1]
end