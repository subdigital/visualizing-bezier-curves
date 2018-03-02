import UIKit
import PlaygroundSupport

let colorList: [UIColor] = (1...10).map { i in
    
    let min: CGFloat = 0.2
    let max: CGFloat = 0.8
    
    let w = (CGFloat(i) / 10.0) * (max-min) + min
    return UIColor(white: w, alpha: 0.6)
    
    } + [UIColor.orange]

extension CGPoint {
    func lerp(_ other: CGPoint, t: CGFloat) -> CGPoint {
        return CGPoint(
            x: (1-t)*x + t*other.x,
            y: (1-t)*y + t*other.y
        )
    }
    
    func distance(_ other: CGPoint) -> CGFloat {
        return sqrt(
            pow(x - other.x, 2) +
                pow(y - other.y, 2)
        )
    }
}

class ControlPoint : Hashable, Equatable {
    var point: CGPoint = .zero
    
    var hashValue: Int
    
    init(point: CGPoint) {
        hashValue = Int(arc4random())
        self.point = point
    }
    
    static func ==(lhs: ControlPoint, rhs: ControlPoint) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

class BezierView : UIView {
    
    private var colorIndex = 0;
    
    var bezierLayer: CAShapeLayer!
    
    var shouldDrawLine: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var timeValue: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var startPoint: CGPoint = .zero {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public var endPoint: CGPoint = .zero {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var controlPoints: [ControlPoint] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        bezierLayer = CAShapeLayer()
        bezierLayer.strokeColor = UIColor.orange.cgColor
        bezierLayer.lineWidth = 4
        bezierLayer.fillColor = UIColor.clear.cgColor
        bezierLayer.isOpaque = false
        layer.addSublayer(bezierLayer)
        
        let margin: CGFloat = 30
        startPoint = CGPoint(x: margin, y: frame.height / 2)
        endPoint = CGPoint(x: frame.width - margin, y: startPoint.y)
    }
    
    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        context.clear(rect)
        
        if shouldDrawLine {
            let cps = controlPoints.map { $0.point }
            drawBezierCurve(context, points: [startPoint] + cps + [endPoint], t: timeValue)
        }
        
        drawPoint(context, p: startPoint, color: .red, radius: 12)
        drawPoint(context, p: endPoint, color: .red, radius: 12)
        
        for controlPoint in controlPoints {
            drawPoint(context, p: controlPoint.point, color: UIColor.magenta, radius: 4)
        }
        
        let innerPoints = controlPoints.map { $0.point }
        let points = [startPoint] + innerPoints + [endPoint]
        if points.count >= 2 {
            drawLinesBetween(context, points, colorIndex: 0)
        }
    }
    
    private func drawBezierCurve(_ context: CGContext, points: [CGPoint], t: CGFloat) {
        
        var currentT: CGFloat = 0.0
        let step: CGFloat = 0.025
        
        UIColor.orange.setStroke()
        context.setLineWidth(4)
        context.move(to: pointOnCurve(with: points, t: 0))
        while currentT < t {
            let p = pointOnCurve(with: points, t: currentT)
            context.addLine(to: p)
            currentT += step
        }
        let p = pointOnCurve(with: points, t: t)
        context.addLine(to: p)
        
        context.strokePath()
        
    }
    
    private func pointOnCurve(with points: [CGPoint], t: CGFloat) -> CGPoint {
        
        guard let firstPoint = points.first else { fatalError() }
        
        if points.count == 1 {
            return firstPoint
        }
        
        
        var newPoints: [CGPoint] = []
        for i in 1..<points.count {
            let prev = points[i-1]
            let cur = points[i]
            let q = prev.lerp(cur, t: t)
            newPoints.append(q)
        }
        
        return pointOnCurve(with: newPoints, t: t)
    }
    
    private func drawLinesBetween(_ context: CGContext, _ points: [CGPoint], colorIndex: Int) {
        points.first.flatMap { context.move(to: $0) }
        points.dropFirst().forEach { context.addLine(to: $0 ) }
        
        context.setLineWidth(3)
        context.setLineDash(phase: 0, lengths: [2])
        UIColor.lightGray.setStroke()
        context.strokePath()
        
        if timeValue > 0 {
            let isLastStep = points.count == 2
            let colorIndex = isLastStep ? (colorList.count - 1) : colorIndex + 1
            let radius: CGFloat = isLastStep ? 12.0 : 6.0
            interpolateBetween(context, points, colorIndex: colorIndex, radius: radius)
        }
    }
    
