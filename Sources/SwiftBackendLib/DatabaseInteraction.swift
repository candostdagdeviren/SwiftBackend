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
      "username": user.name,
      "userId": user.id
    ]

    let userJSON = JSON(userDict)

    db.create(userJSON) {  (id, revision, doc, error) in
      if let error = error {
        print("oops something went wrong error: \(error)")
        handler(nil, nil, nil, error)
        return
      } else {
        handler(id, revision, doc, nil)
      }
    }
  }

  func getUser(with id: String, handler: @escaping (String?, JSON?, NSError?) -> ()) {
    db.retrieve(id as String, callback: { (document: JSON?, error: NSError?) in
        if let error = error {
            print("Oops something went wrong; could not read document.")
            print("Error: \(error.localizedDescription) Code: \(error.code)")
            handler(id, nil, error)
        } else {
            print(">> Successfully read the following JSON document with ID " +
                "\(id) from CouchDB:\n\t\(document)")
            handler(id, document, nil)
        }
    })
  }
}
