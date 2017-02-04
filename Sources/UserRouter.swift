import Foundation
import Kitura
import CouchDB
import SwiftyJSON

public class UserRouter {
  var db: DatabaseInteraction
  public init(db: DatabaseInteraction) {
    self.db = db
  }

  public func bindAll(to router: Router) {
    addGetUserById(to: router)
    addCreateUser(to: router)
  }

  private func addGetUserById(to router: Router) {
    router.get("/v1/user/:id", handler: { req, res, next in
      let id = req.parameters["id"]
      guard let userId = id else {
        res.status(.badRequest)
        next()
        return
      }
      let users: [String: Any] = [userId: ["user": "", "id": userId]]
      res.send(json: JSON(users))
      next()
    })
  }

  private func addCreateUser(to router: Router) {
    router.post("/v1/user/", handler: { req, res, next in
      guard let parsedBody = req.body else {
        res.status(.badRequest)
        next()
        return
      }

      switch(parsedBody) {
        case .json(let jsonBody):
          let name = jsonBody["name"].string ?? ""
          let user = User(name: name, id: "\(name.characters.count)")
          self.db.addNewUser(user) { (id, revision, doc, error) in
            if let error = error {
              res.status(.internalServerError)
              next()
            } else {
              res.status(.OK)
              if let doc = doc {
                res.send(json: doc)
              } else {
                res.send("something is wrong")
              }
              next()
            }
          }
        default:
          next()
      }
    })
  }
}