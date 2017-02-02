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
import SwiftyJSON

@testable import Kitura
@testable import KituraNet

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

class TestResponse: XCTestCase {

    static var allTests: [(String, (TestResponse) -> () throws -> Void)] {
        return [
            ("testSimpleResponse", testSimpleResponse),
            ("testPostRequest", testPostRequest),
            ("testPostRequestTheHardWay", testPostRequestTheHardWay),
            ("testPostJSONRequest", testPostRequest),
            ("testPostRequestWithDoubleBodyParser", testPostRequestWithDoubleBodyParser),
            ("testPostRequestUrlEncoded", testPostRequestUrlEncoded),
            ("testMultipartFormParsing", testMultipartFormParsing),
            ("testRawDataPost", testRawDataPost),
            ("testParameters", testParameters),
            ("testParametersPercent20InPath", testParametersPercent20InPath),
            ("testParametersPlusInPath", testParametersPlusInPath),
            ("testParametersPercent20InQuery", testParametersPercent20InQuery),
            ("testParametersPlusInQuery", testParametersPlusInQuery),
            ("testParametersPercentageEncoding", testParametersPercentageEncoding),
            ("testRedirect", testRedirect),
            ("testErrorHandler", testErrorHandler),
            ("testHeaderModifiers", testHeaderModifiers),
            ("testRouteFunc", testRouteFunc),
            ("testAcceptTypes", testAcceptTypes),
            ("testAcceptEncodingTypes", testAcceptEncodingTypes),
            ("testFormat", testFormat),
            ("testLink", testLink),
            ("testSubdomains", testSubdomains),
            ("testJsonp", testJsonp),
            ("testLifecycle", testLifecycle),
            ("testSend", testSend)
        ]
    }

    override func setUp() {
        doSetUp()
    }

    override func tearDown() {
        doTearDown()
    }

    let router = TestResponse.setupRouter()

