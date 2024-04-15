//
//  PrayerTimingsResponse.swift
//  PrayerTimes
//
//  Created by Admin on 24/03/24.
//

import Foundation

struct PrayerTimingsResponse: Codable {
    let code: Int
    let status: String
    let data: [PrayerTimings]
}

struct PrayerTimings: Codable {
    let timings: Timings
    let date: DateInfo
//    let meta: Meta
}

struct Timings: Codable {
    let fajr: String?
    let sunrise: String?
    let dhuhr: String?
    let asr: String?
    let sunset: String?
    let maghrib: String?
    let isha: String?
    let imsak: String?
    let midnight: String?
    let firstthird: String?
    let lastthird: String?

    enum CodingKeys: String, CodingKey {
        case fajr = "Fajr"
        case sunrise = "Sunrise"
        case dhuhr = "Dhuhr"
        case asr = "Asr"
        case sunset = "Sunset"
        case maghrib = "Maghrib"
        case isha = "Isha"
        case imsak = "Imsak"
        case midnight = "Midnight"
        case firstthird = "Firstthird"
        case lastthird = "Lastthird"
    }
}

struct DateInfo: Codable {
    let readable: String
    let timestamp: String
    let gregorian: Gregorian
    let hijri: Hijri
}

struct Gregorian: Codable {
    let date: String
    let format: String
    let day: String
    let weekday: Weekday
    let month: Month
    let year: String
    let designation: Designation
}

struct Weekday: Codable {
    let en: String
}

struct Month: Codable {
    let number: Int
    let en: String
}

struct Designation: Codable {
    let abbreviated: String
    let expanded: String
}

struct Hijri: Codable {
    let date: String
    let format: String
    let day: String
    let weekday: Weekday
    let month: Month
    let year: String
    let designation: Designation
    let holidays: [String]
}

struct Meta: Codable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let method: Method
    let latitudeAdjustmentMethod: String
    let midnightMode: String
    let school: String
    let offset: Offset
}

struct Method: Codable {
    let id: Int
    let name: String
    let params: Params
    let location: Location
}

struct Params: Codable {
    let fajr: Int
    let isha: Int
}

struct Location: Codable {
    let latitude: Double
    let longitude: Double
}

struct Offset: Codable {
    let imsak: Int
    let fajr: Int
    let sunrise: Int
    let dhuhr: Int
    let asr: Int
    let maghrib: Int
    let sunset: Int
    let isha: Int
    let midnight: Int
}
