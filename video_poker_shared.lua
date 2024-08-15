math.randomseed(os.time())

-- Constants
local BANKROLL_FILE = "/home/cjtobin/games/bankroll.txt"
local suits = { "Hearts", "Diamonds", "Clubs", "Spades" }
local values = { "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A" }

-- Utility functions
local function clearScreen()
	os.execute("clear") -- Use "cls" for Windows
end

local function coloredText(color, text)
	local colors = {
		reset = "\27[0m",
		red = "\27[31m",
		green = "\27[32m",
		yellow = "\27[33m",
		blue = "\27[34m",
		magenta = "\27[35m",
		cyan = "\27[36m",
		white = "\27[37m",
	}
	return colors[color] .. text .. colors["reset"]
end

local function readBankroll()
	local file = io.open(BANKROLL_FILE, "r")
	if file then
		local bankroll = tonumber(file:read("*all"))
		file:close()
		return bankroll
	else
		return 100 -- Default initial bankroll
	end
end

local function saveBankroll(bankroll)
	local file = io.open(BANKROLL_FILE, "w")
	file:write(tostring(bankroll))
	file:close()
end

local function createDeck()
	local deck = {}
	for _, suit in ipairs(suits) do
		for _, value in ipairs(values) do
			table.insert(deck, { value = value, suit = suit })
		end
	end
	return deck
end

local function shuffle(deck)
	for i = #deck, 2, -1 do
		local j = math.random(i)
		deck[i], deck[j] = deck[j], deck[i]
	end
end

local function cardValue(card)
	if card.value == "J" then
		return 11
	elseif card.value == "Q" then
		return 12
	elseif card.value == "K" then
		return 13
	elseif card.value == "A" then
		return 14
	else
		return tonumber(card.value)
	end
end

local function printCard(card)
	print(coloredText("yellow", card.value .. " of " .. card.suit))
end

local function printHand(hand)
	for _, card in ipairs(hand) do
		printCard(card)
	end
end

-- Poker hand evaluation functions
local function isFlush(hand)
	local suit = hand[1].suit
	for i = 2, #hand do
		if hand[i].suit ~= suit then
			return false
		end
	end
	return true
end

local function isStraight(hand)
	local cardValues = {}
	for _, card in ipairs(hand) do
		table.insert(cardValues, cardValue(card))
	end
	table.sort(cardValues)
	for i = 1, #cardValues - 1 do
		if cardValues[i] + 1 ~= cardValues[i + 1] then
			return false
		end
	end
	return true
end

local function countRanks(hand)
	local rankCounts = {}
	for _, card in ipairs(hand) do
		local rank = card.value
		rankCounts[rank] = (rankCounts[rank] or 0) + 1
	end
	return rankCounts
end

local function evaluateHand(hand)
	local flush = isFlush(hand)
	local straight = isStraight(hand)
	local rankCounts = countRanks(hand)

	if flush and straight and cardValue(hand[1]) == 14 then
		return "Royal Flush"
	elseif flush and straight then
		return "Straight Flush"
	elseif rankCounts[4] then
		return "Four of a Kind"
	elseif rankCounts[3] and rankCounts[2] then
		return "Full House"
	elseif flush then
		return "Flush"
	elseif straight then
		return "Straight"
	elseif rankCounts[3] then
		return "Three of a Kind"
	elseif rankCounts[2] and tableCount(rankCounts[2]) == 2 then
		return "Two Pair"
	elseif rankCounts[2] then
		return "One Pair"
	else
		return "High Card"
	end
end

local function tableCount(tbl)
	local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	return count
end

local function payoutMultiplier(handRank)
	local payouts = {
		["Royal Flush"] = 250,
		["Straight Flush"] = 50,
		["Four of a Kind"] = 25,
		["Full House"] = 9,
		["Flush"] = 6,
		["Straight"] = 4,
		["Three of a Kind"] = 3,
		["Two Pair"] = 2,
		["One Pair"] = 1,
		["High Card"] = 0,
	}
	return payouts[handRank] or 0
end

-- Expose functions for other scripts
return {
	clearScreen = clearScreen,
	coloredText = coloredText,
	readBankroll = readBankroll,
	saveBankroll = saveBankroll,
	createDeck = createDeck,
	shuffle = shuffle,
	printHand = printHand,
	evaluateHand = evaluateHand,
	payoutMultiplier = payoutMultiplier,
}
