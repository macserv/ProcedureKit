//
//  ExclusivityManager.swift
//  Operations
//
//  Created by Daniel Thorpe on 27/06/2015.
//  Copyright (c) 2015 Daniel Thorpe. All rights reserved.
//

import Foundation

class ExclusivityManager {

    static let sharedInstance = ExclusivityManager()

    private let queue = dispatch_queue_create("me.danthorpe.Operations.Exclusivity", DISPATCH_QUEUE_SERIAL)
    private var operations: [String: [Operation]] = [:]

    private init() {
        // A private initalizer prevents any other part of the app
        // from creating an instance.
    }

    func addOperation(operation: Operation, categories: [String]) {
        dispatch_sync(queue) {
            for category in categories {
                self._addOperation(operation, category: category)
            }
        }
    }

    func removeOperation(operation: Operation, categories: [String]) {
        dispatch_async(queue) {
            for category in categories {
                self._removeOperation(operation, category: category)
            }
        }
    }


    private func _addOperation(operation: Operation, category: String) {
        var operationsWithThisCategory = operations[category] ?? []

        if let last = operationsWithThisCategory.last {
            operation.addDependency(last)
        }

        operationsWithThisCategory.append(operation)

        operations[category] = operationsWithThisCategory
    }

    private func _removeOperation(operation: Operation, category: String) {
        let matchingOperations = operations[category]

        if  var operationsWithThisCategory = matchingOperations,
            let index = operationsWithThisCategory.indexOf(operation) {
                operationsWithThisCategory.removeAtIndex(index)
                operations[category] = operationsWithThisCategory
        }
    }
}
