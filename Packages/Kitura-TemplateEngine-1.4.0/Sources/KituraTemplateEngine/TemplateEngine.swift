/*
 * Copyright IBM Corporation 2015 - 2016
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


/// Template Engine protocol for Kitura. Implemented by Templating Engines in order to
/// integrate with Kitura's content generation APIs.
///
/// - Note: Influenced by http://expressjs.com/en/guide/using-template-engines.html
public protocol TemplateEngine {
    
    /// The file extension of files in the views directory that will be
    /// rendered by a particular templating engine.
    var fileExtension: String { get }
    
    /// Take a template file and a set of "variables" in the form of a context
    /// and generate content to be sent back to the client.
    ///
    /// - Parameter filePath: The path of the template file to use when generating
    ///                      the content.
    /// - Parameter context: A set of variables in the form of a Dictionary of
    ///                     Key/Value pairs, that can be used when generating the content.
    func render(filePath: String, context: [String: Any]) throws -> String
}
