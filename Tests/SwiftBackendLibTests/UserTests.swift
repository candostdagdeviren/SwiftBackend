//
//  UserTests.swift
//  SwiftBackend
//
//  Created by Candost Dagdeviren on 12/03/2017.
//
//

import XCTest
import CouchDB
@testable import BackendLib

class UserTests: XCTestCase {
    var router: UserRouter!
    static var allTests : [(String, (UserTests) -> () throws -> Void)] {
        return [
                ("testAsserts", testAsserts)
            ]
        }
    override func setUp() {
        super.setUp()

        let connProperties = ConnectionProperties(
            host: "127.0.0.1",  // httpd address
            port: 5984,         // httpd port
            secured: false,     // https or http
            username: "candost",      // admin username
            password: "1234"       // admin password
        )

        let db = Database(connProperties: connProperties, dbName: "kitura_test_db")
        let databaseInteraction = DatabaseInteraction(db: db)
        router = UserRouter(db: databaseInteraction)

    }
    func testAsserts() {

        XCTAssertEqual(router.add(a: 5, b: 6), 11, "Message shown when assert fails")
        // XCTAssertNotNil(user.name, "Message shown when assert fails")
        // XCTFail("Message always shows since this always fails")
        // Other Asserts can be used as well
    }
}
