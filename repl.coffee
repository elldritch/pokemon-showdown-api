ShowdownClient = require 'node-ps-client'

client = new ShowdownClient 'sim.smogon.com', 8000
client.connect()
setTimeout (->
  client.joinRooms ['lobby']
  setTimeout (->
    console.log client.status
    console.log client.rooms
  ), 2000
), 2000
