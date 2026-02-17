import Vapor
import MySQLKit
import Leaf

extension Application {
    private struct ItemManagerKey: StorageKey {
        typealias Value = ItemManager
    }
    var itemManager: ItemManager {
        get {
            guard let manager = self.storage[ItemManagerKey.self] else {
                fatalError("ItemManager not configured")
            }
            return manager
        }
        set { self.storage[ItemManagerKey.self] = newValue }
    }

    private struct UserAuthKey: StorageKey {
        typealias Value = UserAuthenticator
    }
    var userAuth: UserAuthenticator {
        get {
            guard let auth = self.storage[UserAuthKey.self] else {
                fatalError("UserAuthenticator not configured")
            }
            return auth
        }
        set { self.storage[UserAuthKey.self] = newValue }
    }

    struct ConnectionPoolStorageKey: StorageKey {
        typealias Value = EventLoopGroupConnectionPool<MySQLConnectionSource>
    }
}

func configure(_ app: Application) throws {
    app.views.use(.leaf)
    app.middleware.use(app.sessions.middleware)
    app.sessions.use(.memory)

    let configuration = MySQLConfiguration(
        hostname: Environment.get("DB_HOST") ?? "127.0.0.1",
        port: Environment.get("DB_PORT").flatMap(Int.init) ?? 3306,
        username: Environment.get("DB_USER") ?? "root",
        password: Environment.get("DB_PASSWORD") ?? "secret",
        database: Environment.get("DB_NAME") ?? "testdb",
        tlsConfiguration: nil
    )

    let pools = EventLoopGroupConnectionPool(
        source: MySQLConnectionSource(configuration: configuration),
        on: app.eventLoopGroup
    )

    app.storage[Application.ConnectionPoolStorageKey.self] = pools
    app.lifecycle.use(ConnectionPoolCleanup())

    let db = pools.database(logger: Logger(label: "mysql"))
    app.itemManager = ItemManager(db: db)
    app.userAuth = UserAuthenticator(db: db)
}

struct ConnectionPoolCleanup: LifecycleHandler {
    func shutdown(_ application: Application) throws {
        try application.storage[Application.ConnectionPoolStorageKey.self]?.syncShutdownGracefully()
    }
}
