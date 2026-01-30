//
//  TimerEngineProtocol.swift
//  TimerForMac
//
//  Created by Ivan Revchuk on 30.01.2026.
//

import Foundation

protocol TimerEngineProtocol: Sendable {
    var stream: AsyncStream<TimerSnapshot> { get }
    func start(target: TimeInterval?) async
    func pause() async
    func resume() async
    func stop() async
    func recoverIfNeeded() async
}
