//
//  StudioAppointment.swift
//  StudioManager
//
//  Created by Dmytro Yaremyshyn on 10/10/2024.
//

import Foundation

enum StudioSection: CaseIterable {
    case main
}

public struct StudioAppointment: Equatable, Identifiable, Hashable {
    public let id: UUID
    let date: Date
    let price: Double
    let type: String 
    let inResidence: Bool
    let name: String
    let phoneNumber: String?
    let duration: Double
    let addedToCalendar: Bool
        
    public static func map(appointment: StudioEntity) -> StudioAppointment {
        StudioAppointment(
            id: appointment.id ?? UUID(),
            date: appointment.date!,
            price: appointment.price,
            type: appointment.type ?? "Maquilhagem",
            inResidence: appointment.inResidence,
            name: appointment.name ?? "Sem nome",
            phoneNumber: appointment.phoneNumber,
            duration: appointment.duration,
            addedToCalendar: appointment.addedToCalendar
        )
    }
    
    public static func == (lhs: StudioAppointment, rhs: StudioAppointment) -> Bool {
        return lhs.id == rhs.id && lhs.date == rhs.date && lhs.price == rhs.price &&
        lhs.type == rhs.type && lhs.inResidence == rhs.inResidence && lhs.name == rhs.name &&
        lhs.phoneNumber == rhs.phoneNumber && lhs.addedToCalendar == rhs.addedToCalendar
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(date)
        hasher.combine(type)
        hasher.combine(inResidence)
        hasher.combine(name)
        hasher.combine(phoneNumber)
        hasher.combine(addedToCalendar)
    }
}
