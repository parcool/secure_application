import Flutter
import UIKit

public class SwiftSecureApplicationPlugin: NSObject, FlutterPlugin {
    var secured = false
    var opacity: CGFloat = 0.2

    var backgroundTask: UIBackgroundTaskIdentifier!

    internal let registrar: FlutterPluginRegistrar
    private var methodChannel: FlutterMethodChannel?

    init(registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
        super.init()
        registrar.addApplicationDelegate(self)
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "secure_application",
            binaryMessenger: registrar.messenger()
        )
        let instance = SwiftSecureApplicationPlugin(registrar: registrar)
        instance.methodChannel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    // 当应用已进入 Active 状态时（在前台并接收事件）
    public func applicationDidBecomeActive(_ application: UIApplication) {
        print("iOS App: Did Become Active")
        // 可以通过 channel 将状态发送给 Dart 端
        methodChannel?.invokeMethod(
            "appLifecycleStateChanged",
            arguments: "active"
        )
    }

    // 当应用即将进入后台时
    public func applicationWillResignActive(_ application: UIApplication) {
        print("iOS App: Will Resign Active")
        methodChannel?.invokeMethod(
            "appLifecycleStateChanged",
            arguments: "inactive"
        )
        if secured {
            self.registerBackgroundTask()
            UIApplication.shared.ignoreSnapshotOnNextApplicationLaunch()
            if let window = UIApplication.shared.windows.filter({ (w) -> Bool in
                return w.isHidden == false
            }).first {
                if let existingView = window.viewWithTag(99699),
                    let existingBlurrView = window.viewWithTag(99698)
                {
                    window.bringSubviewToFront(existingView)
                    window.bringSubviewToFront(existingBlurrView)
                    return
                } else {
                    let colorView = UIView(frame: window.bounds)
                    colorView.tag = 99699
                    colorView.autoresizingMask = [
                        .flexibleWidth, .flexibleHeight,
                    ]
                    colorView.backgroundColor = UIColor(
                        white: 1,
                        alpha: opacity
                    )
                    window.addSubview(colorView)
                    window.bringSubviewToFront(colorView)

                    let blurEffect = UIBlurEffect(
                        style: UIBlurEffect.Style.extraLight
                    )
                    let blurEffectView = UIVisualEffectView(effect: blurEffect)
                    blurEffectView.frame = window.bounds
                    blurEffectView.autoresizingMask = [
                        .flexibleWidth, .flexibleHeight,
                    ]

                    blurEffectView.tag = 99698

                    window.addSubview(blurEffectView)
                    window.bringSubviewToFront(blurEffectView)

                    // MARK: - 添加图标和文字

                    // 1. 创建图标视图
                    let bundle = Bundle(for: type(of: self))
                    var iconImageView: UIImageView?

                    // ====== 重点修改这里：更明确地获取插件的 Bundle ======
                    // 获取当前 SwiftSecureApplicationPlugin 类所在的 Bundle
                    let currentBundle = Bundle(for: type(of: self))
                    // 获取当前 Bundle 中名为 "secure_application.bundle" 的 Bundle (通常插件会打包成一个 .bundle 文件)
                    // 如果你的插件名称是 secure_application，那么对应的资源包通常是 secure_application.bundle
                    var resourceBundle: Bundle? = nil
                    if let resourceBundlePath = currentBundle.path(
                        forResource: "secure_application",
                        ofType: "bundle"
                    ) {
                        resourceBundle = Bundle(path: resourceBundlePath)
                    }

                    if let image = UIImage(
                        named: "SecureLogo",
                        in: resourceBundle ?? currentBundle,
                        compatibleWith: nil
                    ) {
                        iconImageView = UIImageView(image: image)
                        iconImageView?.contentMode = .scaleAspectFit
                        // 设置图标的固定大小，例如 16x16pt
                        iconImageView?
                            .translatesAutoresizingMaskIntoConstraints = false
                        iconImageView?.widthAnchor.constraint(
                            equalToConstant: 20
                        ).isActive = true  // 调整图标宽度
                        iconImageView?.heightAnchor.constraint(
                            equalToConstant: 20
                        ).isActive = true  // 调整图标高度
                    } else {
                        print(
                            "Error: Icon 'SecureLogo' not found in plugin bundle."
                        )
                    }

                    // 2. 创建文字标签
                    let textLabel = UILabel()
                    textLabel.text = "您的应用已锁定"  // 你的文字内容
                    textLabel.textColor = .darkGray
                    textLabel.font = UIFont.systemFont(ofSize: 15)  // 调整字体大小
                    textLabel.textAlignment = .left  // 在 StackView 中，子视图的对齐通常由 StackView 管理，但这里设为 left 也无妨

                    // 3. 创建 UIStackView
                    let stackView = UIStackView()
                    stackView.axis = .horizontal  // 水平排列
                    stackView.alignment = .center  // 垂直居中对齐（针对子视图）
                    stackView.spacing = 8  // 图标和文字之间的间距
                    stackView.tag = 99695  // 给 StackView 一个tag

                    if let icon = iconImageView {
                        stackView.addArrangedSubview(icon)
                    }
                    stackView.addArrangedSubview(textLabel)

                    // 4. 将 StackView 添加到 window 并居中
                    window.addSubview(stackView)
                    window.bringSubviewToFront(stackView)

                    // 使用 Auto Layout 居中 StackView
                    stackView.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        stackView.centerXAnchor.constraint(
                            equalTo: window.centerXAnchor
                        ),
                        stackView.centerYAnchor.constraint(
                            equalTo: window.centerYAnchor
                        ),
                    ])

                    // MARK: - 结束添加

                    window.snapshotView(afterScreenUpdates: true)
                    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.3))
                }
            }
            self.endBackgroundTask()
        }
    }

    func registerBackgroundTask() {
        self.backgroundTask = UIApplication.shared.beginBackgroundTask {
            [weak self] in
            self?.endBackgroundTask()
        }
        assert(self.backgroundTask != UIBackgroundTaskIdentifier.invalid)
    }

    func endBackgroundTask() {
        print("Background task ended.")
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = UIBackgroundTaskIdentifier.invalid
    }

    public func handle(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        if call.method == "secure" {
            secured = true
            if let args = call.arguments as? [String: Any],
                let opacity = args["opacity"] as? NSNumber
            {
                self.opacity = opacity as! CGFloat
            }
        } else if call.method == "open" {
            secured = false
        } else if call.method == "opacity" {
            if let args = call.arguments as? [String: Any],
                let opacity = args["opacity"] as? NSNumber
            {
                self.opacity = opacity as! CGFloat
            }
        } else if call.method == "unlock" {
            unlock()
        }
    }

    func unlock() {
        print("start unlock!!!")
        if let window = UIApplication.shared.windows.filter({ (w) -> Bool in
            return w.isHidden == false
        }).first,
            let colorView = window.viewWithTag(99699),
            let blurrView = window.viewWithTag(99698),
            let combinedView = window.viewWithTag(99695)  // 获取组合视图
        {
            UIView.animate(
                withDuration: 0.3,
                animations: {
                    colorView.alpha = 0.0
                    blurrView.alpha = 0.0
                    combinedView.alpha = 0.0  // 动画移除组合视图
                },
                completion: { finished in
                    colorView.removeFromSuperview()
                    blurrView.removeFromSuperview()
                    combinedView.removeFromSuperview()  // 移除组合视图
                }
            )
        }
    }
}
