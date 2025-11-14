//
//  CloudKitService.swift
//  Numu
//
//  Created by Majd Iskandarani on 11/13/25.
//

import Foundation
import CloudKit
import SwiftUI

/// Service for monitoring CloudKit sync status and account availability
/// This is optional - SwiftData handles all sync automatically
@Observable
class CloudKitService {
    var isSignedIn: Bool = false
    var syncStatus: SyncStatus = .unknown

    private let container: CKContainer

    init(containerIdentifier: String = "iCloud.com.majdiskandarani.Numu") {
        self.container = CKContainer(identifier: containerIdentifier)
        checkAccountStatus()
    }

    // MARK: - Account Status

    /// Check if user is signed into iCloud
    func checkAccountStatus() {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    self?.isSignedIn = true
                    self?.syncStatus = .synced
                case .noAccount, .restricted:
                    self?.isSignedIn = false
                    self?.syncStatus = .notSignedIn
                case .couldNotDetermine, .temporarilyUnavailable:
                    self?.isSignedIn = false
                    self?.syncStatus = .error
                @unknown default:
                    self?.isSignedIn = false
                    self?.syncStatus = .unknown
                }
            }
        }
    }

    // MARK: - Helper Methods

    /// Call this when app becomes active to refresh status
    func refreshStatus() {
        checkAccountStatus()
    }
}

// MARK: - Sync Status

enum SyncStatus {
    case synced
    case syncing
    case notSignedIn
    case error
    case unknown

    var message: String {
        switch self {
        case .synced:
            return "Synced"
        case .syncing:
            return "Syncing..."
        case .notSignedIn:
            return "Sign in to iCloud to enable sync"
        case .error:
            return "Sync error"
        case .unknown:
            return "Checking sync status..."
        }
    }

    var icon: String {
        switch self {
        case .synced:
            return "checkmark.icloud"
        case .syncing:
            return "arrow.clockwise.icloud"
        case .notSignedIn:
            return "xmark.icloud"
        case .error:
            return "exclamationmark.icloud"
        case .unknown:
            return "icloud"
        }
    }
}
