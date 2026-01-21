//
//  JSONFileStore.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 15.01.2026.
//

import Foundation

protocol JSONFileStoring: AnyObject {
    func read<T: Decodable>(_ type: T.Type, from url: URL) throws -> T
    func write<T: Encodable>(_ value: T, to url: URL) throws
}

enum JSONFileStoreError: Error, Sendable {
    case readFailed(underlying: Error)
    case writeFailed(underlying: Error)
}

final class JSONFileStore: JSONFileStoring {
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let fileManager: FileManager

    init(
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder(),
        fileManager: FileManager = .default
    ) {
        self.encoder = encoder
        self.decoder = decoder
        self.fileManager = fileManager

        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func read<T: Decodable>(_ type: T.Type, from url: URL) throws -> T {
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(T.self, from: data)
        } catch {
            throw JSONFileStoreError.readFailed(underlying: error)
        }
    }

    func write<T: Encodable>(_ value: T, to url: URL) throws {
        do {
            let data = try encoder.encode(value)

            try fileManager.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true,
                attributes: nil
            )

            try data.write(to: url, options: [.atomic])
        } catch {
            throw JSONFileStoreError.writeFailed(underlying: error)
        }
    }
}