    private func interpolateBetween(_ context: CGContext, _ points: [CGPoint], colorIndex: Int, radius: CGFloat) {
        guard points.count >= 2 else { return }
        
        var interpolated: [CGPoint] = []
        for i in 0 ..< points.count-1 {
            let p1 = points[i]
            let p2 = points[i+1]
            
            let t = p1.lerp(p2, t: timeValue)
            interpolated.append(t)
            let color = colorList[colorIndex]
            drawPoint(context, p: t, color: color, radius: 5)
        }
        
        if interpolated.count >= 2 {
            drawLinesBetween(context, interpolated, colorIndex: colorIndex)
        }
    }
    
    
    private func drawPoint(_ context: CGContext, p: CGPoint, color: UIColor, radius: CGFloat) {
        
        color.setFill()
        context.addArc(center: p, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        context.fillPath()
    }
    
    private func drawLine(_ context: CGContext, p1: CGPoint, p2: CGPoint, color: UIColor, width: CGFloat, dashed: Bool = false) {
        color.setStroke()
        context.setLineWidth(width)
        
        if dashed {
            context.setLineDash(phase: 0, lengths: [2])
        }
        
        context.move(to: p1)
        context.addLine(to: p2)
        context.strokePath()
    }
}


class BezierViewController : UIViewController {
    
    private var bezierView: BezierView!
    private var toolbar: UIToolbar!
    private var lineSwitch: UISwitch!
    private var timeSlider: UISlider!
    
    private var tapRecognizer: UITapGestureRecognizer!
    private var doubleTapRecognizer: UITapGestureRecognizer!
    private var panRecognizer: UIPanGestureRecognizer!
    
    private var dragPoint: ControlPoint?
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = .white
        
        toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(toolbar)
        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40)
        ])
        setupToolbar()
        
        bezierView = BezierView()
        bezierView.frame = view.bounds
        bezierView.backgroundColor = .white
        bezierView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bezierView)
        
        NSLayoutConstraint.activate([
            bezierView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bezierView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bezierView.topAnchor.constraint(equalTo: view.topAnchor),
            bezierView.bottomAnchor.constraint(equalTo: toolbar.topAnchor)
            ])
    }
    
    private func setupToolbar() {
        lineSwitch = UISwitch()
        lineSwitch.isOn = false
        lineSwitch.addTarget(self, action: #selector(lineSwitchChanged), for: .valueChanged)
        
        timeSlider = UISlider()
        timeSlider.minimumValue = 0
        timeSlider.maximumValue = 1.0
        timeSlider.isContinuous = true
        timeSlider.addTarget(self, action: #selector(timeSliderChanged), for: .valueChanged)
        timeSlider.frame.size.width = 200
        
        let switchBarItem = UIBarButtonItem(customView: lineSwitch)
        let sliderBarItem = UIBarButtonItem(customView: timeSlider)
        
        toolbar.items = [switchBarItem, sliderBarItem]
    }
    
    @objc
    private func lineSwitchChanged() {
        bezierView.shouldDrawLine = lineSwitch.isOn
    }
    
    @objc
    private func timeSliderChanged() {
        bezierView.timeValue = CGFloat(timeSlider.value)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
        doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        
        bezierView.addGestureRecognizer(tapRecognizer)
        bezierView.addGestureRecognizer(panRecognizer)
        bezierView.addGestureRecognizer(doubleTapRecognizer)
    }
    
    @objc
    private func tap(_ recognizer: UITapGestureRecognizer) {
        let pointInView = recognizer.location(in: bezierView)
        guard nearestControlPoint(at: pointInView, maxDistance: 44) == nil else { return }
        
        let cp = ControlPoint(point: pointInView)
        bezierView.controlPoints.append(cp)
    }
    
    @objc
    private func pan(_ recognizer: UIPanGestureRecognizer) {
        let location = recognizer.location(in: bezierView)
        switch recognizer.state {
        case .began:
            dragPoint = nearestControlPoint(at: location, maxDistance: 44)
            fallthrough
            
        case .changed:
            dragPoint?.point = location
            bezierView.setNeedsDisplay()
            
        case .cancelled, .ended:
            dragPoint = nil
            
        default:
            break
        }
    }
    
    @objc
    private func doubleTap(_ recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: bezierView)
        guard let controlPoint = nearestControlPoint(at: location, maxDistance: 44) else {
            return
        }
        
        if let index = bezierView.controlPoints.index(of: controlPoint) {
            bezierView.controlPoints.remove(at: index)
        }
    }
    
    private func nearestControlPoint(at location: CGPoint, maxDistance: CGFloat) -> ControlPoint? {
        let targetRect = CGRect(x: location.x - maxDistance,
                                y: location.y - maxDistance,
                                width: maxDistance * 2,
                                height: maxDistance * 2)
        
        return bezierView.controlPoints
            .filter { targetRect.contains($0.point) }
            .min { $0.point.distance(location) < $1.point.distance(location) }
    }
}

let vc = BezierViewController()
PlaygroundPage.current.liveView = vc


