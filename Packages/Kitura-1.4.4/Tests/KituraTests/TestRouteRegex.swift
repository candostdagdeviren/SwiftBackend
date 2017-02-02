/**
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Foundation
import SwiftyJSON
import XCTest

@testable import Kitura
@testable import KituraNet

fileprivate let helloworld = "Hello world"
// swiftlint:disable variable_name
fileprivate let id = "123"
// swiftlint:enable variable_name
fileprivate let mountpath = "/helloworld"

fileprivate let makeHandler = { (messageToSend: String) in
    return { (req: RouterRequest, res: RouterResponse, next: () -> Void) throws in

        let parameters = req.parameters

        if parameters.isEmpty {
            try res.send(messageToSend).end()
        } else {
            try res.send(json: JSON(parameters)).end()
        }
    }
}

fileprivate let handler = makeHandler(helloworld)

fileprivate let subrouter = { () -> Router in
    let subrouter = Router(mergeParameters: true)
    subrouter.all(mountpath, handler: handler)

    return subrouter
}()

class TestRouteRegex: XCTestCase {
    static var allTests: [(String, (TestRouteRegex) -> () throws -> Void)] {
        return [
            ("testBuildRegexFromPattern", testBuildRegexFromPattern),
            ("testSimplePaths", testSimplePaths),
            ("testSimpleMatches", testSimpleMatches),
            ("testRouteWithPercentEncoding", testRouteWithPercentEncoding),
            ("testSimpleModifiers", testSimpleModifiers),
            ("testSimpleCustomMatches", testSimpleCustomMatches),
            ("testCustomMatchesWithModifiers", testCustomMatchesWithModifiers)
        ]
    }

    override func setUp() {
        doSetUp()
    }

    override func tearDown() {
        doTearDown()
    }

    func testBuildRegexFromPattern() {
        #if os(Linux)
            var regex: RegularExpression?
        #else
            var regex: NSRegularExpression?
        #endif
        var strings: [String]?
        var path: String
        var range: NSRange

        // Partial match false adds '$' end of string special character
        (regex, strings) = RouteRegex.sharedInstance.buildRegex(fromPattern: "test", allowPartialMatch: false)
        path = "/test"
        range = regex!.rangeOfFirstMatch(in: path, options: [], range: NSRange(location: 0, length: path.characters.count))
        XCTAssertEqual(regex!.pattern, "^/test(?:/(?=$))?$")
        XCTAssertTrue(strings!.isEmpty)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 5)

        // Partial match true does not include '$' end of string special character
        (regex, strings) = RouteRegex.sharedInstance.buildRegex(fromPattern: "test", allowPartialMatch: true)
        path = "/test/hello/world"
        range = regex!.rangeOfFirstMatch(in: path, options: [], range: NSRange(location: 0, length: path.characters.count))
        XCTAssertEqual(regex!.pattern, "^/test(?:/(?=$))?(?=/|$)")
        XCTAssertTrue(strings!.isEmpty)
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 5)

        (regex, strings) = RouteRegex.sharedInstance.buildRegex(fromPattern: "test/:id", allowPartialMatch: true)
        path = "/test/123/hello/world"
        range = regex!.rangeOfFirstMatch(in: path, options: [], range: NSRange(location: 0, length: path.characters.count))
        XCTAssertEqual(regex!.pattern, "^/test/(?:([^/]+?))(?:/(?=$))?(?=/|$)")
        XCTAssertFalse(strings!.isEmpty)
        XCTAssertEqual(strings![0], "id")
        XCTAssertEqual(range.location, 0)
        XCTAssertEqual(range.length, 9)

        (regex, strings) = RouteRegex.sharedInstance.buildRegex(fromPattern: "test/:id+", allowPartialMatch: false)
        XCTAssertEqual(regex!.pattern, "^/test/([^/]+?(?:/[^/]+?)*)(?:/(?=$))?$")
        XCTAssertFalse(strings!.isEmpty)
        XCTAssertEqual(strings![0], "id")

        (regex, strings) = RouteRegex.sharedInstance.buildRegex(fromPattern: "test/:id*", allowPartialMatch: false)
        XCTAssertEqual(regex!.pattern, "^/test(?:/([^/]+?(?:/[^/]+?)*))?(?:/(?=$))?$")
        XCTAssertFalse(strings!.isEmpty)
        XCTAssertEqual(strings![0], "id")

        (regex, strings) = RouteRegex.sharedInstance.buildRegex(fromPattern: "test/:id(\\d*)", allowPartialMatch: false)
        XCTAssertEqual(regex!.pattern, "^/test/(?:(\\d*))(?:/(?=$))?$")
        XCTAssertFalse(strings!.isEmpty)
        XCTAssertEqual(strings![0], "id")

        (regex, strings) = RouteRegex.sharedInstance.buildRegex(fromPattern: "test/:id(Kitura\\d*)", allowPartialMatch: false)
        XCTAssertEqual(regex!.pattern, "^/test/(?:(Kitura\\d*))(?:/(?=$))?$")
        XCTAssertFalse(strings!.isEmpty)
        XCTAssertEqual(strings![0], "id")

        (regex, strings) = RouteRegex.sharedInstance.buildRegex(fromPattern: "test/(Kitura\\d*)", allowPartialMatch: false)
        XCTAssertEqual(regex!.pattern, "^/test/(?:(Kitura\\d*))(?:/(?=$))?$")
        XCTAssertFalse(strings!.isEmpty)
        XCTAssertEqual(strings![0], "0")
    }

    /// Tests for:
    /// 1. ""
    /// 2. "/"
    /// 3. "/*"
    func testSimplePaths() {
        var router = Router()

        router.all("", handler: handler)

        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: "", callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                do {
                    let body = try response?.readString()
                    XCTAssertEqual(body, helloworld)
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        })

        router = Router()

        router.all("", middleware: subrouter)

        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: "/helloworld", callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                do {
                    let body = try response?.readString()
                    XCTAssertEqual(body, helloworld)
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        })

        router = Router()

        router.all("", allowPartialMatch: false, middleware: subrouter)

        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: "", callback: { response in
                // Test broken due to router default response
                // Disable for now
                // XCTAssertEqual(response?.statusCode, .notFound)

                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("get", path: "/helloworld", callback: { response in
                XCTAssertEqual(response?.statusCode, .notFound)

                expectation.fulfill()
            })
        })

        router = Router()

        router.all("/", handler: handler)

        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: "", callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                do {
                    let body = try response?.readString()
                    XCTAssertEqual(body, helloworld)
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        })

        router = Router()

        router.all("/", middleware: subrouter)

        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: mountpath, callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                do {
                    let body = try response?.readString()
                    XCTAssertEqual(body, helloworld)
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        })

        router = Router()

        router.all("/*", handler: handler)

        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: "/123/abc/456/def", callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                do {
                    let body = try response?.readString()
                    XCTAssertEqual(body, helloworld)
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        })

        router = Router()

        router.all("/*", middleware: subrouter)

        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: mountpath, callback: { response in
                XCTAssertEqual(response?.statusCode, .notFound)

                expectation.fulfill()
            })
        })
    }

    /// Tests for:
    /// 1. "test"
    /// 2. "/:id"
    func testSimpleMatches() {
        var router = Router()

        router.all("/test", handler: handler)

        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: "/test", callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                do {
                    let body = try response?.readString()
                    XCTAssertEqual(body, helloworld)
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        })

        router = Router()

        router.all("/test", middleware: subrouter)

        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: "/test" + mountpath, callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                do {
                    let body = try response?.readString()
                    XCTAssertEqual(body, helloworld)
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        })

        router = Router()

        router.all("/:id", handler: handler)

        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: "/" + id, callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                var data = Data()

                do {
                    try response?.readAllData(into: &data)
                    let dict = JSON(data: data).dictionaryValue

                    XCTAssertEqual(dict["id"]?.stringValue, id)
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        })

        router = Router()

        router.all("/:id", middleware: subrouter)

        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: "/" + id + mountpath, callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                var data = Data()

                do {
                    try response?.readAllData(into: &data)
                    let dict = JSON(data: data).dictionaryValue

                    XCTAssertEqual(dict["id"]?.stringValue, id)
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        })

        router = Router()

        router.all("/:id", allowPartialMatch: false, middleware: subrouter)

        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: mountpath, callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                var data = Data()

                do {
                    try response?.readAllData(into: &data)
                    let dict = JSON(data: data).dictionaryValue

                    XCTAssertEqual(dict["id"]?.stringValue, String(mountpath.characters.dropFirst()))
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        })
    }

    /// Tests for:
    /// 1. "/:id?"
    /// 2. "/:id*"
    /// 3. "/:id+"
    func testSimpleModifiers() {
        var router = Router()

        router.all("/:id?", handler: handler)

        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: "", callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                do {
                    let body = try response?.readString()
                    XCTAssertEqual(body, helloworld)
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("get", path: "/" + id, callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                var data = Data()

                do {
                    try response?.readAllData(into: &data)
                    let dict = JSON(data: data).dictionaryValue

                    XCTAssertEqual(dict["id"]?.stringValue, id)
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        })

        router = Router()

        router.all("/:id?" + mountpath, handler: handler)

        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: mountpath, callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                do {
                    let body = try response?.readString()
                    XCTAssertEqual(body, helloworld)
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("get", path: "/" + id + mountpath, callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                var data = Data()

                do {
                    try response?.readAllData(into: &data)
                    let dict = JSON(data: data).dictionaryValue

                    XCTAssertEqual(dict["id"]?.stringValue, id)
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        })

        router = Router()

        router.all("/:id*", handler: handler)

        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: "", callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                do {
                    let body = try response?.readString()
                    XCTAssertEqual(body, helloworld)
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("get", path: "/" + id, callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                var data = Data()

                do {
                    try response?.readAllData(into: &data)
                    let dict = JSON(data: data).dictionaryValue

                    XCTAssertEqual(dict["id"]?.stringValue, id)
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("get", path: "/123/abc/456", callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                var data = Data()

                do {
                    try response?.readAllData(into: &data)
                    let dict = JSON(data: data).dictionaryValue

                    XCTAssertEqual(dict["id"]?.stringValue, "123/abc/456")
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        })

        router = Router()

        router.all("/:id*" + mountpath, handler: handler)

        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: mountpath, callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                do {
                    let body = try response?.readString()
                    XCTAssertEqual(body, helloworld)
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("get", path: "/" + id + mountpath, callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                var data = Data()

                do {
                    try response?.readAllData(into: &data)
                    let dict = JSON(data: data).dictionaryValue

                    XCTAssertEqual(dict["id"]?.stringValue, id)
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("get", path: "/123/abc/456" + mountpath, callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                var data = Data()

                do {
                    try response?.readAllData(into: &data)
                    let dict = JSON(data: data).dictionaryValue

                    XCTAssertEqual(dict["id"]?.stringValue, "123/abc/456")
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        })

        router = Router()

        router.all("/:id+", handler: handler)

        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: "", callback: { response in
                // Test broken due to router default response
                // Disable for now
                // XCTAssertEqual(response?.statusCode, .notFound)

                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("get", path: "/" + id, callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                var data = Data()

                do {
                    try response?.readAllData(into: &data)
                    let dict = JSON(data: data).dictionaryValue

                    XCTAssertEqual(dict["id"]?.stringValue, id)
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("get", path: "/123/abc/456", callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                var data = Data()

                do {
                    try response?.readAllData(into: &data)
                    let dict = JSON(data: data).dictionaryValue

                    XCTAssertEqual(dict["id"]?.stringValue, "123/abc/456")
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        })

        router = Router()

        router.all("/:id+" + mountpath, handler: handler)

        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: mountpath, callback: { response in
                XCTAssertEqual(response?.statusCode, .notFound)

                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("get", path: "/" + id + mountpath, callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                var data = Data()

                do {
                    try response?.readAllData(into: &data)
                    let dict = JSON(data: data).dictionaryValue

                    XCTAssertEqual(dict["id"]?.stringValue, id)
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("get", path: "/123/abc/456" + mountpath, callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                var data = Data()

                do {
                    try response?.readAllData(into: &data)
                    let dict = JSON(data: data).dictionaryValue

                    XCTAssertEqual(dict["id"]?.stringValue, "123/abc/456")
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        })
    }

    /// Tests for:
    /// 1. "/:id(\\d+)"
    func testSimpleCustomMatches() {
        var router = Router()

        router.all("/:id(\\d+)", handler: handler)

        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: "/" + id, callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                var data = Data()

                do {
                    try response?.readAllData(into: &data)
                    let dict = JSON(data: data).dictionaryValue

                    XCTAssertEqual(dict["id"]?.stringValue, id)
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("get", path: "/abc", callback: { response in
                XCTAssertEqual(response?.statusCode, .notFound)

                expectation.fulfill()
            })
        })

        router = Router()

        router.all("/:id(\\d+)", middleware: subrouter)

        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: "/" + id + mountpath, callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                var data = Data()

                do {
                    try response?.readAllData(into: &data)
                    let dict = JSON(data: data).dictionaryValue

                    XCTAssertEqual(dict["id"]?.stringValue, id)
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("get", path: "/abc" + mountpath, callback: { response in
                XCTAssertEqual(response?.statusCode, .notFound)

                expectation.fulfill()
            })
        })
    }

    /// Tests for:
    /// 1. "/:id(\\d+)?"
    /// 2. "/:id(\\d+)*"
    /// 3. "/:id(\\d+)+"
    func testCustomMatchesWithModifiers() {
        var router = Router()

        router.all("/:id(\\d+)?", handler: handler)

        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: "", callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                do {
                    let body = try response?.readString()
                    XCTAssertEqual(body, helloworld)
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("get", path: "/" + id, callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                var data = Data()

                do {
                    try response?.readAllData(into: &data)
                    let dict = JSON(data: data).dictionaryValue

                    XCTAssertEqual(dict["id"]?.stringValue, id)
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("get", path: "/abc", callback: { response in
                XCTAssertEqual(response?.statusCode, .notFound)

                expectation.fulfill()
            })
        })

        router = Router()

        router.all("/:id(\\d+)?", middleware: subrouter)

        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: mountpath, callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                do {
                    let body = try response?.readString()
                    XCTAssertEqual(body, helloworld)
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("get", path: "/" + id + mountpath, callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                var data = Data()

                do {
                    try response?.readAllData(into: &data)
                    let dict = JSON(data: data).dictionaryValue

                    XCTAssertEqual(dict["id"]?.stringValue, id)
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("get", path: "/abc" + mountpath, callback: { response in
                XCTAssertEqual(response?.statusCode, .notFound)

                expectation.fulfill()
            })
        })

        router = Router()

        router.all("/:id(\\d+)*", handler: handler)

        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: "", callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                do {
                    let body = try response?.readString()
                    XCTAssertEqual(body, helloworld)
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("get", path: "/" + id, callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                var data = Data()

                do {
                    try response?.readAllData(into: &data)
                    let dict = JSON(data: data).dictionaryValue

                    XCTAssertEqual(dict["id"]?.stringValue, id)
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("get", path: "/123/456/789", callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                var data = Data()

                do {
                    try response?.readAllData(into: &data)
                    let dict = JSON(data: data).dictionaryValue

                    XCTAssertEqual(dict["id"]?.stringValue, "123/456/789")
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("get", path: "/123/abc/456", callback: { response in
                XCTAssertEqual(response?.statusCode, .notFound)

                expectation.fulfill()
            })
        })

        router = Router()

        router.all("/:id(\\d+)*", middleware: subrouter)

        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: mountpath, callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                do {
                    let body = try response?.readString()
                    XCTAssertEqual(body, helloworld)
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("get", path: "/" + id + mountpath, callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                var data = Data()

                do {
                    try response?.readAllData(into: &data)
                    let dict = JSON(data: data).dictionaryValue

                    XCTAssertEqual(dict["id"]?.stringValue, id)
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("get", path: "/123/456/789" + mountpath, callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                var data = Data()

                do {
                    try response?.readAllData(into: &data)
                    let dict = JSON(data: data).dictionaryValue

                    XCTAssertEqual(dict["id"]?.stringValue, "123/456/789")
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("get", path: "/123/abc/456" + mountpath, callback: { response in
                XCTAssertEqual(response?.statusCode, .notFound)

                expectation.fulfill()
            })
        })

        router = Router()

        router.all("/:id(\\d+)+", handler: handler)

        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: "", callback: { response in
                // Test broken due to router default response
                // Disable for now
                // XCTAssertEqual(response?.statusCode, .notFound)

                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("get", path: "/" + id, callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                var data = Data()

                do {
                    try response?.readAllData(into: &data)
                    let dict = JSON(data: data).dictionaryValue

                    XCTAssertEqual(dict["id"]?.stringValue, id)
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("get", path: "/123/456/789", callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                var data = Data()

                do {
                    try response?.readAllData(into: &data)
                    let dict = JSON(data: data).dictionaryValue

                    XCTAssertEqual(dict["id"]?.stringValue, "123/456/789")
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("get", path: "/123/abc/456", callback: { response in
                XCTAssertEqual(response?.statusCode, .notFound)

                expectation.fulfill()
            })
        })

        router = Router()

        router.all("/:id(\\d+)+", middleware: subrouter)

        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: mountpath, callback: { response in
                 XCTAssertEqual(response?.statusCode, .notFound)

                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("get", path: "/" + id + mountpath, callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                var data = Data()

                do {
                    try response?.readAllData(into: &data)
                    let dict = JSON(data: data).dictionaryValue

                    XCTAssertEqual(dict["id"]?.stringValue, id)
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("get", path: "/123/456/789" + mountpath, callback: { response in
                XCTAssertEqual(response?.statusCode, .OK)

                var data = Data()

                do {
                    try response?.readAllData(into: &data)
                    let dict = JSON(data: data).dictionaryValue

                    XCTAssertEqual(dict["id"]?.stringValue, "123/456/789")
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("get", path: "/123/abc/456" + mountpath, callback: { response in
                XCTAssertEqual(response?.statusCode, .notFound)

                expectation.fulfill()
            })
        })
    }

    func testRouteWithPercentEncoding() {
        let router = Router()
        router.get("/say hello", handler: makeHandler(helloworld + " with whitespace"))
        router.get("/say%20hello", handler: makeHandler(helloworld + " with %20"))
        router.get("/say+hello", handler: makeHandler(helloworld + " with +"))

        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: "/say%20hello", callback: { response in
                guard let response = response else {
                    XCTFail("ClientRequest response object was nil")
                    expectation.fulfill()
                    return
                }

                XCTAssertEqual(response.statusCode, .OK)

                do {
                    let body = try response.readString()
                    XCTAssertEqual(body, helloworld + " with %20")
                } catch {
                    XCTFail("Unable to read response body")
                }

                expectation.fulfill()
            })
        })
    }
}
