//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
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
        .description("Xem nhanh ngày âm lịch, can chi, tiết khí và thông tin dương lịch theo phong cách LunarV.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
