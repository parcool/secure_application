import Flutter
import UIKit

public class SwiftSecureApplicationPlugin: NSObject, FlutterPlugin {
    var secured = false
    var opacity: CGFloat = 0.2

    var backgroundTask: UIBackgroundTaskIdentifier!

    internal let registrar: FlutterPluginRegistrar
    private var methodChannel: FlutterMethodChannel?
    var lockedDisplayMessage: String = "您的应用已锁定"

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

    // 当应用即将进入后台时（原始：applicationWillResignActive）
    public func applicationDidEnterBackground(_ application: UIApplication) {
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
                        style: UIBlurEffect.Style.regular
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
                    var iconImageView: UIImageView?

                    // ====== 最终修改：直接从主应用程序的 main Bundle 加载资源 ======
                    // 因为你已经把 SecureLogo 放到 Runner 的 Assets.xcassets 里了
                    // 所以直接使用 Bundle.main 来查找是正确的。
                    let mainBundle = Bundle.main

                    if let image = UIImage(
                        named: "SecuredIcon",
                        in: mainBundle,
                        compatibleWith: nil
                    ) {
                        iconImageView = UIImageView(image: image)
                        iconImageView?.contentMode = .scaleAspectFit
                        iconImageView?
                            .translatesAutoresizingMaskIntoConstraints = false
                        iconImageView?.widthAnchor.constraint(
                            equalToConstant: 20
                        ).isActive = true
                        iconImageView?.heightAnchor.constraint(
                            equalToConstant: 20
                        ).isActive = true
                    } else {
                        print("Error: Icon 'SecureLogo' not found.")
                        print(
                            "Attempted to load from Main Bundle path: \(mainBundle.bundlePath)"
                        )
                        if let assetsPath = mainBundle.path(
                            forResource: "Assets",
                            ofType: "car"
                        ) {
                            print(
                                "Main Bundle Assets.car found at: \(assetsPath)"
                            )
                        } else {
                            print("Main Bundle Assets.car NOT found.")
                        }
                    }

                    // 2. 创建文字标签
                    let textLabel = UILabel()
                    textLabel.text = self.lockedDisplayMessage  // 你的文字内容
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
                            equalTo: window.bottomAnchor,
                            constant: -38
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
            if let args = call.arguments as? [String: Any] {
                if let opacity = args["opacity"] as? NSNumber {
                    self.opacity = opacity as! CGFloat
                }
                if let lockedText = args["lockedText"] as? String {
                    self.lockedDisplayMessage = lockedText
                    updateOverlayTextIfVisible(lockedText)
                }
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

    private func updateOverlayTextIfVisible(_ text: String) {
        guard let window = UIApplication.shared.windows.first(where: { !$0.isHidden }),
              let stackView = window.viewWithTag(99695) as? UIStackView else {
            return
        }
        for subview in stackView.arrangedSubviews {
            if let label = subview as? UILabel {
                label.text = text
                break
            }
        }
    }

    func unlock() {
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
