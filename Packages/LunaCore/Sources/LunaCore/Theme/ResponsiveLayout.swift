import CoreGraphics

public enum LayoutBreakpoint: Comparable {
    case phone, tablet, large, xlarge

    public static func from(width: CGFloat) -> LayoutBreakpoint {
        if width >= 1440 { return .xlarge }
        if width >= 1024 { return .large }
        if width >= 768  { return .tablet }
        return .phone
    }
}

public struct ResponsiveMetrics {
    public let breakpoint: LayoutBreakpoint
    public let horizontalPadding: CGFloat
    public let posterWidth: CGFloat
    public let posterHeight: CGFloat
    public let landscapeWidth: CGFloat
    public let landscapeHeight: CGFloat
    public let continueWatchingWidth: CGFloat
    public let continueWatchingHeight: CGFloat
    public let fontScaleMultiplier: CGFloat

    public init(for width: CGFloat) {
        let bp = LayoutBreakpoint.from(width: width)
        self.breakpoint = bp
        switch bp {
        case .phone:
            horizontalPadding = 16
            posterWidth = 120; posterHeight = 180
            landscapeWidth = 200; landscapeHeight = 112
            continueWatchingWidth = 192; continueWatchingHeight = 108
            fontScaleMultiplier = 1.0
        case .tablet:
            horizontalPadding = 24
            posterWidth = 140; posterHeight = 210
            landscapeWidth = 240; landscapeHeight = 135
            continueWatchingWidth = 220; continueWatchingHeight = 124
            fontScaleMultiplier = 1.05
        case .large:
            horizontalPadding = 28
            posterWidth = 160; posterHeight = 240
            landscapeWidth = 280; landscapeHeight = 158
            continueWatchingWidth = 250; continueWatchingHeight = 141
            fontScaleMultiplier = 1.1
        case .xlarge:
            horizontalPadding = 32
            posterWidth = 180; posterHeight = 270
            landscapeWidth = 320; landscapeHeight = 180
            continueWatchingWidth = 280; continueWatchingHeight = 158
            fontScaleMultiplier = 1.15
        }
    }
}
