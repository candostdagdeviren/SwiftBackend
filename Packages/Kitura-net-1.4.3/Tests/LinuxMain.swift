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

@testable import KituraNetTests

XCTMain([
       testCase(ClientE2ETests.allTests),
       testCase(ClientRequestTests.allTests),
       testCase(FastCGIProtocolTests.allTests),
       testCase(FastCGIRequestTests.allTests),
       testCase(HTTPResponseTests.allTests),
       testCase(LargePayloadTests.allTests),
       testCase(LifecycleListenerTests.allTests),
       testCase(MiscellaneousTests.allTests),
       testCase(MonitoringTests.allTests),
       testCase(ParserTests.allTests),
       testCase(SocketManagerTests.allTests),
       testCase(UpgradeTests.allTests)
])
