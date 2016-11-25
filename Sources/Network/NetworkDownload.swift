//
//  ProcedureKit
//
//  Copyright © 2016 ProcedureKit. All rights reserved.
//

/**
 NetworkDownloadProcedure is a simple procedure which will perform a download task using
 URLSession based APIs. It only supports the completion block style API, therefore
 do not use this procedure if you wish to use delegate based APIs on URLSession.
 */
open class NetworkDownloadProcedure<Session: URLSessionTaskFactory>: Procedure, InputProcedure, OutputProcedure, NetworkOperation {
    public typealias NetworkResult = ProcedureResult<HTTPPayloadResponse<URL>>
    public typealias CompletionBlock = (NetworkResult) -> Void

    public var input: Pending<URLRequest> = .pending
    public var output: Pending<NetworkResult> = .pending

    public private(set) var session: Session
    public let completion: CompletionBlock

    internal var task: Session.DownloadTask? = nil

    public var networkError: ProcedureKitNetworkError? {
        return output.error as? ProcedureKitNetworkError ?? errors.flatMap { $0 as? ProcedureKitNetworkError }.first
    }

    public init(session: Session, request: URLRequest? = nil, completionHandler: @escaping CompletionBlock = { _ in }) {

        self.session = session
        self.input = request.flatMap { .ready($0) } ?? .pending
        self.completion = completionHandler

        super.init()
        addWillCancelBlockObserver { procedure, _ in
            procedure.task?.cancel()
        }
    }

    open override func execute() {
        guard let request = input.value else {
            finish(withResult: .failure(ProcedureKitError.requirementNotSatisfied()))
            return
        }

        task = session.downloadTask(with: request) { [weak self] location, response, error in
            guard let strongSelf = self else { return }

            if let error = error {
                strongSelf.finish(withResult: .failure(ProcedureKitNetworkError(error as NSError)))
                return
            }

            guard let location = location, let response = response as? HTTPURLResponse else {
                strongSelf.finish(withResult: .failure(ProcedureKitError.unknown))
                return
            }

            let http = HTTPPayloadResponse(payload: location, response: response)

            strongSelf.completion(.success(http))
            strongSelf.finish(withResult: .success(http))
        }

        task?.resume()
    }
}