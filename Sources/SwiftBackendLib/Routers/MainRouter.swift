import Foundation
import Kitura

public class MainRouter {
  public let router = Router()
  var db: DatabaseInteraction

  public init(db: DatabaseInteraction) {
    self.db = db
    router.get("/status") { req, res, callNextHandler in
      res.status(.OK).send("Everything is working")
      callNextHandler()
    }
    router.all("*", middleware: BodyParser())

    self.routeToUser()
  }

  func routeToUser() {
    let user = UserRouter(db: self.db)
    user.bindAll(to: self.router)
  }
}
