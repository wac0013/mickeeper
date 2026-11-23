import XCTest
@testable import MicKeeperCore

final class PolicyTests: XCTestCase {
    private let builtIn = AudioInput(uid: "builtin", name: "MacBook Mic", isBuiltIn: true)
    private let usb = AudioInput(uid: "usb", name: "USB Mic")
    private let airpods = AudioInput(uid: "airpods", name: "AirPods", isBluetooth: true)
    private let headset = AudioInput(uid: "headset", name: "BT Headset", isBluetooth: true)

    func testBluetoothHijackRevertsToLastGood() {
        var config = Config()
        config.lastGoodUID = "usb"

        let out = Policy.decide(current: airpods, available: [builtIn, usb, airpods], config: config)

        XCTAssertEqual(out.switchTo, usb)
        XCTAssertEqual(out.lastGoodUID, "usb")
    }

    func testBluetoothHijackFallsBackToBuiltInWithoutLastGood() {
        let out = Policy.decide(current: airpods, available: [airpods, usb, builtIn], config: Config())

        XCTAssertEqual(out.switchTo, builtIn)
    }

    func testBluetoothHijackFallsBackToBuiltInWhenLastGoodDisconnected() {
        var config = Config()
        config.lastGoodUID = "usb"

        let out = Policy.decide(current: airpods, available: [airpods, builtIn], config: config)

        XCTAssertEqual(out.switchTo, builtIn)
    }

    func testEligibleManualSwitchIsAcceptedAndBecomesLastGood() {
        var config = Config()
        config.lastGoodUID = "builtin"

        let out = Policy.decide(current: usb, available: [builtIn, usb, airpods], config: config)

        XCTAssertNil(out.switchTo)
        XCTAssertEqual(out.lastGoodUID, "usb")
    }

    func testBlocklistedNonBluetoothDeviceIsReverted() {
        var config = Config()
        config.lastGoodUID = "builtin"
        config.toggleBlock(usb.ref)

        let out = Policy.decide(current: usb, available: [builtIn, usb], config: config)

        XCTAssertEqual(out.switchTo, builtIn)
    }

    func testRankingPicksFirstConnectedInOrder() {
        var config = Config()
        config.rankingEnabled = true
        config.toggleRank(usb.ref)
        config.toggleRank(builtIn.ref)

        let out = Policy.decide(current: builtIn, available: [builtIn, usb], config: config)

        XCTAssertEqual(out.switchTo, usb)
    }

    func testRankingSkipsDisconnectedDevice() {
        var config = Config()
        config.rankingEnabled = true
        config.toggleRank(usb.ref)
        config.toggleRank(builtIn.ref)

        let out = Policy.decide(current: airpods, available: [builtIn, airpods], config: config)

        XCTAssertEqual(out.switchTo, builtIn)
    }

    func testRankedBluetoothMicIsAllowedWhenRankingEnabled() {
        var config = Config()
        config.rankingEnabled = true
        config.toggleRank(headset.ref)
        config.toggleRank(builtIn.ref)

        let out = Policy.decide(current: builtIn, available: [builtIn, headset], config: config)

        XCTAssertEqual(out.switchTo, headset)
    }

    func testRankedBluetoothIsStillBlockedWhenRankingDisabled() {
        var config = Config()
        config.rankingEnabled = false
        config.toggleRank(headset.ref)
        config.lastGoodUID = "builtin"

        let out = Policy.decide(current: headset, available: [builtIn, headset], config: config)

        XCTAssertEqual(out.switchTo, builtIn)
    }

    func testUnrankedBluetoothIsBlockedEvenWithRankingEnabled() {
        var config = Config()
        config.rankingEnabled = true
        config.toggleRank(usb.ref)

        let out = Policy.decide(current: airpods, available: [usb, airpods], config: config)

        XCTAssertEqual(out.switchTo, usb)
    }

    func testBlocklistBeatsRanking() {
        var config = Config()
        config.rankingEnabled = true
        config.toggleRank(usb.ref)
        config.toggleBlock(usb.ref)

        let out = Policy.decide(current: builtIn, available: [builtIn, usb], config: config)

        XCTAssertNil(out.switchTo)
        XCTAssertFalse(config.isRanked("usb"))
    }

    func testNoEligibleCandidateKeepsCurrent() {
        let out = Policy.decide(current: airpods, available: [airpods], config: Config())

        XCTAssertNil(out.switchTo)
    }

    func testNoCurrentDeviceChoosesBuiltIn() {
        let out = Policy.decide(current: nil, available: [usb, builtIn], config: Config())

        XCTAssertEqual(out.switchTo, builtIn)
    }
}

final class ConfigTests: XCTestCase {
    func testMoveRankSwapsAndClampsAtEdges() {
        var config = Config()
        config.toggleRank(DeviceRef(uid: "a", name: "A"))
        config.toggleRank(DeviceRef(uid: "b", name: "B"))

        config.moveRank(uid: "b", by: -1)
        config.moveRank(uid: "b", by: -1)

        XCTAssertEqual(config.ranking.map(\.uid), ["b", "a"])
    }

    func testToggleRankRemovesFromBlocklist() {
        var config = Config()
        let ref = DeviceRef(uid: "a", name: "A")
        config.toggleBlock(ref)

        config.toggleRank(ref)

        XCTAssertFalse(config.isBlocked("a"))
        XCTAssertTrue(config.isRanked("a"))
    }

    func testStorePersistsAndReloads() {
        let defaults = UserDefaults(suiteName: "mickeeper.tests.\(UUID().uuidString)")!
        let store = ConfigStore(defaults: defaults)

        store.update { $0.enabled = false; $0.lastGoodUID = "x" }
        let reloaded = ConfigStore(defaults: defaults)

        XCTAssertFalse(reloaded.config.enabled)
        XCTAssertEqual(reloaded.config.lastGoodUID, "x")
    }

    func testDecodeToleratesMissingFields() throws {
        let config = try JSONDecoder().decode(Config.self, from: Data("{}".utf8))

        XCTAssertTrue(config.enabled)
        XCTAssertTrue(config.ranking.isEmpty)
    }
}

final class StringsTests: XCTestCase {
    func testPortugueseSystemLanguageUsesPtBr() {
        XCTAssertEqual(Strings(languages: ["pt-BR", "en-US"]).protected, "Protegido")
    }

    func testOtherLanguagesFallBackToEnglish() {
        XCTAssertEqual(Strings(languages: ["de-DE"]).protected, "Protected")
    }
}
