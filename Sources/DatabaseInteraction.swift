import Foundation
import CouchDB
import SwiftyJSON

public struct DatabaseInteraction {
  var db: Database
  public init(db: Database) {
    self.db = db
  }

  func addNewUser(_ user: User, handler: @escaping (String?, String?, JSON?, NSError?) -> ()) {
    let userDict: [String: Any] = [
      "name": user.name,
      "id": user.id
    ]

    let userJSON = JSON(userDict)

    db.create(userJSON) {  (id, revision, doc, error) in
      if let error = error {
        handler(nil, nil, nil, error)
        return
      } else {
        handler(id, revision, doc, nil)
      }
    }
  }
}
