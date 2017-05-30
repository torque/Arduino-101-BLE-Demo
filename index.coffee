path = require 'path'
glob = require 'glob'
url = require 'url'
{app, BrowserWindow} = require 'electron'

mainWindow = null

initialize = ->
	if runningInstance( )
		return app.quit( )

	createWindow = ->
		windowOptions = {
			width: 1280,
			minWidth: 704,
			height: 360,
			minHeight: 360,
			title: app.getName( )
		}

		mainWindow = new BrowserWindow windowOptions
		# mainWindow.webContents.openDevTools( )
		mainWindow.loadURL url.format {
			pathname: path.resolve __dirname, 'index.html'
			protocol: 'file:'
			slashes: true
		}

		mainWindow.on 'closed', ->
			mainWindow = null

	app.on 'ready', createWindow

	app.on 'window-all-closed', app.quit

	app.on 'activate', ->
		if mainWindow is null
			createWindow( )

runningInstance = ->
	if process.mas
		return false

	return app.makeSingleInstance ->
		if mainWindow
			if mainWindow.isMinimized( )
				mainWindow.restore( )
			mainWindow.focus( )

initialize( )
