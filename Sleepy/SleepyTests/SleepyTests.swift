//
//  SleepyTests.swift
//  SleepyTests
//
//  Created by Davide Perrotta on 20/02/25.
//

import XCTest
@testable import Sleepy

final class SleepyTests: XCTestCase {
    
    var networkManager: NetworkManager!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        super.setUp()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        networkManager = nil
        super.tearDown()
    }

    func testExample() async throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        let testSeconds = 3600 // Simulo 1 ora di sonno (3600 secondi)
                
                do {
                    let response = try await networkManager.sendPost_request(seconds: testSeconds)
                    XCTAssertNotNil(response, "La risposta non dovrebbe essere nil")
                } catch {
                    XCTFail("Errore durante l'invio dei dati: \(error.localizedDescription)")
                }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
            Task {
                            do {
                                _ = try await networkManager.sendPost_request(seconds: 3600)
                            } catch {
                                XCTFail("Errore durante la misurazione delle prestazioni: \(error.localizedDescription)")
                            }
                        }
        }
    }
    
    

}
