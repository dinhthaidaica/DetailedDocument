//
//  LunarV - Lich Am Viet Nam
//  Phat trien boi Pham Hung Tien
//
import Foundation

struct LunarPhase: Equatable {
    let icon: String
    let name: String

    static func from(day lunarDay: Int) -> LunarPhase {
        switch lunarDay {
        case 1, 30:
            return LunarPhase(icon: "moonphase.new.moon", name: "Trăng mới")
        case 2 ... 7:
            return LunarPhase(icon: "moonphase.waxing.crescent", name: "Trăng lưỡi liềm")
        case 8:
            return LunarPhase(icon: "moonphase.first.quarter", name: "Trăng bán nguyệt đầu tháng")
        case 9 ... 14:
            return LunarPhase(icon: "moonphase.waxing.gibbous", name: "Trăng khuyết đầu tháng")
        case 15:
            return LunarPhase(icon: "moonphase.full.moon", name: "Trăng tròn")
        case 16 ... 22:
            return LunarPhase(icon: "moonphase.waning.gibbous", name: "Trăng khuyết cuối tháng")
        case 23:
            return LunarPhase(icon: "moonphase.last.quarter", name: "Trăng bán nguyệt cuối tháng")
        case 24 ... 29:
            return LunarPhase(icon: "moonphase.waning.crescent", name: "Trăng lưỡi liềm cuối tháng")
        default:
            return LunarPhase(icon: "moon.fill", name: "--")
        }
    }
}
