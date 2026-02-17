import Vapor
import Foundation

var env = try Environment.detect()
let app = Application(env)
defer { app.shutdown() }

try configure(app)

// Catch Ctrl+C (SIGINT) and SIGTERM
let signalQueue = DispatchQueue(label: "signal-handler")
let sigintSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: signalQueue)
let sigtermSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: signalQueue)

sigintSource.setEventHandler {
    print("Received SIGINT, shutting down...")
    app.shutdown()
    exit(0)
}
sigtermSource.setEventHandler {
    print("Received SIGTERM, shutting down...")
    app.shutdown()
    exit(0)
}

signal(SIGINT, SIG_IGN)   // ignore default handling
signal(SIGTERM, SIG_IGN)  // ignore default handling
sigintSource.resume()
sigtermSource.resume()

try app.run()