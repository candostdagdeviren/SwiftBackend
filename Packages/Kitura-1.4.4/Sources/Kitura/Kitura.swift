/*
 * Copyright IBM Corporation 2015
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
 */

import KituraNet
import LoggerAPI

import Foundation
import Dispatch

// MARK Kitura

/// A set of helper functions to make it easier to create, start, and stop Kitura based servers.
public class Kitura {

    /// Add an HTTPServer on a port with a delegate.
    ///
    /// The server is only registered with the framework, it does not start listening
    /// on the port until Kitura.run() or Kitura.start() is called.
    ///
    /// - Parameter onPort: The port to listen on.
    /// - Parameter with: The `ServerDelegate` to use.
    /// - Parameter withSSL: The `sslConfig` to use.
    /// - Returns: The created `HTTPServer`.
    @discardableResult
    public class func addHTTPServer(onPort port: Int, with delegate: ServerDelegate, withSSL sslConfig: SSLConfig?=nil) -> HTTPServer {
        let server = HTTP.createServer()
        server.delegate = delegate
        if let sslConfig = sslConfig {
            server.sslConfig = sslConfig.config
        }
        httpServersAndPorts.append(server: server, port: port)
        return server
    }

    /// Add a FastCGIServer on a port with a delegate.
    ///
    /// The server is only registered with the framework, it does not start listening
    /// on the port until Kitura.run() or Kitura.start() is called.
    ///
    /// - Parameter onPort: The port to listen on.
    /// - Parameter with: The `ServerDelegate` to use.
    /// - Returns: The created `FastCGIServer`.
    @discardableResult
    public class func addFastCGIServer(onPort port: Int, with delegate: ServerDelegate) -> FastCGIServer {
        let server = FastCGI.createServer()
        server.delegate = delegate
        fastCGIServersAndPorts.append(server: server, port: port)
        return server
    }

    /// Start the Kitura framework.
    ///
    /// Make all registered servers start listening on their port.
    ///
    /// - note: This function never returns - it should be the last call in your main.swift
    public class func run() {
        Log.verbose("Starting Kitura framework...")
        start()
        ListenerGroup.waitForListeners()
    }

    /// Start all registered servers and return
    ///
    /// Make all registered servers start listening on their port.
    public class func start() {
        for (server, port) in httpServersAndPorts {
            Log.verbose("Starting an HTTP Server on port \(port)...")
            do {
                try server.listen(on: port)
            } catch {
                Log.error("Error listening on port \(port): \(error). Use server.failed(callback:) to handle")
            }
        }
        for (server, port) in fastCGIServersAndPorts {
            Log.verbose("Starting a FastCGI Server on port \(port)...")
            do {
                try server.listen(on: port)
            } catch {
                Log.error("Error listening on port \(port): \(error). Use server.failed(callback:) to handle")
            }
        }
    }

    /// Stop all registered servers
    ///
    /// Make all registered servers stop listening on their port.
    ///
    /// - note: All of the registered servers are unregistered after they are stopped.
    public class func stop() {
        for (server, port) in httpServersAndPorts {
            Log.verbose("Stopping HTTP Server on port \(port)...")
            server.stop()
        }
        httpServersAndPorts.removeAll()
        for (server, port) in fastCGIServersAndPorts {
            Log.verbose("Stopping FastCGI Server on port \(port)...")
            server.stop()
        }
        fastCGIServersAndPorts.removeAll()
    }

    typealias Port = Int
    private static var httpServersAndPorts = [(server: HTTPServer, port: Port)]()
    private static var fastCGIServersAndPorts = [(server: FastCGIServer, port: Port)]()

}
