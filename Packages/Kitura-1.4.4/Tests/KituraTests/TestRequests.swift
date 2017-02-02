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

import XCTest
import Foundation

@testable import Kitura
@testable import KituraNet

class TestRequests: XCTestCase {

    static var allTests: [(String, (TestRequests) -> () throws -> Void)] {
        return [
                   ("testURLParameters", testURLParameters),
                   ("testCustomMiddlewareURLParameter", testCustomMiddlewareURLParameter),
                   ("testCustomMiddlewareURLParameterWithQueryParam", testCustomMiddlewareURLParameterWithQueryParam),
                   ("testParameters", testParameters),
                   ("testParameterExit", testParameterExit)
        ]
    }

    override func setUp() {
        doSetUp()
    }

    override func tearDown() {
        doTearDown()
    }

    let router = TestRequests.setupRouter()

    func testURLParameters() {
        // Set up router for this test
        let router = Router()

        router.get("/zxcv/:p1") { request, _, next in
            let parameter = request.parameters["p1"]
            XCTAssertNotNil(parameter, "URL parameter p1 was nil")
            XCTAssertEqual(request.hostname, "localhost", "RouterRequest.hostname wasn't localhost, it was \(request.hostname)")
            XCTAssertEqual(request.port, 8090, "RouterRequest.port wasn't 8090, it was \(request.port)")
            XCTAssertEqual(request.remoteAddress, "127.0.0.1", "RouterRequest.remoteAddress wasn't 127.0.0.1, it was \(request.remoteAddress)")
            next()
        }
        router.get("/zxcv/ploni") { request, _, next in
            let parameter = request.parameters["p1"]
            XCTAssertNil(parameter, "URL parameter p1 was not nil, it's value was \(parameter!)")
            next()
        }
        router.all() { _, response, next in
            response.status(.OK).send("OK")
            next()
        }

        performServerTest(router) { expectation in
            self.performRequest("get", path: "/zxcv/ploni", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                expectation.fulfill()
            })
        }
    }

    private func runMiddlewareTest(path: String) {
        // swiftlint:disable nesting
        class CustomMiddleware: RouterMiddleware {
        // swiftlint:enable nesting
            func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) {
                let id = request.parameters["id"]
                XCTAssertNotNil(id, "URL parameter 'id' in custom middleware was nil")
                XCTAssertEqual("my_custom_id", id, "URL parameter 'id' in custom middleware was wrong")
                response.status(.OK)
                next()
            }
        }

        let router = Router()

        router.get("/user/:id", allowPartialMatch: false, middleware: CustomMiddleware())
        router.get("/user/:id") { request, response, next in
            let id = request.parameters["id"]
            XCTAssertNotNil(id, "URL parameter 'id' in middleware handler was nil")
            XCTAssertEqual("my_custom_id", id, "URL parameter 'id' in middleware handler was wrong")
            response.status(.OK)
            next()
        }

        performServerTest(router) { expectation in
            self.performRequest("get", path: path, callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                expectation.fulfill()
            })
        }
    }

    func testCustomMiddlewareURLParameter() {
        runMiddlewareTest(path: "/user/my_custom_id")
    }

    func testCustomMiddlewareURLParameterWithQueryParam() {
        runMiddlewareTest(path: "/user/my_custom_id?some_param=value")
    }

    static func setupRouter() -> Router {
        let router = Router()

        router.get("/zxcv/:p1") { request, response, next in
            response.headers["Content-Type"] = "text/html; charset=utf-8"
            let p1 = request.parameters["p1"] ?? "(nil)"
            let q = request.queryParameters["q"] ?? "(nil)"
            let u1 = request.userInfo["u1"] as? NSString ?? "(nil)"
            do {
                try response.send("<!DOCTYPE html><html><body><b>Received /zxcv</b><p><p>p1=\(p1)<p><p>q=\(q)<p><p>u1=\(u1)</body></html>\n\n").end()
            } catch {}
            next()
        }

        return router
    }

    func testParameters() {
        let router = Router()

        router.parameter("user") { request, response, value, next in
            XCTAssertNotNil(value)
            XCTAssertEqual(request.parameters["user"], value)
            XCTAssertNil(response.headers["User"])

            response.headers["User"] = value

            next()
        }

        router.parameter(["id"]) { request, response, value, next in
            XCTAssertNotNil(value)
            XCTAssertEqual(request.parameters["id"], value)
            XCTAssertNil(response.headers["User-Id"])

            response.headers["User-Id"] = value

            next()
        }

        // default test
        router.get("users/:user/:id") { request, response, next in
            XCTAssertNotNil(request.parameters["user"])
            XCTAssertNotNil(request.parameters["id"])
            response.status(.OK)
            next()
        }

        // subrouter tests
        let subrouter = router.route("posts")

        subrouter.get("/:post/:id") { request, response, next in
            XCTAssertNotNil(request.parameters["post"])
            XCTAssertNotNil(request.parameters["id"])
            response.status(.OK)
            next()
        }

        subrouter.get("/random/:id") { request, response, next in
            XCTAssertNotNil(request.parameters["id"])
            response.send(data: "success".data(using: .utf8)!)
            next()
        }

        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: "users/random/1000", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertNotNil(response!.headers["User"])
                XCTAssertNotNil(response!.headers["User-Id"])
                XCTAssertEqual(response!.headers["User"]!.first, "random")
                XCTAssertEqual(response!.headers["User-Id"]!.first, "1000")
                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("get", path: "posts/random/11000", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertNil(response!.headers["User"])
                XCTAssertNotNil(response!.headers["User-Id"])
                XCTAssertEqual(response!.headers["User-Id"]!.first, "11000")

                do {
                    let body = try response!.readString()
                    XCTAssertNotNil(body)
                    XCTAssertEqual(body!, "success")
                } catch {
                    XCTFail()
                }

                expectation.fulfill()
            })
        })
    }

    func testParameterExit() {
        let router = Router()

        router.parameter("id") { request, response, value, next in
            XCTAssertNotNil(value)
            XCTAssertEqual(request.parameters["id"], value)

            guard Int(value) != nil else {
                try response.status(.notAcceptable).end()
                return
            }

            response.headers["User-Id"] = value
            next()
        }

        // default test
        router.get("users/:user/:id") { request, response, next in
            XCTAssertNotNil(request.parameters["id"])
            response.status(.OK).send(data: "\(request.parameters["id"]!)".data(using: .utf8)!)
            next()
        }

        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: "users/random/1000", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertNotNil(response!.headers["User-Id"])
                XCTAssertEqual(response!.headers["User-Id"]!.first!, "1000")

                do {
                    let body = try response!.readString()
                    XCTAssertNotNil(body)
                    XCTAssertEqual(body!, "1000")
                } catch {
                    XCTFail()
                }

                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("get", path: "users/random/dsa", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertNil(response!.headers["User-Id"])
                XCTAssertEqual(response!.statusCode, .notAcceptable)

                do {
                    let body = try response!.readString()
                    XCTAssertNil(body)
                } catch {
                    XCTFail()
                }

                expectation.fulfill()
            })
        })
    }
}
