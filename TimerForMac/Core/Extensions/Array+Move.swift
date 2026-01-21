//
//  Array+Move.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 20.01.2026.
//

import Foundation

extension Array {
    /// Moves elements from `source` to `destination` without SwiftUI dependency.
    /// RU: Перемещает элементы из `source` в `destination` без зависимости от SwiftUI.
    func moving(from source: IndexSet, to destination: Int) -> [Element] {
        var result = self
        let movingItems = source.map { result[$0] }

        // Remove from highest index to lowest to avoid shifting.
        // RU: Удаляем с конца, чтобы индексы не смещались.
        for i in source.sorted(by: >) {
            result.remove(at: i)
        }

        // Destination in the array AFTER removals (SwiftUI semantics).
        // RU: destination считается после удаления исходных элементов.
        let removedBefore = source.filter { $0 < destination }.count
        let adjustedDestination = destination - removedBefore

        let clampedDestination = Swift.max(0, Swift.min(adjustedDestination, result.count))
        result.insert(contentsOf: movingItems, at: clampedDestination)

        return result
    }
}
