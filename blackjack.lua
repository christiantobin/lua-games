math.randomseed(os.time())

-- Constants
local BLACKJACK = 21
local DEALER_STAND = 17
local MIN_BET = 1
local BLACKJACK_PAYOUT = 1.5
local BANKROLL_FILE = "/home/cjtobin/games/bankroll.txt"

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

-- Cards and Deck
local suits = { "Hearts", "Diamonds", "Clubs", "Spades" }
local values = { "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A" }

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
	if card.value == "J" or card.value == "Q" or card.value == "K" then
		return 10
	elseif card.value == "A" then
		return 11
	else
		return tonumber(card.value)
	end
end

local function handValue(hand)
	local value, aces = 0, 0
	for _, card in ipairs(hand) do
		value = value + cardValue(card)
		if card.value == "A" then
			aces = aces + 1
		end
	end
	while value > BLACKJACK and aces > 0 do
		value = value - 10
		aces = aces - 1
	end
	return value
end

local function isSoft17(hand)
	return handValue(hand) == 17 and handValue(hand, true) == 17
end

local function printCard(card)
	print(card.value .. " of " .. card.suit)
end

local function printHand(hand, hideSecondCard)
	for i, card in ipairs(hand) do
		if i == 2 and hideSecondCard then
			print("Hidden")
		else
			printCard(card)
		end
	end
end

local function printGame(playerHands, dealerHand, playerMoney, playerBet, hideDealerSecondCard)
	clearScreen()
	print(coloredText("yellow", "\nDealer's Hand:"))
	printHand(dealerHand, hideDealerSecondCard)
	if not hideDealerSecondCard then
		print("Value: " .. handValue(dealerHand))
	end
	for i, hand in ipairs(playerHands) do
		print(coloredText("green", "\nPlayer's Hand " .. i .. ":"))
		printHand(hand, false)
		print("Value: " .. handValue(hand))
	end
	print(coloredText("blue", "\nPlayer's Money: $" .. playerMoney))
	print(coloredText("blue", "Current Bet: $" .. playerBet))
end

local function printFinalHands(playerHands, dealerHand)
	print(coloredText("yellow", "\nFinal Dealer's Hand:"))
	printHand(dealerHand, false)
	print("Value: " .. handValue(dealerHand))
	for i, hand in ipairs(playerHands) do
		print(coloredText("green", "\nFinal Player's Hand " .. i .. ":"))
		printHand(hand, false)
		print("Value: " .. handValue(hand))
	end
end

-- Basic Strategy
local function basicStrategy(playerHand, dealerCard)
	local playerValue = handValue(playerHand)
	local dealerValue = cardValue(dealerCard)
	local soft = false
	for _, card in ipairs(playerHand) do
		if card.value == "A" then
			soft = true
			break
		end
	end

	if soft and playerValue <= 18 then
		if playerValue <= 17 or (playerValue == 18 and (dealerValue >= 9 or dealerValue == 1)) then
			return "h"
		else
			return "j"
		end
	elseif playerValue >= 17 then
		return "j"
	elseif playerValue >= 13 and playerValue <= 16 then
		if dealerValue >= 2 and dealerValue <= 6 then
			return "j"
		else
			return "h"
		end
	elseif playerValue == 12 then
		if dealerValue >= 4 and dealerValue <= 6 then
			return "j"
		else
			return "h"
		end
	else
		return "h"
	end
end

local function playHand(hand, deck, dealerCard, money, bet)
	local playerTurn = true
	while playerTurn do
		printGame({ hand }, { dealerCard, { value = "Hidden", suit = "Hidden" } }, money, bet, true)
		print("\nChoose action: (h)it, (j)stand, (k)double")
		local action = io.read()
		if action == "" then
			action = "h"
		end

		-- Check if the player played by the book
		local bookAction = basicStrategy(hand, dealerCard)
		local message = (action == bookAction) and "You played by the book!" or "You did not play by the book."

		if action == "h" then
			table.insert(hand, table.remove(deck))
			print(coloredText("blue", message))
			if handValue(hand) > BLACKJACK then
				playerTurn = false
			end
		elseif action == "j" then
			print(coloredText("blue", message))
			playerTurn = false
		elseif action == "k" then
			if money >= bet then
				money = money - bet
				bet = bet * 2
				table.insert(hand, table.remove(deck))
				playerTurn = false
				print(coloredText("blue", message))
			else
				print("Not enough money to double down.")
			end
		end

		-- Tally the number of times the player played by the book
		if action == bookAction then
			return hand, money, bet, true
		else
			return hand, money, bet, false
		end
	end
	return hand, money, bet, false
