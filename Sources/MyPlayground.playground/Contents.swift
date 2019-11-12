import UIKit

var items: [(String) -> ()] = []

func test(closure: @escaping (String) -> ()) {
    items.append(closure)
}

test { text in
    DispatchQueue.global().asyncAfter(deadline: .now()+5, execute: {
        print(text)
    })
}

items[0]("test")
items.removeAll()
