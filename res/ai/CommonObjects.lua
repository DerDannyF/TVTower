-- File: CommonObjects
-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
-- Movie ist jetzt nur noch ein Wrapper

function CheckMovieBuyConditions(licence, maxPrice, minQuality)
	if (licence.GetPrice() > maxPrice) then return false end
	if (minQuality ~= nil) then
		if (licence.GetQuality() < minQuality) then return false end
	end
	return true
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["SpotRequisition"] = class(Requisition, function(c)
	Requisition.init(c)	-- must init base!
	c.TaskId = _G["TASK_ADAGENCY"]
	c.Priority = 5
	c.Count = 0
	c.FulfilledCount = 0
	c.Level = -1
	c.SlotReqs = nil
end)

function SpotRequisition:typename()
	return "SpotRequisition"
end

function SpotRequisition:CheckActuality()
	if (self.Done) then return false end

	local removeList = {}
	for k,v in pairs(self.SlotReqs) do
		if (v:CheckActuality() == false) then
			table.insert(removeList, v)
		end
	end

	for k,v in pairs(removeList) do
		table.removeElement(self.SlotReqs, v)
		self.Count = self.Count - 1
	end

	if (self.Count > 0) then
		return true
	else
		self:Complete()
		return false
	end
end

function SpotRequisition:Complete()
	self.Done = true
	local player = _G["globalPlayer"]
	player:RemoveRequisition(self)
end

function SpotRequisition:UseThisContract(contract)
	--debugMsg("SpotRequisition:UseThisContract - Start")
	--Als Folge der erf�llten Anforderung, werden nun Anforderungen an den Programmplan gestellt
	local conCount = contract.GetSpotCount()

	local player = _G["globalPlayer"]
	for k,v in pairs(self.SlotReqs) do
		if (self.FulfilledCount >= self.Count) then --Es werden keine weiteren SpotSlots ben�tigt um die Anforderung zu erf�llen
		--	debugMsg("SpotRequisition:UseThisContract - Complete")
			self:Complete()
			return
		end

		v.TaskId = _G["TASK_SCHEDULE"]
		v.TaskOwnerId = _G["TASK_ADAGENCY"]
		--debugMsg("SpotRequisition:UseThisContract - id: " .. contract:GetID() .. " --- " .. v.Day .. "/" .. v.Hour .. " # " .. v.TaskId)
		v.ContractId = contract:GetID()
		player:AddRequisition(v)
		self.FulfilledCount = self.FulfilledCount + 1
	end
	--debugMsg("SpotRequisition:UseThisContract - End")
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["SpotSlotRequisition"] = class(Requisition, function(c)
	Requisition.init(c)	-- must init base!
	c.TaskId = nil
	c.Priority = 3
	c.Day = -1
	c.Hour = -1
	c.ContractId = -1
end)

function SpotSlotRequisition:typename()
	return "SpotSlotRequisition"
end

function SpotSlotRequisition:CheckActuality()
	if (self.Done) then return false end

	if (self.Day >= WorldTime.GetDay() or ( self.Day == WorldTime.GetDay() and self.Hour + 2 > WorldTime.GetDayHour())) then
		return true
	else
		self:Complete()
		return false
	end
end

function SpotSlotRequisition:Complete()
	self.Done = true
	local player = _G["globalPlayer"]
	player:RemoveRequisition(self)
end
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_G["AIToolsClass"] = class(KIObjekt)

function AIToolsClass:typename()
	return "AIToolsClass"
end

function AIToolsClass:GetAverageMovieQualityByLevel(level)
	if (level == 1) then
		return 0.03 --Nachtprogramm
	elseif (level == 2) then
		return 0.08 --Mitternacht + Morgen
	elseif (level == 3) then
		return 0.13 -- Nachmittag
	elseif (level == 4) then
		return 0.18 -- Vorabend / Sp�t
	elseif (level == 5) then
		return 0.22 -- Primetime
	end
end

function AIToolsClass:GetMaxAudiencePercentageByLevel(level)
	if level == 1 then
		return 0.0347
	elseif level == 2 then
		return 0.0666
	elseif level == 3 then
		return 0.1161
	elseif level == 4 then
		return 0.2088
	elseif level == 5 then
		return 0.3459
	end
end

function AIToolsClass:GuessedAudienceForLevel(level)
	--debugMsg("GuessedAudienceForLevel - level: " .. level)
	local globalPercentageByHour = self:GetMaxAudiencePercentageByLevel(level) -- Die Maximalquote: Entspricht ungef�hr "maxAudiencePercentage"
	--debugMsg("globalPercentageByHour: " .. globalPercentageByHour)
	local averageMovieQualityByLevel = self:GetAverageMovieQualityByLevel(level) -- Die Durchschnittsquote dieses Qualit�tslevels

	--Formel: Filmqualit�t * Potentielle Quote nach Uhrzeit (maxAudiencePercentage) * Echte Maximalzahl der Zuschauer
	local guessedAudience = averageMovieQualityByLevel * globalPercentageByHour * MY.GetMaxAudience()

	--debugMsg("GuessedAudienceForLevel: " .. guessedAudience .. " = averageMovieQualityByLevel (" .. averageMovieQualityByLevel .. ") * globalPercentageByHour (" .. globalPercentageByHour .. ") *  MY.GetMaxAudience() (" .. MY.GetMaxAudience() .. ")")

	return guessedAudience
end

AITools = AIToolsClass()
-- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<