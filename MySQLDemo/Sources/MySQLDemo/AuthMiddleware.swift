import Vapor

struct AuthMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        if request.session.data["userId"] != nil {
            return next.respond(to: request)
        } else {
            return request.eventLoop.makeSucceededFuture(
                request.redirect(to: "/login")
            )
        }
    }
}
