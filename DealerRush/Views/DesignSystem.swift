import SwiftUI

enum Theme {
    static let background = Color(red: 0.025, green: 0.055, blue: 0.048)
    static let panel = Color(red: 0.085, green: 0.115, blue: 0.105)
    static let forest = Color(red: 0.05, green: 0.22, blue: 0.16)
    static let ivory = Color(red: 0.96, green: 0.94, blue: 0.88)
    static let muted = Color(red: 0.61, green: 0.65, blue: 0.61)
    static let gold = Color(red: 0.88, green: 0.70, blue: 0.43)
    static let red = Color(red: 0.79, green: 0.16, blue: 0.16)
}
struct Panel<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content.padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.panel, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.08)))
    }
}
struct PrimaryButton: View {
    let title: String
    var enabled = true
    let action: () -> Void
    var body: some View {
        Button { Feedback.tap(); action() } label: {
            Text(title).font(.headline).frame(maxWidth: .infinity).frame(minHeight: 54)
        }
        .foregroundStyle(Theme.ivory)
        .background(enabled ? Theme.red.gradient : Theme.panel.gradient, in: RoundedRectangle(cornerRadius: 16))
        .disabled(!enabled)
    }
}
struct ScreenTitle: View {
    let eyebrow: String
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow.uppercased()).font(.caption.weight(.semibold)).tracking(2).foregroundStyle(Theme.gold)
            Text(title).font(.system(.largeTitle, design: .serif, weight: .bold)).foregroundStyle(Theme.ivory)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
struct RatingHeroCard: View {
    let rating: Int
    private var progress: TierProgress { ScoreCalculator.tierProgress(rating) }
    var body: some View {
        Panel {
            VStack(alignment: .leading, spacing: 12) {
                Text("Dealer Rating").font(.subheadline).foregroundStyle(Theme.ivory)
                HStack(alignment: .center, spacing: 15) {
                    Image(systemName: "crown.fill").font(.system(size: 31)).foregroundStyle(Theme.gold)
                    Text(rating.formatted()).font(.system(size: 43, weight: .bold, design: .rounded)).foregroundStyle(Theme.ivory)
                        .minimumScaleFactor(0.7).lineLimit(1)
                }
                Text(progress.name).font(.subheadline.weight(.medium)).foregroundStyle(Theme.gold)
                ProgressView(value: progress.fraction).tint(Theme.gold)
                if let next = progress.nextThreshold {
                    HStack {
                        Text("다음 등급까지 \(progress.remaining)점")
                        Spacer()
                        Text(next.formatted())
                    }.font(.caption).foregroundStyle(Theme.muted)
                } else {
                    Text("최고 등급 달성").font(.caption).foregroundStyle(Theme.muted)
                }
            }
        }
        .background(Theme.forest.opacity(0.25), in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }
}
extension View {
    func rushBackground() -> some View {
        background {
            Theme.background.ignoresSafeArea()
                .overlay(alignment: .topTrailing) { Circle().fill(Theme.forest.opacity(0.45)).frame(width: 320).blur(radius: 110).offset(x: 120, y: -100) }
        }
        .tint(Theme.ivory)
        .preferredColorScheme(.dark)
    }
}
