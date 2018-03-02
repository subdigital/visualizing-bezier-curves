import UIKit
import PlaygroundSupport

extension CGPoint {
    func lerp(_ other: CGPoint, t: CGFloat) -> CGPoint {
        return CGPoint(
            x: (1-t)*x + t*other.x,
            y: (1-t)*y + t*other.y
        )
    }
}

class BezierView : UIView {
    
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
    
    public var control1:  CGPoint? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public var control2: CGPoint? {
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
        
        drawBezierParts(context)
        
        drawPoint(context, p: startPoint, color: .red, radius: 12)
        drawPoint(context, p: endPoint, color: .red, radius: 12)
        
        if let c1 = control1 {
            drawPoint(context, p: c1, color: .darkGray, radius: 8)
        }
        if let c2 = control2 {
            drawPoint(context, p: c2, color: .darkGray, radius: 8)
        }
    }
    
    private func drawBezierParts(_ context: CGContext) {
        guard let c1 = control1, let c2 = control2 else { return }
        
        context.move(to: startPoint)
        context.addLine(to: c1)
        context.addLine(to: c2)
        context.addLine(to: endPoint)
        
        UIColor.lightGray.setStroke()
        context.setLineWidth(2)
        context.setLineDash(phase: 0, lengths: [4])
        context.strokePath()

        if timeValue > 0{
            let t1 = startPoint.lerp(c1, t: timeValue)
            let t2 = c1.lerp(c2, t: timeValue)
            let t3 = c2.lerp(endPoint, t: timeValue)
            
            [t1, t2, t3].forEach {
                self.drawPoint(context, p: $0, color: .magenta, radius: 8)
            }
            context.move(to: t1)
            context.addLine(to: t2)
            context.addLine(to: t3)
            UIColor.magenta.setStroke()
            context.strokePath()
            
            let u1 = t1.lerp(t2, t: timeValue)
            let u2 = t2.lerp(t3, t: timeValue)
            
            [u1, u2].forEach {
                self.drawPoint(context, p: $0, color: .green, radius: 9)
            }
            
            context.move(to: u1)
            context.addLine(to: u2)
            UIColor.green.setStroke()
            context.strokePath()
            
            let v1 = u1.lerp(u2, t: timeValue)
            drawPoint(context, p: v1, color: .yellow, radius: 10)
        }
        
        drawBezierCurve(context)
    }
    
    private func drawBezierCurve(_ context: CGContext) {
        if let c1 = control1, let c2 = control2 {
            let path = UIBezierPath()
            path.move(to: startPoint)
            path.addCurve(to: endPoint, controlPoint1: c1, controlPoint2: c2)
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            bezierLayer.path = path.cgPath
            bezierLayer.strokeEnd = timeValue
            CATransaction.commit()
            
    
            if shouldDrawLine {
                context.setLineDash(phase: 0, lengths: [])
                context.setLineWidth(5)
                UIColor.white.setStroke()
                context.addPath(path.cgPath)
                context.strokePath()
            }
        }
    }
    
    private func drawPoint(_ context: CGContext, p: CGPoint, color: UIColor, radius: CGFloat) {
        color.setFill()
        context.addArc(center: p, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        context.fillPath()
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
    
    enum Point {
        case control1
        case control2
        
        var keyPath: ReferenceWritableKeyPath<BezierView, CGPoint?> {
            switch self {
            case .control1:
                return \BezierView.control1
            case .control2:
                return \BezierView.control2
            }
        }
    }
    private var dragPoint: Point?
    
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
        guard point(at: pointInView) == nil else {
            return
        }
            
        if bezierView.control1 == nil {
            bezierView.control1 = pointInView
        } else if bezierView.control2 == nil {
            bezierView.control2 = pointInView
        }
    }
    
    @objc
    private func pan(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            dragPoint = point(at: recognizer.location(in: bezierView))
            fallthrough
            
        case .changed:
            guard let p = dragPoint else { return }
            bezierView[keyPath: p.keyPath] = recognizer.location(in: bezierView)
            
        case .cancelled, .ended:
            dragPoint = nil
            
        default:
            break
        }
    }
    
    @objc
    private func doubleTap(_ recognizer: UITapGestureRecognizer) {
        guard let point = point(at: recognizer.location(in: bezierView)) else {
            return
        }
        bezierView[keyPath: point.keyPath] = nil
    }
    
    private func point(at location: CGPoint) -> Point? {
        let touchRadius: CGFloat = 44
        let points = [
            (bezierView.control1, Point.control1),
            (bezierView.control2, Point.control2)
        ]
        
        let clickRect = CGRect(x: location.x - touchRadius,
                                y: location.y - touchRadius,
                                width: touchRadius * 2,
                                height: touchRadius * 2)

        return points
            .first { pair in
                guard let p = pair.0 else { return false }
                return clickRect.contains(p)
            }
            .flatMap { $0.1 }
    }
}

let vc = BezierViewController()
PlaygroundPage.current.liveView = vc

