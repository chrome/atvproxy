fs       = require('fs')
director = require('director')
coffee   = require('coffee-script')
url      = require('url')
CONFIG   = require('config').atv
provider = require("./providers/#{CONFIG.provider}/provider")

getJSFileContent = (name) ->
  console.log "assets/js/#{name}.coffee"
  if fs.existsSync("assets/js/#{name}.js")
    fs.readFileSync("assets/js/#{name}.js")
  else if fs.existsSync("assets/js/#{name}.coffee")
    coffeeStr = fs.readFileSync("assets/js/#{name}.coffee").toString()
    coffee.compile(coffeeStr, bare: true)
  else
    '404'


router = new director.http.Router()

# Serve profile file for easier delivery to AppleTV
router.get '/profile.cert', ->
  @res.writeHead 200, 'text/plain'
  @res.write fs.readFileSync(CONFIG.atv_profile)
  @res.end()

# If provider requires signin, this method will handle it
router.post '/signin', ->
  provider.signin {login: @req.body.login, password: @req.body.password}, (result, session) =>
    @res.writeHead 200, 'text/plain'
    console.log 'answer:', result, session
    if result
      @res.write session
      @res.end()
    else
      @res.end()

# Serve static XML pages
router.get '/page/static/:name', (name) ->
  unless fs.existsSync(fileName = "providers/#{CONFIG.provider}/templates/#{name}.xml")
    unless fs.existsSync(fileName = "assets/xml/#{name}.xml")
      @res.writeHead 404
      @res.end()
      return
  @res.writeHead 200
  @res.write fs.readFileSync(fileName)
  @res.end()

# Serve XML templates
router.get '/page/:page', (page) ->
  unless /^[\w_]+$/.exec(page)
    @res.writeHead 403
    @res.end("Wrong filename")
  urlData = url.parse(@req.url, true)
  provider.renderPage urlData.query, page, (content) =>
    @res.writeHead 200
    @res.end(content)

# Serve JS files, compile coffee if needed
router.get '/js/:name', (name) ->
  unless /^[\w_]+$/.exec(name)
    @res.writeHead 403
    @res.end("Wrong filename")
  @res.writeHead 200, { 'Content-Type': 'text/javascript' }
  @res.write getJSFileContent(name)
  @res.end()

# Serve application.js file
router.get /.*application.js/, ->
  @res.writeHead 200, { 'Content-Type': 'text/javascript' }
  @res.write getJSFileContent('application')
  @res.end()

# Log query
router.get '/log', ->
  urlData = url.parse(@req.url, true)
  console.log "* #{urlData.query.message}"
  @res.writeHead 200, { 'Content-Type': 'text/plain' }
  @res.end()


module.exports = router