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
            posterWidth = 125; posterHeight = 185
            landscapeWidth = 220; landscapeHeight = 124
            continueWatchingWidth = 240; continueWatchingHeight = 145
            fontScaleMultiplier = 1.0
        case .tablet:
            horizontalPadding = 24
            posterWidth = 145; posterHeight = 215
            landscapeWidth = 280; landscapeHeight = 158
            continueWatchingWidth = 260; continueWatchingHeight = 155
            fontScaleMultiplier = 1.05
        case .large:
            horizontalPadding = 28
            posterWidth = 165; posterHeight = 245
            landscapeWidth = 280; landscapeHeight = 158
            continueWatchingWidth = 270; continueWatchingHeight = 160
            fontScaleMultiplier = 1.1
        case .xlarge:
            horizontalPadding = 32
            posterWidth = 185; posterHeight = 275
            landscapeWidth = 320; landscapeHeight = 180
            continueWatchingWidth = 300; continueWatchingHeight = 170
            fontScaleMultiplier = 1.15
        }
    }
}
