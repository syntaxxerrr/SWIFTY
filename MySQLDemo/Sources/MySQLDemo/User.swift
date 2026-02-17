import Vapor
import MySQLKit

struct User: Content {
    let id: Int
    let username: String
}

struct UserAuthenticator {
    let db: MySQLDatabase

    func authenticate(username: String, password: String) -> EventLoopFuture<User?> {
        let query = "SELECT id, username FROM users WHERE username = '\(username)' AND password = '\(password)'"
        return db.simpleQuery(query).map { rows in
            guard let row = rows.first,
                  let id = row.column("id")?.int,
                  let username = row.column("username")?.string else {
                return nil
            }
            return User(id: id, username: username)
        }
    }

    func createUser(username: String, password: String) -> EventLoopFuture<User?> {
        let checkQuery = "SELECT id FROM users WHERE username = '\(username)'"
        return db.simpleQuery(checkQuery).flatMap { rows in
            if !rows.isEmpty {
                return db.eventLoop.makeSucceededFuture(nil)
            }
            let insertQuery = "INSERT INTO users (username, password) VALUES ('\(username)', '\(password)')"
            return db.simpleQuery(insertQuery).flatMap { _ in
                let selectQuery = "SELECT id, username FROM users WHERE username = '\(username)'"
                return db.simpleQuery(selectQuery).map { rows in
                    guard let row = rows.first,
                          let id = row.column("id")?.int,
                          let username = row.column("username")?.string else {
                        return nil
                    }
                    return User(id: id, username: username)
                }
            }
        }
    }
}
