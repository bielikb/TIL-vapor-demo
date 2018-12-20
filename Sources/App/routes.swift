import Vapor
import Fluent

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "It works" example
    router.get { req in
        return "It works!"
    }
    
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }

    router.post("api", "acronyms") { (request) -> Future<Acronym> in
        return try request.content.decode(Acronym.self).flatMap(to: Acronym.self, { (acronym) in
            return acronym.save(on: request)
        })
    }

    router.get("api", "acronyms") { (request) -> Future<[Acronym]> in
        return Acronym.query(on: request).all()
    }

    // 1
    router.get("api", "acronyms", Acronym.parameter) {
        req -> Future<Acronym> in
        // 2
        return try req.parameters.next(Acronym.self)
    }

    router.put("api", "acronyms", Acronym.parameter) {
        req -> Future<Acronym> in
        // 2
        return try flatMap(to: Acronym.self,
                           req.parameters.next(Acronym.self),
                           req.content.decode(Acronym.self)) {
                            acronym, updatedAcronym in
                            // 3
                            acronym.short = updatedAcronym.short
                            acronym.long = updatedAcronym.long
                            // 4
                            return acronym.save(on: req)
        }
    }

    router.delete("api", "acronyms", Acronym.parameter) {
        req -> Future<HTTPStatus> in
        // 2
        return try req.parameters.next(Acronym.self)
        // 3
        .delete(on: req)
        // 4
        .transform(to: HTTPStatus.noContent)
    }

    router.get("api", "acronyms", "search") {
        req -> Future<[Acronym]> in
        // 2
        guard
            let searchTerm = req.query[String.self, at: "term"] else {
                throw Abort(.badRequest)
        }
        // 3
        return Acronym.query(on: req).group(.or, closure: { or in
            or.filter(\.short == searchTerm)
            or.filter(\.long == searchTerm)
        }).all()
    }

    router.get("api", "acronyms", "sorted") {
        req -> Future<[Acronym]> in
        // 2
        return Acronym.query(on: req)
        .sort(\.short, .ascending)
        .all()
    }

    router.get("api", "acronyms", "first") {
        req -> Future<Acronym> in
        // 2
        return Acronym.query(on: req)
            // 3
            .first()
            .map(to: Acronym.self) { acronym in
                guard let acronym = acronym else {
                    throw Abort(.notFound)
                }
                // 4
                return acronym
        }
    }
}