end

local function playBlackjack()
	local money = readBankroll()
	local playing = true
	local rounds = 0
	local wins = 0
	local losses = 0
	local byTheBookCount = 0

	while playing do
		local bet = MIN_BET

		-- Adjust the bet using simple inputs
		local adjustingBet = true
		while adjustingBet do
			print("\nAdjust your bet: $" .. bet)
			print("Press 'u' to increase, 'd' to decrease, 's' to start")
			local betInput = io.read()
			if betInput == "" then
				betInput = "s"
			end
			if betInput == "u" then
				bet = bet + 1
			elseif betInput == "d" then
				if bet > MIN_BET then
					bet = bet - 1
				end
			elseif betInput == "s" then
				adjustingBet = false
			end
		end

		-- Deduct bet from money
		money = money - bet

		-- Create and shuffle deck
		local deck = createDeck()
		shuffle(deck)

		-- Deal initial hands
		local playerHands = { { table.remove(deck), table.remove(deck) } }
		local dealerHand = { table.remove(deck), table.remove(deck) }

		-- Check for immediate Blackjack
		if handValue(playerHands[1]) == BLACKJACK and handValue(dealerHand) ~= BLACKJACK then
			printGame(playerHands, dealerHand, money, bet, true)
			print(coloredText("green", "\nPlayer has Blackjack!"))
			money = money + bet + (bet * BLACKJACK_PAYOUT)
			wins = wins + 1
			print(coloredText("blue", "\nPlayer's Money: $" .. money))
		else
			local handIndex = 1
			while handIndex <= #playerHands do
				local hand = playerHands[handIndex]
				local playedByBook
				hand, money, bet, playedByBook = playHand(hand, deck, dealerHand[1], money, bet)
				if playedByBook then
					byTheBookCount = byTheBookCount + 1
				end
				handIndex = handIndex + 1
			end

			-- Dealer's turn
			while
				handValue(dealerHand) < DEALER_STAND or (handValue(dealerHand) == DEALER_STAND and isSoft17(dealerHand))
			do
				table.insert(dealerHand, table.remove(deck))
			end

			-- Determine winner
			for _, hand in ipairs(playerHands) do
				local playerValue = handValue(hand)
				local dealerValue = handValue(dealerHand)

				if playerValue > BLACKJACK then
					print(coloredText("red", "\nPlayer busts with hand:"))
					printHand(hand, false)
					losses = losses + 1
				elseif dealerValue > BLACKJACK or playerValue > dealerValue then
					print(coloredText("green", "\nPlayer wins with hand:"))
					printHand(hand, false)
					money = money + bet * 2
					wins = wins + 1
				elseif playerValue < dealerValue then
					print(coloredText("red", "\nDealer wins against hand:"))
					printHand(hand, false)
					losses = losses + 1
				else
					print(coloredText("yellow", "\nPush with hand:"))
					printHand(hand, false)
					money = money + bet
				end

				-- Check for Blackjack
				if playerValue == BLACKJACK and #hand == 2 then
					print(coloredText("green", "\nBlackjack! Payout: 3 to 2"))
					money = money + bet * BLACKJACK_PAYOUT
					wins = wins + 1
				end
			end

			-- Print final hands
			printFinalHands(playerHands, dealerHand)
		end

		rounds = rounds + 1
		print(coloredText("blue", "\nEnd of round. Player's Money: $" .. money))
		saveBankroll(money) -- Save bankroll after each round

		if money < MIN_BET then
			print(coloredText("red", "Not enough money to continue playing."))
			playing = false
		else
			print("Do you want to play another round? (y/n)")
			local continue = io.read()
			if continue == "" then
				continue = "y"
			end
			if continue ~= "y" then
				playing = false
			end
		end
	end

	print(coloredText("blue", "Game over. Player's Money: $" .. money))
	print(coloredText("yellow", "Rounds played: " .. rounds))
	print(coloredText("green", "Wins: " .. wins))
	print(coloredText("red", "Losses: " .. losses))
	print(coloredText("blue", "Times played by the book: " .. byTheBookCount))
end

playBlackjack()
