--!strict
--[[
	AchievementData — 20 achievements that map onto the natural play loop.
	Each grants a tangible reward on claim, creating "one more session"
	retention pressure. The completion bar is visible from join.
]]

export type Achievement = {
	id: string,
	name: string,
	description: string,
	statKey: string,    -- which field of profile.stats to read
	target: number,
	reward: { kind: string, amount: number },
}

local achievements: { Achievement } = {
	-- Capture-based
	{ id="cap_5",     name="Trainee",            description="Capture 5 brainrots.",            statKey="totalCaptured", target=5,      reward={ kind="cash", amount=500 } },
	{ id="cap_25",    name="Collector",          description="Capture 25 brainrots.",           statKey="totalCaptured", target=25,     reward={ kind="cash", amount=2500 } },
	{ id="cap_100",   name="Lab Director",       description="Capture 100 brainrots.",          statKey="totalCaptured", target=100,    reward={ kind="cash", amount=10000 } },
	{ id="cap_500",   name="Brainrot Whisperer", description="Capture 500 brainrots.",          statKey="totalCaptured", target=500,    reward={ kind="rare_egg", amount=1 } },

	-- Mutation-based (the novel mechanic)
	{ id="mut_5",     name="Mutation Witness",   description="Trigger 5 mutations.",            statKey="totalMutations", target=5,     reward={ kind="cash", amount=750 } },
	{ id="mut_50",    name="Mutation Maestro",   description="Trigger 50 mutations.",           statKey="totalMutations", target=50,    reward={ kind="cash", amount=5000 } },
	{ id="mut_250",   name="Genetic Architect",  description="Trigger 250 mutations.",          statKey="totalMutations", target=250,   reward={ kind="instant_mutation", amount=2 } },
	{ id="mut_1000",  name="Lab Singularity",    description="Trigger 1000 mutations.",         statKey="totalMutations", target=1000,  reward={ kind="rare_egg", amount=3 } },

	-- Steal-based (PvP)
	{ id="steal_1",   name="First Score",        description="Steal your first brainrot.",      statKey="totalSteals", target=1,        reward={ kind="cash", amount=1000 } },
	{ id="steal_10",  name="Pickpocket",         description="Steal 10 brainrots.",             statKey="totalSteals", target=10,       reward={ kind="cash", amount=5000 } },
	{ id="steal_50",  name="Heist Boss",         description="Steal 50 brainrots.",             statKey="totalSteals", target=50,       reward={ kind="infection_bomb", amount=5 } },

	-- Infection-based (PvP)
	{ id="inf_1",     name="Patient Zero",       description="Infect another player once.",     statKey="totalInfections", target=1,    reward={ kind="cash", amount=1000 } },
	{ id="inf_10",    name="Outbreak Engineer",  description="Infect players 10 times.",        statKey="totalInfections", target=10,   reward={ kind="cash", amount=5000 } },
	{ id="inf_50",    name="Plague Doctor",      description="Infect players 50 times.",        statKey="totalInfections", target=50,   reward={ kind="rare_egg", amount=1 } },

	-- Cash earned (volume)
	{ id="cash_10k",  name="Sigma Salaryman",    description="Earn 10,000 cash total.",         statKey="totalCashEarned", target=10000,    reward={ kind="cash", amount=2000 } },
	{ id="cash_100k", name="Brainrot Banker",    description="Earn 100,000 cash total.",        statKey="totalCashEarned", target=100000,   reward={ kind="cash", amount=15000 } },
	{ id="cash_1m",   name="Tycoon Tier",        description="Earn 1,000,000 cash total.",      statKey="totalCashEarned", target=1000000,  reward={ kind="rare_egg", amount=2 } },
	{ id="cash_10m",  name="Apex Mogul",         description="Earn 10,000,000 cash total.",     statKey="totalCashEarned", target=10000000, reward={ kind="cash", amount=500000 } },

	-- Rebirth (read from profile.rebirths separately)
	{ id="reb_1",     name="Born Again",         description="Reach Rebirth 1.",                statKey="rebirths", target=1,            reward={ kind="cash", amount=2500 } },
	{ id="reb_5",     name="Cycle Master",       description="Reach Rebirth 5.",                statKey="rebirths", target=5,            reward={ kind="rare_egg", amount=1 } },
}

local AchievementData = {}

function AchievementData.GetAll(): { Achievement }
	return achievements
end

function AchievementData.Get(id: string): Achievement?
	for _, a in ipairs(achievements) do
		if a.id == id then return a end
	end
	return nil
end

return AchievementData
