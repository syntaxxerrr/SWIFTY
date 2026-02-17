import MySQLKit
import NIOCore

typealias Database = MySQLDatabase

struct Item: Codable {
    let id: Int
    let name: String
    let description: String?
}

struct ItemManager {
    let db: Database

    func addItem(name: String, description: String?) -> EventLoopFuture<Void> {
        let descValue = description != nil ? "'\(description!)'" : "NULL"
        let insert = """
            INSERT INTO items (name, description)
            VALUES ('\(name)', \(descValue))
        """
        return db.simpleQuery(insert).map { _ in }
    }

    func updateItem(id: Int, name: String?, description: String?) -> EventLoopFuture<Void> {
        var updates: [String] = []
        if let newName = name, !newName.isEmpty {
            updates.append("name = '\(newName)'")
        }
        if let newDesc = description {
            updates.append("description = '\(newDesc)'")
        }
        guard !updates.isEmpty else {
            return db.eventLoop.makeSucceededFuture(())
        }
        let setClause = updates.joined(separator: ", ")
        let query = "UPDATE items SET \(setClause) WHERE id = \(id)"
        return db.simpleQuery(query).map { _ in }
    }

    func deleteItem(id: Int) -> EventLoopFuture<Void> {
        let query = "DELETE FROM items WHERE id = \(id)"
        return db.simpleQuery(query).map { _ in }
    }

    func getItem(id: Int) -> EventLoopFuture<Item?> {
        let query = "SELECT id, name, description FROM items WHERE id = \(id)"
        return db.simpleQuery(query).map { rows in
            guard let row = rows.first,
                  let id = row.column("id")?.int,
                  let name = row.column("name")?.string else { return nil }
            let description = row.column("description")?.string
            return Item(id: id, name: name, description: description)
        }
    }

    func searchItems(term: String) -> EventLoopFuture<[Item]> {
        let query = """
            SELECT id, name, description FROM items
            WHERE name LIKE '%\(term)%' OR description LIKE '%\(term)%'
        """
        return db.simpleQuery(query).map { rows in
            rows.compactMap { row in
                guard let id = row.column("id")?.int,
                      let name = row.column("name")?.string else { return nil }
                let description = row.column("description")?.string
                return Item(id: id, name: name, description: description)
            }
        }
    }
}
