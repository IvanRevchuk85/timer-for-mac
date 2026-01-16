//
//  JSONFileStore.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 15.01.2026.
//

import Foundation

// MARK: - JSONFileStoring
protocol JSONFileStoring {
    func read<T: Decodable>(_ type: T.Type, from url: URL) throws -> T
    func write<T: Encodable>(_ value: T, to url: URL) throws
}

// MARK: - JSONFileStore
final class JSONFileStore: JSONFileStoring {
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(encoder: JSONEncoder = JSONEncoder(), decoder: JSONDecoder = JSONDecoder()) {
        self.encoder = encoder
        self.decoder = decoder
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func read<T: Decodable>(_ type: T.Type, from url: URL) throws -> T {
        let data = try Data(contentsOf: url)
        return try decoder.decode(T.self, from: data)
    }

    func write<T: Encodable>(_ value: T, to url: URL) throws {
        let data = try encoder.encode(value)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: url, options: [.atomic])
    }
}