    func testSimpleResponse() {
    	performServerTest(router) { expectation in
            self.performRequest("get", path:"/qwer", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response!.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(response!.statusCode)")
                XCTAssertNotNil(response!.headers["Date"], "There was No Date header in the response")
                //XCTAssertEqual(response!.method, "GET", "The request wasn't recognized as a get")
                do {
                    let body = try response!.readString()
                    XCTAssertEqual(body!, "<!DOCTYPE html><html><body><b>Received</b></body></html>\n\n")
                } catch {
                    XCTFail("No response body")
                }
                expectation.fulfill()
            })
        }
    }

    func testPostRequest() {
    	performServerTest(router) { expectation in
            self.performRequest("post", path: "/bodytest", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                //XCTAssertEqual(response!.method, "POST", "The request wasn't recognized as a post")
                XCTAssertNotNil(response!.headers["Date"], "There was No Date header in the response")
                do {
                    let body = try response!.readString()
                    XCTAssertEqual(body!, "<!DOCTYPE html><html><body><b>Received text body: </b>plover\nxyzzy\n</body></html>\n\n")
                } catch {
                    XCTFail("No response body")
                }
                expectation.fulfill()
            }) {req in
                req.write(from: "plover\n")
                req.write(from: "xyzzy\n")
            }
        }
    }

    func testPostRequestTheHardWay() {
        performServerTest(router) { expectation in
            self.performRequest("post", path: "/bodytesthardway", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                do {
                    let body = try response!.readString()
                    XCTAssertEqual(body!, "Read 13 bytes")
                } catch {
                    XCTFail("No response body")
                }
                expectation.fulfill()
            }) {req in
                req.write(from: "plover\n")
                req.write(from: "xyzzy\n")
            }
        }
    }

    func testPostJSONRequest() {
        let jsonToTest = JSON(["foo": "bar"])

        performServerTest(router) { expectation in
            self.performRequest("post", path: "/bodytest", callback: { response in
                guard let response = response else {
                    XCTFail("ClientRequest response object was nil")
                    expectation.fulfill()
                    return
                }
                XCTAssertNotNil(response.headers["Date"], "There was No Date header in the response")
                do {
                   guard let body = try response.readString() else {
                       XCTFail("body in response is nil")
                       expectation.fulfill()
                       return
                    }
                   let returnedJSON = JSON.parse(string: body)
                   XCTAssertEqual(returnedJSON, jsonToTest)
                } catch {
                    XCTFail("No response body")
                }
                expectation.fulfill()
            }, headers: ["Content-Type": "application/json"]) { req in
            do {
                let jsonData = try jsonToTest.rawData()
                req.write(from: jsonData)
                req.write(from: "\n")
            } catch {
                XCTFail("caught error \(error)")
            }
           }
        }
    }

    func testPostRequestWithDoubleBodyParser() {
        performServerTest(router) { expectation in
            self.performRequest("post", path: "/doublebodytest", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                //XCTAssertEqual(response!.method, "POST", "The request wasn't recognized as a post")
                XCTAssertNotNil(response!.headers["Date"], "There was No Date header in the response")
                do {
                    let body = try response!.readString()
                    XCTAssertEqual(body!, "<!DOCTYPE html><html><body><b>Received text body: </b>plover\nxyzzy\n</body></html>\n\n")
                } catch {
                    XCTFail("No response body")
                }
                expectation.fulfill()
            }) {req in
                req.write(from: "plover\n")
                req.write(from: "xyzzy\n")
            }
        }
    }

    func testPostRequestUrlEncoded() {
        performServerTest(router) { expectation in
            self.performRequest("post", path: "/bodytest", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertNotNil(response!.headers["Date"], "There was No Date header in the response")
                do {
                    let body = try response!.readString()
                    XCTAssertEqual(body!, "<!DOCTYPE html><html><body><b>Received URL encoded body</b><br> [\"swift\": \"rocks\"] </body></html>\n\n")
                } catch {
                    XCTFail("No response body")
                }
                expectation.fulfill()
            }) {req in
                req.headers["Content-Type"] = "application/x-www-form-urlencoded"
                req.write(from: "swift=rocks")
            }
        }
        // repeat the same test with a Content-Type parameter of charset=UTF-8
        performServerTest(router) { expectation in
            self.performRequest("post", path: "/bodytest", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertNotNil(response!.headers["Date"], "There was No Date header in the response")
                do {
                    let body = try response!.readString()
                    XCTAssertEqual(body!, "<!DOCTYPE html><html><body><b>Received URL encoded body</b><br> [\"swift\": \"rocks\"] </body></html>\n\n")
                } catch {
                    XCTFail("No response body")
                }
                expectation.fulfill()
            }) {req in
                req.headers["Content-Type"] = "application/x-www-form-urlencoded; charset=UTF-8"
                req.write(from: "swift=rocks")
            }
        }
    }

    func dataComponentsTest(_ searchString: String, separator: String) {
        let stringFind = searchString.components(separatedBy: separator)

        // test Data.components extension
        var separatorData = Data()
        if let data = separator.data(using: .utf8) {
            separatorData = data
        }
        var searchData = Data()
        if let data = searchString.data(using: .utf8) {
            searchData = data
        }
        let dataFind = searchData.components(separatedBy: separatorData)
        // ensure we get the same sized array back
        XCTAssert(dataFind.count == stringFind.count)
        // test to ensure the strings are equal
        for i in 0 ..< stringFind.count {
            let dataString = String(data: dataFind[i], encoding: .utf8)
            XCTAssertEqual(stringFind[i], dataString)
        }
    }

    func testMultipartFormParsing() {

        // ensure NSData.components works just like String.components
        dataComponentsTest("AxAyAzA", separator: "A")
        dataComponentsTest("HelloWorld", separator: "World")
        dataComponentsTest("ababababababababababa", separator: "b")
        dataComponentsTest("Invalid separator", separator: "")
        dataComponentsTest("", separator: "Invalid search string")

        performServerTest(router) { expectation in
            self.performRequest("post", path: "/multibodytest", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                do {
                    let body = try response!.readString()
                    XCTAssertEqual(body!, "text  text(\"text default\") file1 a.txt text(\"Content of a.txt.\") file2 a.html text(\"<!DOCTYPE html><title>Content of a.html.</title>\") ")
                } catch {
                    XCTFail("No response body")
                }
                expectation.fulfill()
            }) {req in
                req.headers["Content-Type"] = "multipart/form-data; boundary=---------------------------9051914041544843365972754266"
                req.write(from: "-----------------------------9051914041544843365972754266\r\n" +
                    "Content-Disposition: form-data; name=\"text\"\r\n\r\n" +
                    "text default\r\n" +
                    "-----------------------------9051914041544843365972754266\r\n" +
                    "Content-Disposition: form-data; name=\"file1\"; filename=\"a.txt\"\r\n" +
                    "Content-Type: text/plain\r\n\r\n" +
                    "Content of a.txt.\r\n" +
                    "-----------------------------9051914041544843365972754266\r\n" +
                    "Content-Disposition: form-data; name=\"file2\"; filename=\"a.html\"\r\n" +
                    "Content-Type: text/html\r\n\r\n" +
                    "<!DOCTYPE html><title>Content of a.html.</title>\r\n" +
                    "-----------------------------9051914041544843365972754266--")
            }
        }
        // repeat the test with blank headers (allowed as per section 5.1 of RFC 2046) and custom headers that should be skiped
        performServerTest(router) { expectation in
            self.performRequest("post", path: "/multibodytest", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                do {
                    let body = try response!.readString()
                    XCTAssertEqual(body!, "  text(\"text default\") file1 a.txt text(\"Content of a.txt.\") file2 a.html text(\"<!DOCTYPE html><title>Content of a.html.</title>\") ")
                } catch {
                    XCTFail("No response body")
                }
                expectation.fulfill()
            }) {req in
                req.headers["Content-Type"] = "multipart/form-data; boundary=---------------------------9051914041544843365972754266"
                req.write(from: "This is a preamble and should be ignored" +
                    "\r\n-----------------------------9051914041544843365972754266\r\n" +
                    "\r\n" +
                    "text default\r\n" +
                    "-----------------------------9051914041544843365972754266\r\n" +
                    "Content-Disposition: form-data; name=\"file1\"; filename=\"a.txt\"\r\n" +
                    "Content-Type: text/plain\r\n" +
                    "X-Arbitrary-Header: we should ignore this\r\n\r\n" +
                    "Content of a.txt.\r\n" +
                    "-----------------------------9051914041544843365972754266\r\n" +
                    "Content-Disposition: form-data; name=\"file2\"; filename=\"a.html\"\r\n" +
                    "Content-Type: text/html\r\n" +
                    "X-Arbitrary-Header2: we should ignore this too\r\n\r\n" +
                    "<!DOCTYPE html><title>Content of a.html.</title>\r\n" +
                    "-----------------------------9051914041544843365972754266--")
            }
        }
        // One more test to ensure we handle Content-Type with a parameter after the bounadary
        performServerTest(router) { expectation in
            self.performRequest("post", path: "/multibodytest", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                do {
                    let body = try response!.readString()
                    XCTAssertEqual(body!, "  text(\"text default\") ")
                } catch {
                    XCTFail("No response body")
                }
                expectation.fulfill()
            }) {req in
                req.headers["Content-Type"] = "multipart/form-data; boundary=ZZZY70gRGgDPOiChzXcmW3psiU7HlnC; charset=US-ASCII"
                req.write(from: "Preamble" +
                    "\r\n--ZZZY70gRGgDPOiChzXcmW3psiU7HlnC\r\n" +
                    "\r\n" +
                    "text default\r\n" +
                    "--ZZZY70gRGgDPOiChzXcmW3psiU7HlnC--")
            }
        }

        // Negative test case - valid boundary but an invalid body
        performServerTest(router) { expectation in
            self.performRequest("post", path: "/multibodytest", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                do {
                    let body = try response!.readString()
                    XCTAssertEqual(body!, "Cannot POST /multibodytest.")
                } catch {
                    XCTFail("No response body")
                }
                expectation.fulfill()
            }) {req in
                req.headers["Content-Type"] = "multipart/form-data; boundary=ABDCEFG"
                req.write(from: "This does not contain any valid boundary")
            }
        }

    }

    func testRawDataPost() {
        performServerTest(router) { expectation in
            self.performRequest("post",
                                path: "/bodytest",
                                callback: {
                                    (response) in
                                    guard let response = response else {
                                        XCTFail("Client response was nil on raw data post.")
                                        expectation.fulfill()
                                        return
                                    }

                                    XCTAssertNotNil(response.headers["Date"], "There was No Date header in the response")
                                    do {
                                        let responseString = try response.readString()
                                        XCTAssertEqual("length: 2048", responseString)
                                    } catch {
                                        XCTFail("Failed posting raw data")
                                    }
                                    expectation.fulfill()
            },
                                headers: ["Content-Type": "application/octet-stream"],
                                requestModifier: {
                                    (request) in
                                    let length = 2048
                                    let bytes = [UInt32](repeating: 0, count: length).map { _ in 0 }
                                    let randomData = Data(bytes: bytes, count: length)
                                    request.write(from: randomData)
            })
        }
    }

    private func runTestParameters(pathParameter: String, queryParameter: String,
                                   expectedReturnedPathParameter: String? = nil,
                                   expectedReturnedQueryParameter: String? = nil) {
        let expectedReturnedPathParameter = expectedReturnedPathParameter ?? pathParameter
        let expectedReturnedQueryParameter = expectedReturnedQueryParameter ?? queryParameter
        performServerTest(router) { expectation in
            self.performRequest("get", path: "/zxcv/\(pathParameter)?q=\(queryParameter)",
                callback: { response in
                guard let response = response else {
                    XCTFail("ClientRequest response object was nil")
                    expectation.fulfill()
                    return
                }

                do {
                    let body = try response.readString()
                    XCTAssertEqual(body, "<!DOCTYPE html><html><body><b>Received /zxcv</b><p>" +
                        "<p>p1=\(expectedReturnedPathParameter)<p>" +
                        "<p>q=\(expectedReturnedQueryParameter)<p>" +
                        "<p>u1=Ploni Almoni</body></html>\n\n")
                } catch {
                    XCTFail("No response body")
                }
                expectation.fulfill()
            })
        }
    }

    func testParameters() {
        runTestParameters(pathParameter: "test1", queryParameter: "test2")
    }

    func testParametersPercent20InPath() {
        runTestParameters(pathParameter: "John%20Doe", queryParameter: "test2",
                          expectedReturnedPathParameter: "John Doe")
    }

    func testParametersPlusInPath() {
        runTestParameters(pathParameter: "John+Doe", queryParameter: "test2",
                          expectedReturnedPathParameter: "John+Doe")
    }

    func testParametersPercent20InQuery() {
        runTestParameters(pathParameter: "test1", queryParameter: "John%20Doe",
                          expectedReturnedQueryParameter: "John Doe")
    }

    func testParametersPlusInQuery() {
        runTestParameters(pathParameter: "test1", queryParameter: "John+Doe",
                          expectedReturnedQueryParameter: "John Doe")
    }

    func testParametersPercentageEncoding() {
        runTestParameters(pathParameter: "John%40Doe", queryParameter: "Jane%2BRoe",
                          expectedReturnedPathParameter: "John@Doe",
                          expectedReturnedQueryParameter: "Jane+Roe")
    }

    func testRedirect() {
        performServerTest(router) { expectation in
            self.performRequest("get", path: "/redir", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                do {
                    let body = try response!.readString()
                    XCTAssertNotNil(body!.range(of: "ibm"), "response does not contain IBM")
                } catch {
                    XCTFail("No response body")
                }
                expectation.fulfill()
            })
        }
    }

    func testErrorHandler() {
        performServerTest(router) { expectation in
            self.performRequest("get", path: "/error", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                do {
                    let body = try response!.readString()
                    let errorDescription = "foo is nil"
                    XCTAssertEqual(body!, "Caught the error: \(errorDescription)")
                } catch {
                    XCTFail("No response body")
                }
                expectation.fulfill()
            })
        }
    }

    func testRouteFunc() {
        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: "/route", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response!.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(response!.statusCode)")
                do {
                    let body = try response!.readString()
                    XCTAssertEqual(body!, "get 1\nget 2\n")
                } catch {
                    XCTFail("No response body")
                }
                expectation.fulfill()
            })
        }, { expectation in
            self.performRequest("post", path: "/route", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response!.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(response!.statusCode)")
                do {
                    let body = try response!.readString()
                    XCTAssertEqual(body!, "post received")
                } catch {
                    XCTFail("No response body")
                }
                expectation.fulfill()
            })
        })
    }

    func testHeaderModifiers() {

        router.get("/headerTest") { _, response, next in

            response.headers.append("Content-Type", value: "text/html")
            XCTAssertEqual(response.headers["Content-Type"]!, "text/html")

            response.headers.append("Content-Type", value: "text/plain; charset=utf-8")
            XCTAssertEqual(response.headers["Content-Type"]!, "text/html")

            response.headers["Content-Type"] = nil
            XCTAssertNil(response.headers["Content-Type"])

            response.headers.append("Content-Type", value: "text/plain, image/png")
            XCTAssertEqual(response.headers["Content-Type"]!, "text/plain, image/png")

            response.headers.append("Content-Type", value: "text/html, image/jpeg")
            XCTAssertEqual(response.headers["Content-Type"]!, "text/plain, image/png")

            response.headers.append("Content-Type", value: "charset=UTF-8")
            XCTAssertEqual(response.headers["Content-Type"]!, "text/plain, image/png")

            response.headers["Content-Type"] = nil

            response.headers.append("Content-Type", value: "text/html")
            XCTAssertEqual(response.headers["Content-Type"]!, "text/html")

            response.headers.append("Content-Type", value: "image/png, text/plain")
            XCTAssertEqual(response.headers["Content-Type"]!, "text/html")

            do {
                try response.status(HTTPStatusCode.OK).send("<!DOCTYPE html><html><body><b>Received</b></body></html>\n\n").end()
            } catch {}
            next()
        }

        performServerTest(router) { expectation in
            self.performRequest("get", path: "/headerTest", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                expectation.fulfill()
            })
        }

    }

    func testAcceptTypes() {

        router.get("/customPage") { request, response, next in

            XCTAssertEqual(request.accepts(type: "html"), "html", "Accepts did not return expected value")
            XCTAssertEqual(request.accepts(types: "text/html"), "text/html", "Accepts did not return expected value")
            XCTAssertEqual(request.accepts(types: ["json", "text"]), "json", "Accepts did not return expected value")
            XCTAssertEqual(request.accepts(types: "application/json"), "application/json", "Accepts did not return expected value")

            // test for headers with * subtype
            XCTAssertEqual(request.accepts(types: "application/xml"), "application/xml", "Accepts did not return expected value")
            XCTAssertEqual(request.accepts(types: "xml", "json"), "json", "Accepts did not return expected value")
            XCTAssertEqual(request.accepts(types: "html", "xml", "png"), "html", "Accepts did not return expected value")

            // shouldn't match anything
            XCTAssertNil(request.accepts(types: "image/png"), "Request accepts this type when it shouldn't")
            XCTAssertNil(request.accepts(types: "png"), "Request accepts this type when it shouldn't")
            XCTAssertNil(request.accepts(types: "unreal"), "Invalid extension was accepted!")

            do {
                try response.status(HTTPStatusCode.OK).send("<!DOCTYPE html><html><body><b>Received</b></body></html>\n\n").end()
            } catch {}
            next()
        }

        router.get("/customPage2") { request, response, next in

            XCTAssertEqual(request.accepts(types: "image/png"), "image/png", "Request accepts this type when it shouldn't")
            XCTAssertEqual(request.accepts(types: "image/tiff"), "image/tiff", "Request accepts this type when it shouldn't")
            XCTAssertEqual(request.accepts(types: "json", "jpeg", "html"), "html", "Accepts did not return expected value")
            XCTAssertEqual(request.accepts(types: ["png", "html"]), "html", "Accepts did not return expected value")
            XCTAssertEqual(request.accepts(types: ["xml", "html", "unreal"]), "html", "Accepts did not return expected value")

            do {
                try response.status(HTTPStatusCode.OK).send("<!DOCTYPE html><html><body><b>Received</b></body></html>\n\n").end()
            } catch {}
            next()
        }

        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: "/customPage", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                expectation.fulfill()
            }) {req in
                req.headers = ["Accept" : "text/*;q=.5, application/json, application/*;q=.3"]
            }
        }, { expectation in
            self.performRequest("get", path:"/customPage2", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                expectation.fulfill()
            }) {req in
                req.headers = ["accept" : "*/*;q=.001, application/*;q=0.2, image/jpeg;q=0.8, text/html, text/plain"]
            }
        })
    }

    func testAcceptEncodingTypes() {
        router.get("/customPage") { request, response, next in
            XCTAssertEqual(request.accepts(header: "Accept-Encoding", type: "gzip"), "gzip", "Accepts did not return expected value")
            XCTAssertEqual(request.accepts(header: "Accept-Encoding", types: "compress"), "compress", "Accepts did not return expected value")
            XCTAssertEqual(request.accepts(header: "Accept-Encoding", types: ["compress", "gzip"]), "gzip", "Accepts did not return expected value")

            // should NOT match "*" here as q = 0
            XCTAssertNil(request.accepts(header: "Accept-Encoding", types: "deflate"), "Request accepts this type when it shouldn't")

            do {
                try response.status(HTTPStatusCode.OK).send("<!DOCTYPE html><html><body><b>Received</b></body></html>\n\n").end()
            } catch {}
            next()
        }

        router.get("/customPage2") { request, response, next in
            XCTAssertEqual(request.accepts(header: "Accept-Encoding", type: "gzip"), "gzip", "Accepts did not return expected value")
            XCTAssertEqual(request.accepts(header: "Accept-Encoding", types: "compress"), "compress", "Accepts did not return expected value")
            //should match compress instead of gzip here as q value is greater
            XCTAssertEqual(request.accepts(header: "Accept-Encoding", types: ["compress", "gzip"]), "compress", "Accepts did not return expected value")

            // should match "*" here as q > 0
            XCTAssertEqual(request.accepts(header: "Accept-Encoding", types: "deflate"), "deflate", "Accepts did not return expected value")

            // should NOT match here as header is incorrect
            XCTAssertNil(request.accepts(header: "Accept-Charset", types: "deflate"), "Request accepts this type when it shouldn't")

            do {
                try response.status(HTTPStatusCode.OK).send("<!DOCTYPE html><html><body><b>Received</b></body></html>\n\n").end()
            } catch {}
            next()
        }

        performServerTest(router, asyncTasks: { expectation in
            self.performRequest("get", path: "/customPage", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                expectation.fulfill()
            }) {req in
                req.headers = ["Accept-Encoding" : "compress;q=0.5, gzip;q=1.0, *;q=0"]
            }
        }, { expectation in
            self.performRequest("get", path:"/customPage2", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                expectation.fulfill()
            }) {req in
                req.headers = ["accept-encoding" : "gzip;q=0.5, compress;q=1.0, *;q=0.001"]
            }
        })
    }

    func testFormat() {
        performServerTest(router) { expectation in
            self.performRequest("get", path:"/format", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response!.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(response!.statusCode)")
                XCTAssertEqual(response!.headers["Content-Type"]!.first!, "text/html")
                do {
                    let body = try response!.readString()
                    XCTAssertEqual(body!, "<!DOCTYPE html><html><body>Hi from Kitura!</body></html>\n\n")
                } catch {
                    XCTFail("No response body")
                }
                expectation.fulfill()
                }, headers: ["Accept" : "text/html"])
        }

        performServerTest(router) { expectation in
            self.performRequest("get", path:"/format", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response!.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(response!.statusCode)")
                XCTAssertEqual(response!.headers["Content-Type"]!.first!, "text/plain")
                do {
                    let body = try response!.readString()
                    XCTAssertEqual(body!, "Hi from Kitura!")
                } catch {
                    XCTFail("No response body")
                }
                expectation.fulfill()
                }, headers: ["Accept" : "text/plain"])
        }

        performServerTest(router) { expectation in
            self.performRequest("get", path:"/format", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response!.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(response!.statusCode)")
                do {
                    let body = try response!.readString()
                    XCTAssertEqual(body!, "default")
                } catch {
                    XCTFail("No response body")
                }
                expectation.fulfill()
                }, headers: ["Accept" : "text/cmd"])
        }

    }

    func testLink() {
        performServerTest(router) { expectation in
            self.performRequest("get", path: "/single_link", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response!.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(response!.statusCode)")
                let header = response!.headers["Link"]?.first
                XCTAssertNotNil(header, "Link header should not be nil")
                XCTAssertEqual(header!, "<https://developer.ibm.com/swift>; rel=\"root\"")
                expectation.fulfill()
            })
        }

        performServerTest(router) { expectation in
            self.performRequest("get", path: "/multiple_links", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response!.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(response!.statusCode)")
                let firstLink = "<https://developer.ibm.com/swift/products/ibm-swift-sandbox/>; rel=\"next\""
                let secondLink = "<https://developer.ibm.com/swift/products/ibm-bluemix/>; rel=\"prev\""
                let header = response!.headers["Link"]?.first
                XCTAssertNotNil(header, "Link header should not be nil")
                XCTAssertNotNil(header!.range(of: firstLink), "link header should contain first link")
                XCTAssertNotNil(header!.range(of: secondLink), "link header should contain second link")
                expectation.fulfill()
            })
        }
    }

    func testJsonp() {
        performServerTest(router) { expectation in
            self.performRequest("get", path: "/jsonp?callback=testfn", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response!.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(response!.statusCode)")
                do {
                    let body = try response!.readString()
#if os(Linux)
                    let expected = "{\n  \"some\": \"json\"\n}"
#else
                    let expected = "{\n  \"some\" : \"json\"\n}"
#endif
                    XCTAssertEqual(body!, "/**/ testfn(\(expected))")
                    XCTAssertEqual(response!.headers["Content-Type"]!.first!, "application/javascript")
                } catch {
                    XCTFail("No response body")
                }
                expectation.fulfill()
            })
        }

        performServerTest(router) { expectation in
            self.performRequest("get", path: "/jsonp?callback=test+fn", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response!.statusCode, HTTPStatusCode.badRequest, "HTTP Status code was \(response!.statusCode)")
                expectation.fulfill()
            })
        }

        performServerTest(router) { expectation in
            self.performRequest("get", path: "/jsonp", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response!.statusCode, HTTPStatusCode.badRequest, "HTTP Status code was \(response!.statusCode)")
                expectation.fulfill()
            })
        }

        performServerTest(router) { expectation in
            self.performRequest("get", path: "/jsonp_cb?cb=testfn", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response!.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(response!.statusCode)")
                do {
                    let body = try response!.readString()
#if os(Linux)
                    let expected = "{\n  \"some\": \"json\"\n}"
#else
                    let expected = "{\n  \"some\" : \"json\"\n}"
#endif
                    XCTAssertEqual(body!, "/**/ testfn(\(expected))")
                    XCTAssertEqual(response!.headers["Content-Type"]!.first!, "application/javascript")
                } catch {
                    XCTFail("No response body")
                }
                expectation.fulfill()
            })
        }

        performServerTest(router) { expectation in
            self.performRequest("get", path: "/jsonp_encoded?callback=testfn", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response!.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(response!.statusCode)")
                do {
                    let body = try response!.readString()
                    #if os(Linux)
                        let expected = "{\n  \"some\": \"json with bad js chars \\u2028 \\u2029\"\n}"
                    #else
                        let expected = "{\n  \"some\" : \"json with bad js chars \\u2028 \\u2029\"\n}"
                    #endif
                    XCTAssertEqual(body!, "/**/ testfn(\(expected))")
                    XCTAssertEqual(response!.headers["Content-Type"]!.first!, "application/javascript")
                } catch {
                    XCTFail("No response body")
                }
                expectation.fulfill()
            })
        }
    }

    func testSubdomains() {
        performServerTest(router) { expectation in
            self.performRequest("get", path: "/subdomains", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response!.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(response!.statusCode)")
                let hostHeader = response!.headers["Host"]?.first
                let domainHeader = response!.headers["Domain"]?.first
                let subdomainsHeader = response!.headers["Subdomain"]?.first

                XCTAssertEqual(hostHeader, "localhost", "Wrong http response host")
                XCTAssertEqual(domainHeader, "localhost", "Wrong http response domain")
                XCTAssertEqual(subdomainsHeader, "", "Wrong http response subdomains")
                expectation.fulfill()
            })
        }

        performServerTest(router) { expectation in
            self.performRequest("get", path: "/subdomains", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response!.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(response!.statusCode)")
                let hostHeader = response!.headers["Host"]?.first
                let domainHeader = response!.headers["Domain"]?.first
                let subdomainsHeader = response!.headers["Subdomain"]?.first

                XCTAssertEqual(hostHeader, "a.b.c.example.com", "Wrong http response host")
                XCTAssertEqual(domainHeader, "example.com", "Wrong http response domain")
                XCTAssertEqual(subdomainsHeader, "a, b, c", "Wrong http response subdomains")
                expectation.fulfill()
            }, headers: ["Host" : "a.b.c.example.com"])
        }

        performServerTest(router) { expectation in
            self.performRequest("get", path: "/subdomains", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response!.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(response!.statusCode)")
                let hostHeader = response!.headers["Host"]?.first
                let domainHeader = response!.headers["Domain"]?.first
                let subdomainsHeader = response!.headers["Subdomain"]?.first

                XCTAssertEqual(hostHeader, "a.b.c.d.example.co.uk", "Wrong http response host")
                XCTAssertEqual(domainHeader, "example.co.uk", "Wrong http response domain")
                XCTAssertEqual(subdomainsHeader, "a, b, c, d", "Wrong http response subdomains")
                expectation.fulfill()
            }, headers: ["Host" : "a.b.c.d.example.co.uk"])
        }
    }

    func testLifecycle() {
        performServerTest(router) { expectation in
            self.performRequest("get", path: "/lifecycle", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response!.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(response!.statusCode)")
                XCTAssertEqual(response!.headers["x-lifecycle"]?.first, "kitura", "Wrong lifecycle header")
                do {
                    let body = try response!.readString()
                    XCTAssertEqual(body!, "<!DOCTYPE html><html><body><b>Filtered</b></body></html>\n\n")
                } catch {
                    XCTFail("No response body")
                }
                expectation.fulfill()
            })
        }
    }

    func testSend() {
        performServerTest(router) { expectation in
            self.performRequest("get", path: "/data", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response!.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(response!.statusCode)")
                do {
                    var body = Data()
                    _ = try response!.read(into: &body)
                    XCTAssertEqual(body, "<!DOCTYPE html><html><body><b>Received</b></body></html>\n\n".data(using: .utf8)!)
                } catch {
                    XCTFail("No response body")
                }
                expectation.fulfill()
            })
        }

        performServerTest(router) { expectation in
            self.performRequest("get", path: "/json", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response!.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(response!.statusCode)")
                XCTAssertEqual(response!.headers["Content-Type"]?.first, "application/json", "Wrong Content-Type header")
                do {
                    var body = Data()
                    _ = try response!.read(into: &body)
                    let json = JSON(data: body)
                    XCTAssertEqual(json["some"], "json")
                } catch {
                    XCTFail("No response body")
                }
                expectation.fulfill()
            })
        }

        performServerTest(router) { expectation in
            self.performRequest("get", path: "/download", callback: { response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response!.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(response!.statusCode)")
                XCTAssertEqual(response!.headers["Content-Type"]?.first, "text/html", "Wrong Content-Type header")
                do {
                    let body = try response!.readString()
                    XCTAssertEqual(body!, "<!DOCTYPE html><html><body><b>Index</b></body></html>\n")
                } catch {
                    XCTFail("No response body")
                }

                expectation.fulfill()
            })
        }

    }

    static func setupRouter() -> Router {
        let router = Router()

        // subdomains test
        router.get("subdomains") { request, response, next in
            response.headers["Host"] = request.hostname
            response.headers["Domain"] = request.domain

            let subdomains = request.subdomains

            response.headers["Subdomain"] = subdomains.joined(separator: ", ")

            response.status(.OK)
            next()
        }

        // the same router definition is used for all these test cases
        router.all("/zxcv/:p1") { request, _, next in
            request.userInfo["u1"] = "Ploni Almoni"
            next()
        }

        router.get("/qwer") { _, response, next in
            response.headers["Content-Type"] = "text/html; charset=utf-8"
            do {
                try response.send("<!DOCTYPE html><html><body><b>Received</b></body></html>\n\n").end()
            } catch {}
            next()
        }

        router.get("/zxcv/:p1") { request, response, next in
            response.headers["Content-Type"] = "text/html; charset=utf-8"
            let p1 = request.parameters["p1"] ?? "(nil)"
            let q = request.queryParameters["q"] ?? "(nil)"
            let u1 = request.userInfo["u1"] as? String ?? "(nil)"
            do {
                try response.send("<!DOCTYPE html><html><body><b>Received /zxcv</b><p><p>p1=\(p1)<p><p>q=\(q)<p><p>u1=\(u1)</body></html>\n\n").end()
            } catch {}
            next()
        }

        router.get("/redir") { _, response, next in
            do {
                try response.redirect("http://www.ibm.com")
            } catch {}

            next()
        }

        // Error handling example
        router.get("/error") { _, response, next in
            response.status(HTTPStatusCode.internalServerError)
            response.error = InternalError.nilVariable(variable: "foo")
            next()
        }

        router.route("/route")
        .get { _, response, next in
            response.send("get 1\n")
            next()
        }
        .post {_, response, next in
            response.send("post received")
            next()
        }
        .get { _, response, next in
            response.send("get 2\n")
            next()
        }

        let bodyTestHandler: RouterHandler = { request, response, next in
            guard let requestBody = request.body else {
                next ()
                return
            }

            if let urlEncoded = requestBody.asURLEncoded {
                do {
                    response.headers["Content-Type"] = "text/html; charset=utf-8"
                    try response.send("<!DOCTYPE html><html><body><b>Received URL encoded body</b><br> \(urlEncoded) </body></html>\n\n").end()
                } catch {
                    XCTFail("caught error: \(error)")
                }
            } else if let text = requestBody.asText {
                do {
                    response.headers["Content-Type"] = "text/html; charset=utf-8"
                    try response.send("<!DOCTYPE html><html><body><b>Received text body: </b>\(text)</body></html>\n\n").end()
                } catch {
                    XCTFail("caught error: \(error)")
                }
            } else if let json = requestBody.asJSON {
                do {
                    response.headers["Content-Type"] = "application/json; charset=utf-8"
                    try response.send(data: json.rawData()).end()
                } catch {
                    XCTFail("caught error: \(error)")
                }
            } else if case let .raw(data) = requestBody {
                XCTAssertNotNil(data)
                let length = "2048"
                _ = response.send("length: \(length)")
                next()
            } else {
                response.error = Error.failedToParseRequestBody(body: "\(request.body)")
            }

            next()
        }

        router.all("/bodytest", middleware: BodyParser())
        router.post("/bodytest", handler: bodyTestHandler)

        router.post("/bodytesthardway") { request, response, next in
            let body = try request.readString()
            response.status(.OK).send("Read \(body?.characters.count ?? 0) bytes")
            next()
        }

        //intentially BodyParser is added twice, to check how two body parsers work together
        router.all("/doublebodytest", middleware: BodyParser())
        router.all("/doublebodytest", middleware: BodyParser())
        router.post("/doublebodytest", handler: bodyTestHandler)

        router.all("/multibodytest", middleware: BodyParser())

        router.post("/multibodytest") { request, response, next in
            guard let body = request.body else {
                next ()
                return
            }
            guard let parts = body.asMultiPart else {
                response.error = Error.failedToParseRequestBody(body: "\(request.body)")
                next ()
                return
            }
            for part in parts {
                response.send("\(part.name) \(part.filename) \(part.body) ")
            }

            next()
        }

        func callbackText(request: RouterRequest, response: RouterResponse) {
            do {
                try response.status(HTTPStatusCode.OK).send("Hi from Kitura!").end()
            } catch {}

        }

        func callbackHtml(request: RouterRequest, response: RouterResponse) {
            do {
                try response.status(HTTPStatusCode.OK).send("<!DOCTYPE html><html><body>Hi from Kitura!</body></html>\n\n").end()
            } catch {}

        }

        func callbackDefault(request: RouterRequest, response: RouterResponse) {
            do {
                response.headers["Content-Type"] = "text/plain; charset=utf-8"
                try response.status(HTTPStatusCode.OK).send("default").end()
            } catch {}

        }

        router.get("/format") { request, response, next in
            do {
                try response.format(callbacks: [
                                                   "text/plain" : callbackText,
                                                   "text/html" : callbackHtml,
                                                   "default" : callbackDefault])
            } catch {}
        }

        router.get("/single_link") { request, response, next in
            do {
                response.headers.addLink("https://developer.ibm.com/swift",
                                     linkParameters: [.rel: "root"])
                try response.status(.OK).end()
            } catch {}
        }

        router.get("/multiple_links") { request, response, next in
            do {
                response.headers.addLink("https://developer.ibm.com/swift/products/ibm-bluemix/",
                         linkParameters: [.rel: "prev"])
                response.headers.addLink("https://developer.ibm.com/swift/products/ibm-swift-sandbox/",
                         linkParameters: [.rel: "next"])
                try response.status(.OK).end()
            } catch {}
        }

        router.get("/jsonp") { request, response, next in
            let json = JSON([ "some": "json" ])
            do {
                do {
                    try response.send(jsonp: json).end()
                } catch JSONPError.invalidCallbackName {
                    try response.status(.badRequest).end()
                }
            } catch {}
        }

        router.get("/jsonp_cb") { request, response, next in
            let json = JSON([ "some": "json" ])
            do {
                do {
                    try response.send(jsonp: json, callbackParameter: "cb").end()
                } catch JSONPError.invalidCallbackName {
                    try response.status(.badRequest).end()
                }
            } catch {}
        }

        router.get("/jsonp_encoded") { request, response, next in
#if os(Linux)
            let json = JSON([ "some": JSON("json with bad js chars \u{2028} \u{2029}") ])
#else
            let json = JSON([ "some": JSON("json with bad js chars \u{2028} \u{2029}" as NSString) ])
#endif
            do {
                do {
                    try response.send(jsonp: json).end()
                } catch JSONPError.invalidCallbackName {
                    try response.status(.badRequest).end()
                }
            } catch {}
        }

        router.get("/lifecycle") { request, response, next in
            var previousOnEndInvoked: LifecycleHandler? = nil
            let onEndInvoked = {
                response.headers["x-lifecycle"] = "kitura"
                previousOnEndInvoked!()
            }
            previousOnEndInvoked = response.setOnEndInvoked(onEndInvoked)

            var previousWrittenDataFilter: WrittenDataFilter? = nil
            let writtenDataFilter: WrittenDataFilter = { _ in
                let newBody = "<!DOCTYPE html><html><body><b>Filtered</b></body></html>\n\n"
                return previousWrittenDataFilter!(newBody.data(using: .utf8)!)
            }
            previousWrittenDataFilter = response.setWrittenDataFilter(writtenDataFilter)

            response.headers["Content-Type"] = "text/html; charset=utf-8"
            do {
                try response.send("<!DOCTYPE html><html><body><b>Lifecycle</b></body></html>\n\n").end()
            } catch {}
            next()
        }

        router.get("/data") { _, response, next in
            do {
                try response.send(data: "<!DOCTYPE html><html><body><b>Received</b></body></html>\n\n".data(using: .utf8)!).end()
            } catch {}
            next()
        }

        router.get("/json") { _, response, next in
            response.headers["Content-Type"] = "application/json"
            let json = JSON([ "some": "json" ])
            do {
                try response.send(json: json).end()
            } catch {}
            next()
        }

        router.get("/download") { _, response, next in
            do {
                try response.send(download: "./Tests/KituraTests/TestStaticFileServer/index.html")
            } catch {}
            next()
        }

        router.error { request, response, next in
            response.headers["Content-Type"] = "text/html; charset=utf-8"
            do {
                let errorDescription: String
                if let error = response.error {
                    errorDescription = "\(error)"
                } else {
                    errorDescription = ""
                }
                try response.send("Caught the error: \(errorDescription)").end()
            } catch {}
            next()
        }

        router.error([ { request, response, next in
            // Dummy error handler
            next()
        }])

        router.error(DummyErrorMiddleware())

        router.error([DummyErrorMiddleware()])

	return router
    }

    class DummyErrorMiddleware: RouterMiddleware {
        func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
            next()
        }
    }
}
