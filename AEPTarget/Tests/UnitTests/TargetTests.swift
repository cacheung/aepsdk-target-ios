/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

@testable import AEPCore
@testable import AEPServices
@testable import AEPTarget
import XCTest

class TargetTests: XCTestCase {
    var target: Target!
    var mockRuntime: TestableExtensionRuntime!

    var mockMBox = ["mbox1", "mbox2"]
    var mockMBoxJson = ["mbox1": ["state": "state1", "options": [["eventToken": "sometoken"]], "metrics": [["type": "click", "eventToken": "eventToken"]]],
                        "mbox2": ["state": "state2", "options": [["eventToken": "sometoken2"]]]]
    var mockProfileParam = ["name": "Smith"]
    var mockConfigSharedState = ["target.clientCode": "code_123", "global.privacy": "optedin"]

    override func setUp() {
        mockRuntime = TestableExtensionRuntime()
        target = Target(runtime: mockRuntime)
    }

    func testRegisterExtension_registersWithoutAnyErrorOrCrash() {
        XCTAssertNoThrow(MobileCore.registerExtensions([Target.self]))
    }

    func testRegisterExtension() {
        target.onRegistered()
        XCTAssertEqual(5, mockRuntime.listeners.count)
    }

    func testReadyForEvent() {
        let event = Event(name: "", type: "", source: "", data: nil)
        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.configuration", event: event, data: (value: ["target.clientCode": "code_123"], status: .set))
        XCTAssertTrue(target.readyForEvent(event))
    }

    func testReadyForEvent_no_configuration() {
        XCTAssertFalse(target.readyForEvent(Event(name: "", type: "", source: "", data: nil)))
    }

    func testPrefetchContent() {
        MockNetworkService.request = nil
        ServiceProvider.shared.networkService = MockNetworkService()
        let prefetchDataArray: [[String: Any]?] = [
            TargetPrefetch(name: "Drink_1", targetParameters: TargetParameters(profileParameters: ["mbox-parameter-key1": "mbox-parameter-value1"])),
            TargetPrefetch(name: "Drink_2", targetParameters: TargetParameters(profileParameters: ["mbox-parameter-key1": "mbox-parameter-value1"])),
        ].map {
            $0.asDictionary()
        }

        let data: [String: Any] = [
            "prefetch": prefetchDataArray,
            "targetparams": TargetParameters(profileParameters: mockProfileParam).asDictionary() as Any,
        ]
        let event = Event(name: "", type: "", source: "", data: data)
        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.configuration", event: event, data: (value: mockConfigSharedState, status: .set))
        target.onRegistered()
        if let eventListener: EventListener = mockRuntime.listeners["com.adobe.eventType.target-com.adobe.eventSource.requestContent"] {
            eventListener(event)
            XCTAssertNotNil(MockNetworkService.request)
            if let url = MockNetworkService.request?.url.absoluteString {
                XCTAssertTrue(url.hasPrefix("https://code_123.tt.omtrdc.net/rest/v1/delivery/?client=code_123&sessionId="))
            } else {
                XCTFail()
            }
            return
        }
        XCTFail()
    }

    func testLocationDisplayed() {
        MockNetworkService.request = nil
        ServiceProvider.shared.networkService = MockNetworkService()
        target.targetState.mergePrefetchedMboxJson(mboxesDictionary: mockMBoxJson)

        let data: [String: Any] = [
            "mboxnames": mockMBox,
            "targetparams": TargetParameters(profileParameters: mockProfileParam).asDictionary() as Any,
            TargetConstants.EventDataKeys.IS_LOCATION_DISPLAYED: true,
        ]
        let event = Event(name: "", type: "", source: "", data: data)
        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.configuration", event: event, data: (value: mockConfigSharedState, status: .set))
        target.onRegistered()
        if let eventListener: EventListener = mockRuntime.listeners["com.adobe.eventType.target-com.adobe.eventSource.requestContent"] {
            eventListener(event)
            XCTAssertNotNil(MockNetworkService.request)
            if let url = MockNetworkService.request?.url.absoluteString {
                XCTAssertTrue(url.hasPrefix("https://code_123.tt.omtrdc.net/rest/v1/delivery/?client=code_123&sessionId="))
            } else {
                XCTFail()
            }
            return
        }
        XCTFail()
    }

    func testLocationClicked() {
        MockNetworkService.request = nil
        ServiceProvider.shared.networkService = MockNetworkService()
        target.targetState.mergePrefetchedMboxJson(mboxesDictionary: mockMBoxJson)

        let data: [String: Any] = [
            "mboxname": "mbox1",
            "targetparams": TargetParameters(profileParameters: mockProfileParam).asDictionary() as Any,
            TargetConstants.EventDataKeys.IS_LOCATION_CLICKED: true,
        ]
        let event = Event(name: "", type: "", source: "", data: data)
        mockRuntime.simulateSharedState(extensionName: "com.adobe.module.configuration", event: event, data: (value: mockConfigSharedState, status: .set))
        target.onRegistered()
        if let eventListener: EventListener = mockRuntime.listeners["com.adobe.eventType.target-com.adobe.eventSource.requestContent"] {
            eventListener(event)
            XCTAssertNotNil(MockNetworkService.request)
            if let url = MockNetworkService.request?.url.absoluteString {
                XCTAssertTrue(url.hasPrefix("https://code_123.tt.omtrdc.net/rest/v1/delivery/?client=code_123&sessionId="))
            } else {
                XCTFail()
            }
            return
        }
        XCTFail()
    }
}

private class MockNetworkService: Networking {
    static var request: NetworkRequest?
    func connectAsync(networkRequest request: NetworkRequest, completionHandler _: ((HttpConnection) -> Void)?) {
        MockNetworkService.request = request
    }
}