# openssl req -new -nodes -newkey rsa:2048 -out bloomberg.pem -keyout bloomberg.key -x509 -days 7300 -subj "/C=US/CN=mobapi.bloomberg.com"
# openssl x509 -in bloomberg.pem -outform der -out bloomberg.cer && cat bloomberg.key >> bloomberg.pem

fs       = require('fs')
http     = require('http')
https    = require('https')
CONFIG   = require('config').atv

router   = require('./router')

class ATVServer
  sslOptions:
    key:  fs.readFileSync(CONFIG.ssl_key)
    cert: fs.readFileSync(CONFIG.ssl_cert)

  constructor: ->
    http.createServer(@handler).listen(80)
    https.createServer(@sslOptions, @handler).listen(443)

  handler: (request, response) =>
    console.log "- request: #{unescape(request.url)}"

    request.chunks = []
    request.on 'data', (chunk) -> request.chunks.push(chunk.toString())

    router.dispatch request, response, (err) ->
      if (err)
        response.writeHead(404)
        response.end()

module.exports = ATVServer