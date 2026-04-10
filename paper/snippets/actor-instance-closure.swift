actor LocalBox {
    var state = 0

    func makeClosures() {
        let keepsIsolation: @isolated(any) () -> Void = {
            _ = self.state
        }

        let dropsIsolation: @isolated(any) () -> Void = {
            print("no isolated capture")
        }

        _ = keepsIsolation.isolation // non-nil: actor-instance isolation survives because `self` is captured
        _ = dropsIsolation.isolation // nil: no isolated capture, so the closure falls back to nonisolated
    }
}
