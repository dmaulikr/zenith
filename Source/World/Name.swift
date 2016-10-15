public enum NameFlag {
    case indefinite
    case definite
    case capitalize
}

struct Name {

    private let nameBase: String
    private static let vowels = ["a", "e", "i", "o", "u"]

    init(_ type: String) {
        var nameBase = ""
        for character in type.characters {
            if String(character).lowercased() != String(character) {
                nameBase += " "
                nameBase += String(character).lowercased()
            } else {
                nameBase.append(character)
            }
        }
        self.nameBase = nameBase
    }

    func name(flags: [NameFlag]) -> String {
        var result = ""

        if flags.contains(.indefinite) {
            if Name.vowels.contains(String(nameBase.characters.first!)) {
                result += "an "
            } else {
                result += "a "
            }
        } else if flags.contains(.definite) {
            result += "the "
        }

        result += nameBase

        if flags.contains(.capitalize) {
            let firstCharacter = String(result.characters.first!)
            let rest = String(result.characters.dropFirst())
            result = firstCharacter.capitalized + rest
        }

        return result
    }
}
