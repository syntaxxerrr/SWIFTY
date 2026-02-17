import Vapor

struct IndexContext: Encodable {
    let items: [Item]
    let searchTerm: String
    let username: String?
}

struct EditContext: Encodable {
    let item: Item
    let username: String?
}

func routes(_ app: Application) throws {
    let manager = app.itemManager
    let auth = app.userAuth

    // Login
    app.get("login") { req async throws -> View in
        let error = req.query["error"] ?? ""
        let registered = req.query["registered"] ?? ""
        return try await req.view.render("login", ["error": error, "registered": registered])
    }

    app.post("login") { req async throws -> Response in
        struct LoginData: Content {
            var username: String
            var password: String
        }
        let data = try req.content.decode(LoginData.self)
        let user = try await auth.authenticate(username: data.username, password: data.password).get()
        if let user = user {
            req.session.data["userId"] = String(user.id)
            req.session.data["username"] = user.username
            return req.redirect(to: "/")
        } else {
            return req.redirect(to: "/login?error=Invalid%20username%20or%20password")
        }
    }

    // Signup
    app.get("signup") { req async throws -> View in
        let error = req.query["error"] ?? ""
        return try await req.view.render("signup", ["error": error])
    }

    app.post("signup") { req async throws -> Response in
        struct SignupData: Content {
            var username: String
            var password: String
        }
        let data = try req.content.decode(SignupData.self)
        let newUser = try await auth.createUser(username: data.username, password: data.password).get()
        if let user = newUser {
            req.session.data["userId"] = String(user.id)
            req.session.data["username"] = user.username
            return req.redirect(to: "/")
        } else {
            return req.redirect(to: "/signup?error=Username%20already%20taken")
        }
    }

    // Logout
    app.get("logout") { req -> Response in
        req.session.destroy()
        return req.redirect(to: "/login")
    }

    // Protected routes
    let protected = app.grouped(AuthMiddleware())

    protected.get { req async throws -> View in
        let items = try await manager.searchItems(term: "").get()
        let username = req.session.data["username"]
        let context = IndexContext(items: items, searchTerm: "", username: username)
        return try await req.view.render("index", context)
    }

    protected.get("search") { req async throws -> View in
        let term = req.query["term"] ?? ""
        let items = try await manager.searchItems(term: term).get()
        let username = req.session.data["username"]
        let context = IndexContext(items: items, searchTerm: term, username: username)
        return try await req.view.render("index", context)
    }

    protected.get("add") { req async throws -> View in
        let username = req.session.data["username"]
        return try await req.view.render("add", ["username": username])
    }

    protected.post("add") { req async throws -> Response in
        struct AddData: Content {
            var name: String
            var description: String?
        }
        let data = try req.content.decode(AddData.self)
        try await manager.addItem(name: data.name, description: data.description).get()
        return req.redirect(to: "/")
    }

    protected.get("edit", ":id") { req async throws -> View in
        guard let id = req.parameters.get("id", as: Int.self) else {
            throw Abort(.badRequest)
        }
        guard let item = try await manager.getItem(id: id).get() else {
            throw Abort(.notFound)
        }
        let username = req.session.data["username"]
        let context = EditContext(item: item, username: username)
        return try await req.view.render("edit", context)
    }

    protected.post("edit", ":id") { req async throws -> Response in
        struct EditData: Content {
            var name: String?
            var description: String?
        }
        guard let id = req.parameters.get("id", as: Int.self) else {
            throw Abort(.badRequest)
        }
        let data = try req.content.decode(EditData.self)
        try await manager.updateItem(id: id, name: data.name, description: data.description).get()
        return req.redirect(to: "/")
    }

    protected.post("delete", ":id") { req async throws -> Response in
        guard let id = req.parameters.get("id", as: Int.self) else {
            throw Abort(.badRequest)
        }
        try await manager.deleteItem(id: id).get()
        return req.redirect(to: "/")
    }
}
