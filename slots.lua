math.randomseed(os.time())

-- Constants
local BANKROLL_FILE = "/home/cjtobin/games/bankroll.txt"
local SYMBOLS = { "9", "J", "Q", "K", "A", "G", "C" } -- Casino-themed symbols
local REEL_ROWS = 3
local REEL_COLS = 5 -- Changed to 5 columns
local LINE_OPTIONS = { 1, 2, 3, 4, 5, 6, 7 }
local BET_AMOUNT = 1 -- Fixed bet amount per line
local FREE_GAMES_TRIGGER_SYMBOL = "G"
local FREE_GAMES_COUNT = 6
local MINI_PRIZE = 50
local MINOR_PRIZE = 150
local MAJOR_PRIZE = 500

-- Paytable based on symbol rarity
local PAYTABLE = {
	["9"] = { 3, 5, 10, 20 },
	["J"] = { 3, 10, 20, 40 },
	["Q"] = { 3, 15, 30, 60 },
	["K"] = { 3, 20, 40, 80 },
	["A"] = { 3, 25, 50, 100 },
	["G"] = { 3, 0, 0, 0 }, -- Free games, no payout
	["C"] = { 3, 0, 0, 0 }, -- Word awards, no payout
}

-- Symbol distribution for adjusting rarity
local SYMBOL_DISTRIBUTION = {
	"9",
	"9",
	"9",
	"9",
	"9",
	"J",
	"J",
	"J",
	"J",
	"Q",
	"Q",
	"Q",
	"K",
	"K",
	"A",
	"G",
	"C",
}

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

local symbolColors = {
	["9"] = "yellow",
	["J"] = "blue",
	["Q"] = "magenta",
	["K"] = "cyan",
	["A"] = "green",
	["G"] = "red",
	["C"] = "white",
}

local function colorizeSymbol(symbol)
	return coloredText(symbolColors[symbol], symbol)
end

