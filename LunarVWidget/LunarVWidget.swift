//
//  LunarV - Lich Am Viet Nam
//  Phat trien boi Pham Hung Tien
//
import WidgetKit
import SwiftUI

struct LunarVWidget: Widget {
    let kind: String = "LunarVWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LunarTimelineProvider()) { entry in
            LunarWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Lịch Âm LunarV")
        .description("Xem nhanh ngày âm lịch, can chi và tiết khí.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
