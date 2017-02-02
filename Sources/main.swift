import Kitura
import HeliumLogger

HeliumLogger.use()

let router = Router()

router.get("/") { request, response, next in
  response.send("Hello world")
  next()
}

Kitura.addHTTPServer(onPort: 8090, with: router)

Kitura.run()
