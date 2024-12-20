//
//  AppointmentsListViewModel.swift
//  StudioManager
//
//  Created by Dmytro Yaremyshyn on 22/09/2024.
//

import Foundation

class AppointmentsListViewModel: ObservableObject {
    private var allAppointments: [StudioAppointment] = []
    @Published private(set) var appointments: [StudioAppointment] = []
    @Published private(set) var errorMessage: String? = nil
    @Published private(set) var successMessage: String? = nil
    weak var coordinator: AppointmentsListCoordinator?
    private var filterCalendar: FilterCalendar = .today
    
    private let persistenceService: AppointmentPersistenceLoader
    
    init(persistenceService: AppointmentPersistenceLoader) {
        self.persistenceService = persistenceService
    }
    
    public func fetchAppointments() {
        allAppointments = persistenceService.getStudioAppointments()
        errorMessage = nil
        
#if DEBUG
        allAppointments = allAppointments.count == 0 ? Appointment.allCustomers : allAppointments
#endif
        filterAppointments(by: filterCalendar)
    }
    
    public func filterAppointments(by filterCalendar: FilterCalendar) {
        self.filterCalendar = filterCalendar
        appointments = FilterCalendarHelper.filter(by: filterCalendar, appointments: allAppointments)
    }
    
    public func goToAppointmentDetails(appointment: StudioAppointment) {
        coordinator?.goToAppointmentDetails(appointment: appointment)
    }
    
    public func removeAppointment(index: Int) {
        let appointment = appointments[index]
        // First remove the appointment from persistence
        let success = persistenceService.deleteStudioAppointment(appointment: appointment)
        guard success else {
            errorMessage = "Erro ao apagar marcação"
            return
        }
        // Remove the appointment from both the current appointments array and the allAppointments array
        appointments.remove(at: index)
        if let allAppointmentsIndex = allAppointments.firstIndex(where: { $0.id == appointment.id }) {
            allAppointments.remove(at: allAppointmentsIndex)
        }
    }
    
    public func addAppointmentsToCalendar() {
        let addCalendarAppointments = allAppointments.filter { !$0.addedToCalendar }
        self.successMessage = addCalendarAppointments.isEmpty ? "Nenhuma marcação para adicionar ao calendário." : nil
        addCalendarAppointments.forEach { appointment in
            CalendarEventHelper.createEvent(to: appointment) { [weak self] result in
                self?.errorMessage = result == false ? "An error occurred saving the appointment to your calendar." : nil
                self?.successMessage = result ? "Todas as marcações foram adicionadas ao calendário com sucesso." : nil
            }
            appointmentsAddedToCalendar(appointment: appointment, index: allAppointments.firstIndex(where: { $0.id == appointment.id }))
        }
    }
    
    private func appointmentsAddedToCalendar(appointment: StudioAppointment, index: Int?) {
        guard let index else { return }
        let updatedAppointment = StudioAppointment(
            id: appointment.id,
            date: appointment.date,
            price: appointment.price,
            type: appointment.type,
            inResidence: appointment.inResidence,
            name: appointment.name,
            phoneNumber: appointment.phoneNumber,
            duration: appointment.duration,
            addedToCalendar: true
        )
        self.allAppointments[index] = updatedAppointment
        persistenceService.saveStudioAppointment(appointment: updatedAppointment)
    }
}
