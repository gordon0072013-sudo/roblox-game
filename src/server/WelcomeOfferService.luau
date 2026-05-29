--!strict

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config  = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local Log     = require(Shared.Log)

local DataService = require(script.Parent.DataService)

local WelcomeOfferService = {}

local OFFER_DURATION_SECONDS = 600   -- 10 min visibility window
local OFFER_SHOW_DELAY        = 90    -- give them ~90s of play first
local OFFER_PRODUCT_KEY      = "CashLarge"   -- bundles 7,500 cash

local function ensure(data: any)
	data._welcomeOffer = data._welcomeOffer or {
		shown = false,
		usedAt = 0,
		shownAt = 0,
	}
end

local function pushOffer(player: Player)
	local data = DataService.Get(player)
	if not data then return end
	ensure(data)
	local product = Config.DEV_PRODUCTS[OFFER_PRODUCT_KEY]
	if not product then return end
	Remotes.Event(Remotes.Names.WelcomeOffer):FireClient(player, {
		kind = "show",
		productKey = OFFER_PRODUCT_KEY,
		title = `STARTER PACK · 50% extra cash`,
		body  = string.format("Get %s cash for just %d R$. Today only — applies to your first purchase.",
			tostring(product.amount or 0), product.price),
		productPrice = product.price,
		expiresIn = OFFER_DURATION_SECONDS,
	})
	data._welcomeOffer.shown = true
	data._welcomeOffer.shownAt = os.time()
	Log.Info("WelcomeOffer", "shown to %s", player.Name)
end

function WelcomeOfferService.OnPlayerAdded(player: Player)
	DataService.OnProfileLoaded(player, function()
		local data = DataService.Get(player)
		if not data then return end
		ensure(data)
		-- Only first-time players (never bought anything) see this.
		local hasBought = (data :: any)._purchaseLog and #((data :: any)._purchaseLog) > 0
		if data._welcomeOffer.shown or hasBought then return end
		task.delay(OFFER_SHOW_DELAY, function()
			-- player.Parent vs Players:FindFirstChild(name): the latter is
			-- true even if the player left and a same-named account rejoined,
			-- which would surprise the new session with a leftover offer.
			-- Parent check ties to this specific Player instance.
			if not player.Parent then return end
			pushOffer(player)
		end)
	end)
end

function WelcomeOfferService.Init()
	Remotes.Event(Remotes.Names.WelcomeOffer)
end

return WelcomeOfferService
