//
//  Card.swift
//  Flashzilla
//
//  Created by Сергей Захаров on 26.04.2026.
//

import Foundation

struct Card: Codable, Identifiable {
    var id: UUID
    var prompt: String
    var answer: String

    init(id: UUID = UUID(), prompt: String, answer: String) {
        self.id = id
        self.prompt = prompt
        self.answer = answer
    }

    enum CodingKeys: String, CodingKey {
        case id, prompt, answer
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.prompt = try container.decode(String.self, forKey: .prompt)
        self.answer = try container.decode(String.self, forKey: .answer)
    }

    static let example = Card(prompt: "Who played the 13th Doctor in Doctor Who?", answer: "Jodie Whittaker")
}
