// Closure wrapping with disconnected local: capture OK
func disconnectedWrapping() {
    let g: () -> Void = {}              // disconnected
    let f: @MainActor () -> Void = { g() } // OK
    _ = f
}

// Closure wrapping with parameter (task region): error
// func paramWrapping(_ g: @escaping () -> Void) {
//     let _: @MainActor () -> Void = { g() } // error
// }

// Closure wrapping with sending parameter: capture OK
func sendingParamWrapping(_ g: sending @escaping () -> Void) {
    let f: @MainActor () -> Void = { g() } // OK
    _ = f
}
