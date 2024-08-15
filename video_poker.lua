local shared = require("video_poker_shared")

local function videoPoker()
	local money = shared.readBankroll()
	local playing = true

	while playing do
		shared.clearScreen()
		print(shared.coloredText("blue", "Current Money: $" .. money))

		-- Get the number of hands
		print("Enter the number of hands you want to play:")
		local numHands = tonumber(io.read())
		if not numHands or numHands <= 0 then
			print(shared.coloredText("red", "Invalid number of hands!"))
			break
		end

		-- Get the bet per hand
		print("Enter your bet per hand:")
		local betPerHand = tonumber(io.read())
		if not betPerHand or betPerHand <= 0 or betPerHand * numHands > money then
			print(shared.coloredText("red", "Invalid bet amount or insufficient funds!"))
			break
		end

		-- Deduct the total bet from the bankroll
		local totalBet = betPerHand * numHands
		money = money - totalBet

		-- Create and shuffle the deck
		local deck = shared.createDeck()
		shared.shuffle(deck)

		-- Deal initial hands
		local hands = {}
		for i = 1, numHands do
			local hand = {}
			for j = 1, 5 do
				table.insert(hand, table.remove(deck))
			end
			table.insert(hands, hand)
		end

		-- Display hands and let the player choose cards to hold
		for i, hand in ipairs(hands) do
			print(shared.coloredText("green", "\nHand " .. i .. ":"))
			shared.printHand(hand)
			print("Enter the card positions (1-5) to hold, separated by spaces, or press Enter to discard all:")
			local holds = io.read()
			local holdPositions = {}
			for position in holds:gmatch("%d") do
				holdPositions[tonumber(position)] = true
			end

			-- Draw new cards for positions not held
			for j = 1, 5 do
				if not holdPositions[j] then
					hand[j] = table.remove(deck)
				end
			end
		end

		-- Evaluate hands and calculate payouts
		local totalWin = 0
		for i, hand in ipairs(hands) do
			print(shared.coloredText("green", "\nFinal Hand " .. i .. ":"))
			shared.printHand(hand)
			local handRank = shared.evaluateHand(hand)
			local multiplier = shared.payoutMultiplier(handRank)
			local handWin = betPerHand * multiplier
			totalWin = totalWin + handWin
			print(shared.coloredText("yellow", "Hand Rank: " .. handRank .. " | Win: $" .. handWin))
		end

		-- Add winnings to the bankroll
		money = money + totalWin
		print(shared.coloredText("yellow", "\nTotal Win: $" .. totalWin))
		shared.saveBankroll(money)

		-- Check if the player wants to play again
		print("Do you want to play again? (y/n)")
		local continue = io.read()
		if continue == "" then
			continue = "y"
		end
		if continue ~= "y" then
			playing = false
		end
	end

	print(shared.coloredText("blue", "Game over. Player's Money: $" .. money))
end

videoPoker()