-- Slot Machine functions
local function generateReel()
	local reel = {}
	for row = 1, REEL_ROWS do
		reel[row] = {}
		for col = 1, REEL_COLS do
			reel[row][col] = SYMBOL_DISTRIBUTION[math.random(#SYMBOL_DISTRIBUTION)]
		end
	end
	return reel
end

local function printReel(reel)
	for row = 1, REEL_ROWS do
		for col = 1, REEL_COLS do
			io.write(colorizeSymbol(reel[row][col]) .. " ")
		end
		print()
	end
end

-- Function to get the symbols in a line based on the line number
local function getLineSymbols(reel, line)
	local symbols = {}
	if line == 1 then
		-- Horizontal Line 1
		for col = 1, REEL_COLS do
			table.insert(symbols, reel[1][col])
		end
	elseif line == 2 then
		-- Horizontal Line 2
		for col = 1, REEL_COLS do
			table.insert(symbols, reel[2][col])
		end
	elseif line == 3 then
		-- Horizontal Line 3
		for col = 1, REEL_COLS do
			table.insert(symbols, reel[3][col])
		end
	elseif line == 4 then
		-- Diagonal Line 1 (Top-left to Bottom-right)
		for i = 1, math.min(REEL_ROWS, REEL_COLS) do
			table.insert(symbols, reel[i][i])
		end
	elseif line == 5 then
		-- Diagonal Line 2 (Bottom-left to Top-right)
		for i = 1, math.min(REEL_ROWS, REEL_COLS) do
			table.insert(symbols, reel[REEL_ROWS - i + 1][i])
		end
	elseif line == 6 then
		-- V-Shape Line 1 (Middle to Top, then back to Middle)
		table.insert(symbols, reel[2][1])
		table.insert(symbols, reel[1][2])
		table.insert(symbols, reel[2][3])
		table.insert(symbols, reel[3][4])
		table.insert(symbols, reel[2][5])
	elseif line == 7 then
		-- V-Shape Line 2 (Middle to Bottom, then back to Middle)
		table.insert(symbols, reel[2][1])
		table.insert(symbols, reel[3][2])
		table.insert(symbols, reel[2][3])
		table.insert(symbols, reel[1][4])
		table.insert(symbols, reel[2][5])
	end
	return symbols
end

-- Function to check for wins based on active lines
local function checkWin(reel, lines)
	local wins = 0
	local winLines = {}
	local freeGamesTriggered = false
	local miniPrize = false
	local minorPrize = false
	local majorPrize = false
	local totalPayout = 0

	for line = 1, lines do
		local symbols = getLineSymbols(reel, line)
		local symbol = symbols[1]
		local count = 1
		for i = 2, #symbols do
			if symbols[i] == symbol then
				count = count + 1
			else
				break
			end
		end
		if count >= 3 then
			wins = wins + 1
			table.insert(winLines, line)
			totalPayout = totalPayout + PAYTABLE[symbol][math.min(count, 5) - 2] * BET_AMOUNT
			if symbol == FREE_GAMES_TRIGGER_SYMBOL then
				freeGamesTriggered = true
			end
		end
		if symbol == "C" then
			if count == 3 then
				miniPrize = true
			elseif count == 4 then
				minorPrize = true
			elseif count == 5 then
				majorPrize = true
			end
		end
	end
	return wins, winLines, freeGamesTriggered, miniPrize, minorPrize, majorPrize, totalPayout
end

local function checkRetrigger(reel, lines)
	for line = 1, lines do
		local countG = 0
		local symbols = getLineSymbols(reel, line)
		for _, symbol in ipairs(symbols) do
			if symbol == FREE_GAMES_TRIGGER_SYMBOL then
				countG = countG + 1
			end
		end
		if countG >= 2 then
			return true
		end
	end
	return false
end

local function playFreeGames(money, lines)
	local freeGamesRemaining = FREE_GAMES_COUNT
	local freeGamesTotalWin = 0
	while freeGamesRemaining > 0 do
		clearScreen()
		print(
			coloredText(
				"blue",
				"Free Game " .. (FREE_GAMES_COUNT - freeGamesRemaining + 1) .. " of " .. FREE_GAMES_COUNT
			)
		)
		local reel = generateReel()
		print(coloredText("yellow", "\nReel:"))
		printReel(reel)

		local wins, winLines, _, miniPrize, minorPrize, majorPrize, totalPayout = checkWin(reel, lines)
		if wins > 0 then
			freeGamesTotalWin = freeGamesTotalWin + totalPayout
			money = money + totalPayout
			print(
				coloredText(
					"green",
					"You won on lines: " .. table.concat(winLines, ", ") .. "! Payout: $" .. totalPayout
				)
			)
		else
			print(coloredText("red", "No win!"))
		end

		if checkRetrigger(reel, lines) then
			freeGamesRemaining = freeGamesRemaining + FREE_GAMES_COUNT
			print(
				coloredText(
					"yellow",
					"Free games re-triggered! You now have " .. freeGamesRemaining .. " free games remaining!"
				)
			)
		end

		if miniPrize then
			freeGamesTotalWin = freeGamesTotalWin + MINI_PRIZE
			money = money + MINI_PRIZE
			print(coloredText("green", "You won a MINI prize: $" .. MINI_PRIZE))
		end
		if minorPrize then
			freeGamesTotalWin = freeGamesTotalWin + MINOR_PRIZE
			money = money + MINOR_PRIZE
			print(coloredText("green", "You won a MINOR prize: $" .. MINOR_PRIZE))
		end
		if majorPrize then
			freeGamesTotalWin = freeGamesTotalWin + MAJOR_PRIZE
			money = money + MAJOR_PRIZE
			print(coloredText("green", "You won a MAJOR prize: $" .. MAJOR_PRIZE))
		end

		freeGamesRemaining = freeGamesRemaining - 1
		print("Press Enter to continue...")
		io.read()
	end
	print(coloredText("yellow", "Total win from free games: $" .. freeGamesTotalWin))
	return money
end

local function slotMachine()
	local money = readBankroll()
	local playing = true

	while playing do
		clearScreen()
		print(coloredText("blue", "Current Money: $" .. money))
		print("Choose the number of lines to bet on:")
		for i, lines in ipairs(LINE_OPTIONS) do
			local cost = lines * BET_AMOUNT
			print("(" .. i .. ") Bet on " .. lines .. " line(s) - Cost: $" .. cost)
		end

		local choice = tonumber(io.read())
		local lines = LINE_OPTIONS[choice]

		if not lines then
			print(coloredText("red", "Invalid choice!"))
		else
			local totalBet = BET_AMOUNT * lines
			if totalBet > money then
				print(coloredText("red", "Insufficient funds!"))
			else
				money = money - totalBet
				local reel = generateReel()
				print(coloredText("yellow", "\nReel:"))
				printReel(reel)

				local wins, winLines, freeGamesTriggered, miniPrize, minorPrize, majorPrize, totalPayout =
					checkWin(reel, lines)
				if wins > 0 then
					money = money + totalPayout
					print(
						coloredText(
							"green",
							"You won on lines: " .. table.concat(winLines, ", ") .. "! Payout: $" .. totalPayout
						)
					)
				else
					print(coloredText("red", "No win!"))
				end

				if freeGamesTriggered then
					print(coloredText("yellow", "You triggered " .. FREE_GAMES_COUNT .. " free games!"))
					money = playFreeGames(money, lines)
				end

				if miniPrize then
					money = money + MINI_PRIZE
					print(coloredText("green", "You won a MINI prize: $" .. MINI_PRIZE))
				end
				if minorPrize then
					money = money + MINOR_PRIZE
					print(coloredText("green", "You won a MINOR prize: $" .. MINOR_PRIZE))
				end
				if majorPrize then
					money = money + MAJOR_PRIZE
					print(coloredText("green", "You won a MAJOR prize: $" .. MAJOR_PRIZE))
				end

				saveBankroll(money)
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

	print(coloredText("blue", "Game over. Player's Money: $" .. money))
end

slotMachine()
