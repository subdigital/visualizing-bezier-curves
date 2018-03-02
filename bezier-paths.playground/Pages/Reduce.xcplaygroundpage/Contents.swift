//: [Previous](@previous)

import UIKit

var points = [
    CGPoint(x: 0, y: 1),
    CGPoint(x: 10, y: 12),
    CGPoint(x: 12, y: 13),
    CGPoint(x: 15, y: 1)
]


let t: CGFloat = 0.25

func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
    return (1-t)*a + t*b
}

func lerp(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
    return CGPoint(
        x: lerp(a.x, b.x, t),
        y: lerp(a.y, b.y, t)
    )
}

func interp(points: [CGPoint]) -> (CGFloat) -> [CGPoint] {
    return { t in
        let first = points.first!
        let rest = points.dropFirst()
        
        let initial: ([CGPoint], CGPoint) = ([], first)
        let (interpolated, _) = rest.reduce(initial) { a, currentPoint in
            let points = a.0
            let prev = a.1
            let p = lerp(currentPoint, prev, t)
            return (points + [p], currentPoint)
        }
        return interpolated
    }
}

func interpZip(points: [CGPoint]) -> (CGFloat) -> [CGPoint] {
    return { t in
        let pairs = zip(points, points.dropFirst())
        return pairs.map { pair in
            lerp(pair.0, pair.1, t)
        }
    }
}

let f = interp(points: points)
f(1)



extension Sequence where SubSequence: Sequence,
    SubSequence.Iterator.Element == Iterator.Element {
    typealias Pair = (Element, Element)
    
    func consecutivePairs() -> AnySequence<Pair> {
        var iterator = makeIterator()
        guard var previous = iterator.next() else { return AnySequence([]) }
        return AnySequence({ () -> AnyIterator<Pair> in
            return AnyIterator({
                guard let next = iterator.next() else { return nil }
                defer { previous = next }
                return (previous, next)
            })
        })
    }
}






