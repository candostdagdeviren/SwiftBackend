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
    getUserById(to: router)
    createUser(to: router)
  }

  public func add(a: Int, b: Int) -> Int {
    return a + b
  }

  private func getUserById(to router: Router) {
    router.get("/v1/user/:id", handler: { req, res, next in
      let id = req.parameters["id"]
      guard let userId = id else {
        res.status(.badRequest)
        next()
        return
      }
      self.db.getUser(with:userId) { (id, doc, error) in
        if error != nil {
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
    })
  }

  private func createUser(to router: Router) {
    router.post("/v1/user/", handler: { req, res, next in
      guard let parsedBody = req.body else {
        res.status(.badRequest)
        next()
        return
      }

      switch(parsedBody) {
        case .json(let jsonBody):
          let name = jsonBody["name"].string ?? ""
          let userId = jsonBody["id"].string ?? ""
          let user = User(name: name, id: userId)
          self.db.addNewUser(user) { (id, revision, doc, error) in
            if error != nil {
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
