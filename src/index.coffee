# Wurm Unlimited Merchants Listing
# by woubuc - http://github.com/woubuc


# Node modules
fs = require 'fs'
path = require 'path'

# Third party modules
async = require 'async'
yaml = require 'js-yaml'
exists = require 'exists-file'
sqlite3 = require('sqlite3').verbose()


# Load config
config = yaml.safeLoad fs.readFileSync('./config.yml')


# Databases
db_names = ['wurmeconomy', 'wurmcreatures', 'wurmitems', 'wurmplayers']
dbs = {}

# Connect to databases
for db in db_names

	# Get path to file
	p = path.join(config.db_path, db + '.db')

	# Check if it exists
	if not exists p
		console.error 'Could not find ' + db + '.db'
		process.exit()

	# Create database connection
	dbs[db] = new sqlite3.Database(p)


# Prepare array
merchants = []

# Function to parse total price into g, s, c and i
parse_price = (price) ->
	return no if price is 0
	obj =
		total: price
		g: 0
		s: 0
		c: 0
	while price >= 1000000
		obj.g++
		price -= 1000000

	while price >= 10000
		obj.s++
		price -= 10000

	while price >= 100
		obj.c++
		price -= 100

	obj.i = price

	return obj


# Get merchants
dbs.wurmeconomy.all 'SELECT WURMID, OWNER FROM TRADER WHERE WURMID <> 0', (err, merchants_data) ->
	return console.error(err) if err

	# Loop over all merchants
	async.eachLimit merchants_data, 4, (merchant_data, callback) ->

		# Prepare output data object
		output = {}

		async.series
			inventory: (cb) ->
				# Get inventory ID
				dbs.wurmcreatures.get 'SELECT NAME, INVENTORYID FROM CREATURES WHERE WURMID = ?', merchant_data.WURMID, (err, creature_data) ->
					return console.error(err) if err
					
					# Add merchant name to output
					output.name = creature_data.NAME

					# Get merchant inventory
					dbs.wurmitems.all 'SELECT NAME, QUALITYLEVEL, PRICE, RARITY FROM ITEMS WHERE PARENTID = ?', creature_data.INVENTORYID, (err, item_data) ->
						return cb(err) if err
						
						# Add inventory items to output
						output.inventory = item_data.map (i) ->
							name: i.NAME
							ql: Math.floor(i.QUALITYLEVEL)
							price: parse_price(i.PRICE)

							rarity: switch i.RARITY
								when 1 then 'rare'
								when 2 then 'supreme'
								when 3 then 'fantastic'
								else no

						# Next step
						do cb

			position: (cb) ->
				# Get merchant owner's name
				dbs.wurmcreatures.get 'SELECT POSX, POSY FROM POSITION WHERE WURMID = ?', merchant_data.WURMID, (err, position_data) ->
					return cb(err) if err

					# Add position to output
					output.position =
						x: Math.round(position_data.POSX / 4)
						y: Math.round(position_data.POSY / 4)

					# Next step
					do cb

			playername: (cb) ->
				# Get merchant owner's name
				dbs.wurmplayers.get 'SELECT NAME FROM PLAYERS WHERE WURMID = ?', merchant_data.OWNER, (err, player_data) ->
					return cb(err) if err

					# Add player name to output
					output.owner = player_data.NAME

					# Next step
					do cb


		, (err, result) ->
			return callback(err) if err

			# Add output to merchants array
			merchants.push output

			# Continue with next merchant in queue
			do callback

	, (err, result) ->
		return console.error(err) if err

		# Close database connections
		dbs[db].close() for db in db_names

		# Save output to file
		fs.writeFileSync config.output_file, JSON.stringify(merchants, null, '\t')

		# Done
		console.log 'Export complete'