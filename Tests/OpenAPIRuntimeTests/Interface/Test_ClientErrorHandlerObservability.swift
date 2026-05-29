//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftOpenAPIGenerator open source project
//
// Copyright (c) 2026 Apple Inc. and the SwiftOpenAPIGenerator project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftOpenAPIGenerator project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import HTTPTypes
import Testing
@_spi(Generated) @testable import OpenAPIRuntime

struct Test_ClientErrorHandlerObservability {
    @Test
    func configurationDefaultNil() {
        let configuration = Configuration()

        #expect(configuration.clientErrorHandler == nil)
    }

    @Test
    func configurationCustomHandler() throws {
        let handler = RecordingClientErrorHandler()
        let configuration = Configuration(
            multipartBoundaryGenerator: .constant,
            xmlCoder: MockCustomCoder(),
            clientErrorHandler: { handler.record($0) }
        )
        let clientError = ClientError(
            operationID: "op",
            operationInput: "input",
            causeDescription: "Unknown",
            underlyingError: TestError()
        )

        configuration.clientErrorHandler?(clientError)

        #expect(try #require(handler.errors.first).operationID == "op")
        #expect(configuration.xmlCoder != nil)
    }

    @Test
    func requestSerializationError() async throws {
        let handler = RecordingClientErrorHandler()
        let client = UniversalClient(
            configuration: Configuration(clientErrorHandler: { handler.record($0) }),
            transport: MockClientTransport.successful
        )

        do {
            let _: String = try await client.send(
                input: "input",
                forOperation: "op",
                serializer: { _ in throw TestError() },
                deserializer: { _, _ in throw TestError() }
            )
            Issue.record("Expected error to be thrown.")
        } catch {
            let clientError = try #require(error as? ClientError)
            let observedError = try #require(handler.errors.first)
            #expect(handler.errors.count == 1)
            #expect(observedError.operationID == clientError.operationID)
            #expect(observedError.operationInput as? String == "input")
            #expect(observedError.causeDescription == "Unknown")
            #expect(observedError.underlyingError as? TestError == TestError())
            #expect(observedError.request == nil)
            #expect(observedError.response == nil)
        }
    }

    @Test
    func transportError() async throws {
        let handler = RecordingClientErrorHandler()
        let client = UniversalClient(
            configuration: Configuration(clientErrorHandler: { handler.record($0) }),
            transport: MockClientTransport.failing
        )

        do {
            let _: String = try await client.send(
                input: "input",
                forOperation: "op",
                serializer: { _ in (HTTPRequest(soar_path: "/", method: .post), MockClientTransport.requestBody) },
                deserializer: { _, _ in throw TestError() }
            )
            Issue.record("Expected error to be thrown.")
        } catch {
            let clientError = try #require(error as? ClientError)
            let observedError = try #require(handler.errors.first)
            #expect(handler.errors.count == 1)
            #expect(observedError.operationID == clientError.operationID)
            #expect(observedError.causeDescription == "Transport threw an error.")
            #expect(observedError.underlyingError as? TestError == TestError())
            #expect(observedError.request == HTTPRequest(soar_path: "/", method: .post))
            #expect(observedError.requestBody == MockClientTransport.requestBody)
            #expect(observedError.response == nil)
        }
    }

    @Test
    func transportErrorThroughMiddlewareStack() async throws {
        let handler = RecordingClientErrorHandler()
        let client = UniversalClient(
            configuration: Configuration(clientErrorHandler: { handler.record($0) }),
            transport: MockClientTransport.failing,
            middlewares: [MockMiddleware()]
        )

        do {
            let _: String = try await client.send(
                input: "input",
                forOperation: "op",
                serializer: { _ in (HTTPRequest(soar_path: "/", method: .post), MockClientTransport.requestBody) },
                deserializer: { _, _ in throw TestError() }
            )
            Issue.record("Expected error to be thrown.")
        } catch {
            let clientError = try #require(error as? ClientError)
            let observedError = try #require(handler.errors.first)
            #expect(handler.errors.count == 1)
            #expect(observedError.operationID == clientError.operationID)
            #expect(observedError.causeDescription == "Transport threw an error.")
            #expect(observedError.underlyingError as? TestError == TestError())
            #expect(observedError.request == HTTPRequest(soar_path: "/", method: .post))
            #expect(observedError.requestBody == MockClientTransport.requestBody)
            #expect(observedError.response == nil)
        }
    }

    @Test
    func middlewareRequestError() async throws {
        let handler = RecordingClientErrorHandler()
        let client = UniversalClient(
            configuration: Configuration(clientErrorHandler: { handler.record($0) }),
            transport: MockClientTransport.successful,
            middlewares: [MockMiddleware(failurePhase: .onRequest)]
        )

        do {
            let _: String = try await client.send(
                input: "input",
                forOperation: "op",
                serializer: { _ in (HTTPRequest(soar_path: "/", method: .post), MockClientTransport.requestBody) },
                deserializer: { _, _ in throw TestError() }
            )
            Issue.record("Expected error to be thrown.")
        } catch {
            let clientError = try #require(error as? ClientError)
            let observedError = try #require(handler.errors.first)
            #expect(handler.errors.count == 1)
            #expect(observedError.operationID == clientError.operationID)
            #expect(observedError.causeDescription == "Middleware of type 'MockMiddleware' threw an error.")
            #expect(observedError.underlyingError as? TestError == TestError())
            #expect(observedError.request == HTTPRequest(soar_path: "/", method: .post))
            #expect(observedError.requestBody == MockClientTransport.requestBody)
            #expect(observedError.response == nil)
        }
    }

