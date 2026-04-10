@Test func isolatedAnyIsolation_taskRegionCapture_isNil() async throws {
    let isolation = await isolatedAny_isolationProperty_taskRegionCapture_returnsNil()
    #expect(isolation == nil)
}

@Test func isolatedAnyIsolation_mainActorCapture_isMainActor() async throws {
    let isolation = await isolatedAny_isolationProperty_mainActorCapture_returnsMainActor()
    let main = try #require(isolation as? MainActor)
    #expect(main === MainActor.shared)
}

@Test func isolatedAnyIsolation_mainActorCapture_plainClosureThenCoerce_isNil() async throws {
    let isolation = await isolatedAny_isolationProperty_mainActorCapture_returnsMainActor2()
    #expect(isolation == nil)
}

@Test func isolatedAnyIsolation_mainActorCapture_isolatedAnyClosureLiteral_isMainActor() async throws {
    let isolation = await isolatedAny_isolationProperty_mainActorCapture_returnsMainActor3()
    let main = try #require(isolation as? MainActor)
    #expect(main === MainActor.shared)
}
