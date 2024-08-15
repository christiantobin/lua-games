-- Set the
-- Set the package path to include the directory of this script
package.path = package.path .. ";/home/cjtobin/games/?.lua"
local shared = require("slots_shared")

local BET_DENOMINATIONS = { 1, 2, 3, 5 }

local function slotMachine()
	local money = shared.readBankroll()
	local playing = true

	while playing do
		shared.clearScreen()
		print(shared.coloredText("blue", "Current Money: $" .. money))
		print("Choose the denomination for betting on all 7 lines:")
		for i, denom in ipairs(BET_DENOMINATIONS) do
			print("(" .. i .. ") Bet $" .. denom .. " per line - Total Cost: $" .. (denom * 7))
		end

		local choice = tonumber(io.read())
		local denom = BET_DENOMINATIONS[choice]

		if not denom then
			print(shared.coloredText("red", "Invalid choice!"))
		else
			local totalBet = denom * 7
			if totalBet > money then
				print(shared.coloredText("red", "Insufficient funds!"))
			else
				money = money - totalBet
				local reel = shared.generateReel()
				print(shared.coloredText("yellow", "\nReel:"))
				shared.printReel(reel)

				local wins, winLines, freeGamesTriggered, miniPrize, minorPrize, majorPrize, totalPayout =
					shared.checkWin(reel, 7, denom)
				if wins > 0 then
					money = money + totalPayout
					print(
						shared.coloredText(
							"green",
							"You won on lines: " .. table.concat(winLines, ", ") .. "! Payout: $" .. totalPayout
						)
					)
				else
					print(shared.coloredText("red", "No win!"))
				end

				if freeGamesTriggered then
					print(shared.coloredText("yellow", "You triggered " .. FREE_GAMES_COUNT .. " free games!"))
					money = shared.playFreeGames(money, 7, denom)
				end

				if miniPrize then
					money = money + MINI_PRIZE
					print(shared.coloredText("green", "You won a MINI prize: $" .. MINI_PRIZE))
				end
				if minorPrize then
					money = money + MINOR_PRIZE
					print(shared.coloredText("green", "You won a MINOR prize: $" .. MINOR_PRIZE))
				end
				if majorPrize then
					money = money + MAJOR_PRIZE
					print(shared.coloredText("green", "You won a MAJOR prize: $" .. MAJOR_PRIZE))
				end

				shared.saveBankroll(money)
			end
		end

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

slotMachine()()