    @Test
    func middlewareResponseError() async throws {
        let handler = RecordingClientErrorHandler()
        let client = UniversalClient(
            configuration: Configuration(clientErrorHandler: { handler.record($0) }),
            transport: MockClientTransport.successful,
            middlewares: [MockMiddleware(failurePhase: .onResponse)]
        )

        do {
            let _: String = try await client.send(
                input: "input",
                forOperation: "op",
                serializer: { _ in (HTTPRequest(soar_path: "/", method: .post), MockClientTransport.requestBody) },
                deserializer: { _, _ in throw TestError() }
            )
            Issue.record("Expected error to be thrown.")
        } catch {
            let clientError = try #require(error as? ClientError)
            let observedError = try #require(handler.errors.first)
            #expect(handler.errors.count == 1)
            #expect(observedError.operationID == clientError.operationID)
            #expect(observedError.causeDescription == "Middleware of type 'MockMiddleware' threw an error.")
            #expect(observedError.underlyingError as? TestError == TestError())
            #expect(observedError.request == HTTPRequest(soar_path: "/", method: .post))
            #expect(observedError.requestBody == MockClientTransport.requestBody)
            #expect(observedError.response == nil)
        }
    }

    @Test
    func responseDeserializationError() async throws {
        let handler = RecordingClientErrorHandler()
        let client = UniversalClient(
            configuration: Configuration(clientErrorHandler: { handler.record($0) }),
            transport: MockClientTransport.successful
        )
        let decodingError = DecodingError.dataCorrupted(
            .init(codingPath: [], debugDescription: "Invalid response body.")
        )

        do {
            let _: String = try await client.send(
                input: "input",
                forOperation: "op",
                serializer: { _ in (HTTPRequest(soar_path: "/", method: .post), MockClientTransport.requestBody) },
                deserializer: { _, _ in throw decodingError }
            )
            Issue.record("Expected error to be thrown.")
        } catch {
            let clientError = try #require(error as? ClientError)
            let observedError = try #require(handler.errors.first)
            #expect(handler.errors.count == 1)
            #expect(observedError.operationID == clientError.operationID)
            #expect(observedError.underlyingError is DecodingError)
            #expect(observedError.request == HTTPRequest(soar_path: "/", method: .post))
            #expect(observedError.requestBody == MockClientTransport.requestBody)
            #expect(observedError.response == HTTPResponse(status: .ok))
            #expect(observedError.responseBody == MockClientTransport.responseBody)
        }
    }

    @Test
    func observesSameClientErrorThatIsThrown() async throws {
        let handler = RecordingClientErrorHandler()
        let client = UniversalClient(
            configuration: Configuration(clientErrorHandler: { handler.record($0) }),
            transport: MockClientTransport.successful
        )
        let decodingError = DecodingError.dataCorrupted(
            .init(codingPath: [], debugDescription: "Invalid response body.")
        )

        do {
            let _: String = try await client.send(
                input: "input",
                forOperation: "op",
                serializer: { _ in (HTTPRequest(soar_path: "/", method: .post), MockClientTransport.requestBody) },
                deserializer: { _, _ in throw decodingError }
            )
            Issue.record("Expected error to be thrown.")
        } catch {
            let clientError = try #require(error as? ClientError)
            let observedError = try #require(handler.errors.first)
            #expect(handler.errors.count == 1)
            #expect(observedError.operationID == clientError.operationID)
            #expect(observedError.operationInput as? String == clientError.operationInput as? String)
            #expect(observedError.request == clientError.request)
            #expect(observedError.requestBody == clientError.requestBody)
            #expect(observedError.baseURL == clientError.baseURL)
            #expect(observedError.response == clientError.response)
            #expect(observedError.responseBody == clientError.responseBody)
            #expect(observedError.causeDescription == clientError.causeDescription)
            #expect(observedError.underlyingError is DecodingError)
            #expect(clientError.underlyingError is DecodingError)
        }
    }

    @Test
    func notCalledOnSuccess() async throws {
        let handler = RecordingClientErrorHandler()
        let client = UniversalClient(
            configuration: Configuration(clientErrorHandler: { handler.record($0) }),
            transport: MockClientTransport.successful
        )

        let output: String = try await client.send(
            input: "input",
            forOperation: "op",
            serializer: { _ in (HTTPRequest(soar_path: "/", method: .post), MockClientTransport.requestBody) },
            deserializer: { _, _ in "output" }
        )

        #expect(output == "output")
        #expect(handler.errors.isEmpty)
    }
}

private final class RecordingClientErrorHandler: @unchecked Sendable {
    private let lock = Lock()
    private var _errors: [ClientError] = []

    var errors: [ClientError] { lock.withLock { _errors } }

    func record(_ error: ClientError) { lock.withLockVoid { _errors.append(error) } }
}
