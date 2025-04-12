//
//  HealthManager.swift
//  prova
//
//  Created by Davide Perrotta on 11/04/25.
//

import SwiftUI
import HealthKit


@MainActor
class HealthManager: ObservableObject {
    // HealthKit store per accedere ai dati sanitari
    let healthStore = HKHealthStore()
    
    // Singleton per accedere facilmente all'istanza
    static let shared = HealthManager()

    // Stato dell'autorizzazione
    @Published var isAuthorized: Bool = false
    @Published var sleepAccessGranted: Bool = false
    
    // Report del sonno aggiornato
    @Published var sleepReport: SleepReport?
    
    // Timer per aggiornamenti periodici
    @State private var timer: Timer?

    // Rappresenta un intervallo di risveglio
    struct WakeInterval: Identifiable {
        let id = UUID() // Identificativo univoco per SwiftUI
        let start: Date
        let end: Date
        var duration: TimeInterval {
            end.timeIntervalSince(start) // Calcola durata
        }
    }

    // Report complessivo del sonno
    struct SleepReport {
        let wakeIntervals: [WakeInterval] // Tutti i risvegli
        let totalSleepTime: TimeInterval  // Tempo totale di sonno

        // Formatta il tempo totale in ore e minuti
        var formattedTotalSleep: String {
            let hours = Int(totalSleepTime) / 3600
            let minutes = (Int(totalSleepTime) % 3600) / 60
            return "\(hours)h \(minutes)m"
        }
    }

    // Richiede autorizzazione per accedere ai dati del sonno
    func requestAuthorization() async {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            print("❌ Tipo sonno non trovato")
            return
        }

        let readTypes: Set<HKSampleType> = [sleepType] // Solo lettura

        do {
            // Richiede l'autorizzazione con continuazione asincrona
            let success = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
                healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: success)
                    }
                }
            }

            // Aggiorna stato autorizzazione
            self.isAuthorized = success
            self.sleepAccessGranted = success

            // Log
            if success {
                print("✅ Autorizzazione concessa")
            } else {
                print("❌ Autorizzazione negata")
            }
        } catch {
            print("❌ Errore richiesta autorizzazione: \(error.localizedDescription)")
        }
    }

    // Genera un report del sonno degli ultimi 7 giorni
    func generateSleepReport() async -> SleepReport? {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }

        // Imposta l'intervallo di 7 giorni
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let endDate = Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)

        // Crea il descrittore per la query
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: sleepType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
        )

        do {
            // Esegue la query
            let results = try await descriptor.result(for: healthStore)

            var wakeIntervals: [WakeInterval] = []
            var totalSleepTime: TimeInterval = 0

            // Analizza ogni campione
            for sample in results.compactMap({ $0 as? HKCategorySample }) {
                switch sample.value {
                case HKCategoryValueSleepAnalysis.awake.rawValue:
                    // Salva intervallo di risveglio
                    wakeIntervals.append(WakeInterval(start: sample.startDate, end: sample.endDate))
                case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                     HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                     HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                     HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                    // Aggiunge tempo dormito
                    totalSleepTime += sample.endDate.timeIntervalSince(sample.startDate)
                default:
                    break
                }
            }

            // Crea il report
            let report = SleepReport(wakeIntervals: wakeIntervals, totalSleepTime: totalSleepTime)

            // Aggiorna il @Published su MainActor
            await MainActor.run {
                self.sleepReport = report
            }

            return report

        } catch {
            print("❌ Errore durante la query dei dati di sonno: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Avvia un timer che aggiorna il report ogni secondo
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task {
                if let report = await self.generateSleepReport() {
                    // Log dettagliato per ogni aggiornamento
                    print("🛏️ Sonno totale: \(report.formattedTotalSleep)")
                    print("⏰ Risvegli: \(report.wakeIntervals.count)")
                    for interval in report.wakeIntervals {
                        print("• Da \(interval.start.formatted()) a \(interval.end.formatted()) - Durata: \(Int(interval.duration / 60)) minuti")
                    }
                } else {
                    print("⚠️ Nessun dato di sonno disponibile.")
                }
            }
        }
    }
    
    // Ferma il timer
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
