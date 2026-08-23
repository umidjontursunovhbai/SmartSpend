import CloudKit
import Foundation

final class CloudSyncService {
    static let shared = CloudSyncService()

    private let containerIdentifier = "iCloud.com.tursunov.SmartSpend"
    private let recordType = "SmartSpendData"
    private let recordName = "primary"
    private let payloadKey = "payload"
    private let updatedAtKey = "updatedAt"

    private init() {}

    func checkAccountStatus() async -> CloudSyncState {
        guard hasICloudContainerEntitlement else {
            return .unavailable("iCloud sync is not enabled in this build yet. After Apple Developer subscription, enable iCloud + CloudKit capability.")
        }

        do {
            let status = try await cloudContainer.accountStatus()

            switch status {
            case .available:
                return .idle
            case .noAccount:
                return .unavailable("Sign in to iCloud on this iPhone to use sync.")
            case .restricted:
                return .unavailable("iCloud is restricted on this device.")
            case .couldNotDetermine:
                return .unavailable("SmartSpend could not check iCloud right now.")
            case .temporarilyUnavailable:
                return .unavailable("iCloud is temporarily unavailable. Try again later.")
            @unknown default:
                return .unavailable("This iCloud status is not supported yet.")
            }
        } catch {
            return .unavailable(syncMessage(for: error))
        }
    }

    func sync(localSnapshot: SmartSpendSyncSnapshot) async throws -> SmartSpendSyncSnapshot {
        guard hasICloudContainerEntitlement else {
            throw CloudSyncError.missingEntitlement
        }

        let database = cloudContainer.privateCloudDatabase
        let recordID = CKRecord.ID(recordName: recordName)

        do {
            let remoteRecord = try await database.record(for: recordID)
            let remoteSnapshot = try decodeSnapshot(from: remoteRecord)

            if remoteSnapshot.updatedAt > localSnapshot.updatedAt {
                return remoteSnapshot
            }

            try await upload(localSnapshot, into: remoteRecord, database: database)
            return localSnapshot
        } catch let error as CKError where error.code == .unknownItem {
            let record = CKRecord(recordType: recordType, recordID: recordID)
            try await upload(localSnapshot, into: record, database: database)
            return localSnapshot
        } catch {
            throw error
        }
    }

    private func upload(
        _ snapshot: SmartSpendSyncSnapshot,
        into record: CKRecord,
        database: CKDatabase
    ) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(snapshot)
        record[payloadKey] = data as CKRecordValue
        record[updatedAtKey] = snapshot.updatedAt as CKRecordValue

        _ = try await database.save(record)
    }

    private func decodeSnapshot(from record: CKRecord) throws -> SmartSpendSyncSnapshot {
        guard let data = record[payloadKey] as? Data else {
            throw CloudSyncError.missingPayload
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(SmartSpendSyncSnapshot.self, from: data)
    }

    private var cloudContainer: CKContainer {
        CKContainer(identifier: containerIdentifier)
    }

    private var hasICloudContainerEntitlement: Bool {
        // Keep CloudKit calls disabled until the app has the paid Apple Developer
        // iCloud + CloudKit capability. Calling CloudKit without the entitlement
        // can crash when Settings opens.
        false
    }

    func syncMessage(for error: Error) -> String {
        guard let ckError = error as? CKError else {
            return error.localizedDescription
        }

        switch ckError.code {
        case .notAuthenticated:
            return "Sign in to iCloud on this iPhone to use sync."
        case .permissionFailure:
            return "CloudKit is not enabled for this app yet. After Apple Developer subscription, enable iCloud + CloudKit capability."
        case .networkUnavailable, .networkFailure:
            return "Network is unavailable. Check internet and try again."
        case .serviceUnavailable, .requestRateLimited, .zoneBusy:
            return "iCloud is busy right now. Try again later."
        default:
            return ckError.localizedDescription
        }
    }
}

enum CloudSyncError: LocalizedError {
    case missingEntitlement
    case missingPayload

    var errorDescription: String? {
        switch self {
        case .missingEntitlement:
            return "iCloud sync is not enabled in this build yet. After Apple Developer subscription, enable iCloud + CloudKit capability."
        case .missingPayload:
            return "Remote iCloud data is missing its payload."
        }
    }
}
