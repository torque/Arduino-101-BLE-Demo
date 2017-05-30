noble = require 'noble'

# All UUIDs need to be non-hyphenated lower-case because that's what noble's
# callbacks give.
MyCustomService = 'beef000000000000000000000000acce'
Characteristics = [
	'beef000100000000000000000000acce'
	'beef00010000000000000000000001ed'
]

noble.on 'stateChange', ( state ) ->
	console.log 'bt state changed to ' + state
	if state is 'poweredOn'
		# noble.startScanning( )
		noble.startScanning [MyCustomService], false
	else
		noble.stopScanning( )

noble.on 'scanStart', ->
	console.log 'scan started'

noble.on 'scanStop', ->
	console.log 'scan stopped'

charList = { }
ledOn = undefined

imuElements = [
	document.querySelector '#IMU .values .x'
	document.querySelector '#IMU .values .y'
	document.querySelector '#IMU .values .z'
]

ledView = document.querySelector '#LEDBUTTON'
ledViewClick = undefined
ledStateView = ledView.querySelector '.state'

noble.on 'discover', ( peripheral ) ->
	console.log 'discovered ', peripheral
	noble.stopScanning( )
	connectionFuckery = setTimeout =>
		console.log 'trying to connect...'
		peripheral.disconnect( )
		peripheral.connect ( err ) ->
			if err
				console.log 'connection error: ', err
				return

			connectionName = document.querySelector '#connection .name'
			connectionName.innerText = peripheral.advertisement.localName

			peripheral.once 'disconnect', ->
				charList = { }
				connectionName.innerText = 'nothing'
				if ledViewClick?
					console.log 'removing led view click'
					ledView.removeEventListener 'click', ledViewClick
					ledViewClick = undefined
				changeLEDState undefined
				for el in imuElements
					el.innerText = '0'
				console.log 'peripheral disconnected.'
				noble.startScanning [MyCustomService], false

			peripheral.discoverServices [MyCustomService], ( err, services ) ->
				console.log "Discovered services: ", services
				services[0]?.discoverCharacteristics Characteristics, ( err, chars ) ->
					console.log 'Found characteristics: ', chars
					for char in chars
						switch char.uuid
							when Characteristics[0]
								charList.accel = char
							when Characteristics[1]
								charList.led = char

					if charList.accel?
						charList.accel.subscribe ( err ) ->
							if err
								console.log 'accel subscription error'
							else
								console.log 'subscribed to acceleration'
						charList.accel.on 'data', ( data, isNotification ) ->
							[x, y, z] = (imuElements[i].innerText = num for num, i in data.toString( ).split ',')

					if charList.led?
						charList.led.read ( err, data ) ->
							if err
								console.log 'led data read error'
								return
							changeLEDState 1 == data.readUInt8 0
							console.log 'adding click handler'
							ledViewClick = ledView.addEventListener 'click', ( ev ) ->
								newState = not ledOn
								buf = new Buffer 1
								buf.writeUInt8 (if newState then 1 else 0), 0
								charList.led.write buf, false, ( err ) ->
									if err
										console.log 'led write error'
									changeLEDState newState
	, 100

changeLEDState = ( newState ) ->
	ledOn = newState
	if newState is true
		ledView.style.borderBottomColor = '#99CC99'
		ledStateView.innerText = 'ON'
	else if newState is false
		ledView.style.borderBottomColor = '#393939'
		ledStateView.innerText = 'OFF'
	else if newState is undefined
		ledView.style.borderBottomColor = '#F2777A'
		ledStateView.innerText = '?'
