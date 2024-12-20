//
//  AppointmentsListViewController.swift
//  StudioManager
//
//  Created by Dmytro Yaremyshyn on 22/09/2024.
//

import UIKit
import Combine

public class AppointmentsListViewController: UIViewController {
    
    private var cancellables = Set<AnyCancellable>()
    var viewModel: AppointmentsListViewModel? {
        didSet { bind() }
    }
    private var dataSource: AppointmentsDiffableDataSource?
    
    // MARK: - UI
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(AppointmentsViewCell.self, forCellReuseIdentifier: AppointmentsViewCell.reuseIdentifier)
        tableView.delegate = self
        return tableView
    }()
    
    private lazy var segmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(items: [
            "Hoje",
            "Semana",
            "Mês",
            "Todas"])
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector (segmentedControlValueChanged), for: .valueChanged)
        return segmentedControl
    }()
   
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupDataSource()
        setupView()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel?.fetchAppointments()
    }
    
    private func setupDataSource() {
        dataSource = AppointmentsDiffableDataSource(
            tableView: tableView,
            viewModel: viewModel,
            cellProvider: { tableView, indexPath, appointment in
                let cell = tableView.dequeueReusableCell(withIdentifier: AppointmentsViewCell.reuseIdentifier, for: indexPath) as! AppointmentsViewCell
                cell.configure(model: appointment)
                return cell
            }
        )
        dataSource?.defaultRowAnimation = .fade
        tableView.dataSource = dataSource
    }

    private func setupView() {
        title = "Marcações"
        view.backgroundColor = .systemBackground
        view.addSubview(segmentedControl)
        view.addSubview(tableView)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "calendar.badge.plus"), style: .done, target: self, action: #selector(saveToCalendarTapped)) 
        
        segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
        
        tableView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    private func bind() {
        viewModel?.$appointments
            .receive(on: DispatchQueue.main)
            .sink { [weak self] appointments in
                guard let self else { return }
                self.applySnapshot(appointments: appointments)
            }
            .store(in: &cancellables)
        
        viewModel?.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                guard let self, let message = errorMessage else { return }
                showErrorDialog(title: "Erro", message: message, cancelTitle: "Cancelar")
            }
            .store(in: &cancellables)
        
        viewModel?.$successMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] successMessage in
                guard let self, let message = successMessage else { return }
                showSuccessDialog(title: "Sucesso", message: message)
            }
            .store(in: &cancellables)
    }
    
    private func applySnapshot(appointments: [StudioAppointment]) {
        var snapshot = NSDiffableDataSourceSnapshot<StudioSection, StudioAppointment>()
        
        snapshot.appendSections([.main])
        snapshot.appendItems(appointments, toSection: .main)
        
        dataSource?.apply(snapshot, animatingDifferences: true)
    }
}

// MARK: - Filter calendar
extension AppointmentsListViewController {
    
    @objc private func segmentedControlValueChanged() {
        let filterCalendar = FilterCalendar(rawValue: segmentedControl.selectedSegmentIndex) ?? .today
        viewModel?.filterAppointments(by: filterCalendar)
    }
}

// MARK: - Add to calendar
extension AppointmentsListViewController {
    
    @objc private func saveToCalendarTapped() {
        viewModel?.addAppointmentsToCalendar()
    }
}

// MARK: - UITableViewDelegate - didSelectRowAt
extension AppointmentsListViewController: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let selectedAppointment = dataSource?.itemIdentifier(for: indexPath) {
            viewModel?.goToAppointmentDetails(appointment: selectedAppointment)
        }
    }
}
