//
//  HealthManager.swift
//  Sleepeer
//
//  Created by Davide Perrotta on 14/02/25.
//

import Foundation
import SwiftUI
import HealthKit


class HealthManager: ObservableObject{
    
    //Inizializzazione di HealthStore
    let healthStore = HKHealthStore()
    
    @Published var timeInBed: TimeInterval = 0
    @Published var timeAwake: TimeInterval = 0
    @Published var timeRem: TimeInterval = 0
    @Published var timeCore: TimeInterval = 0
    @Published var timeDeep: TimeInterval = 0
    @Published var timeunspecified: TimeInterval = 0
    
    @Published var lastUpdatedDate: Date?
    
    //Variabile per tracciare se è stato autorizzato l'accesso a Healthkit
    @Published var isAuthorized: Bool = false
    
    func requestSleepAuthorization(){
        guard let sleepTypes = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            print("Recupero dei dati di sonno falliti");
            return
        }
        
        let healthTypes : Set<HKSampleType> = [sleepTypes]
        
        //Senza la successiva riga, alla prima apertura non viene richiesto l'accesso ai dati di Healthkit
        DispatchQueue.main.async {
            self.healthStore.requestAuthorization(toShare: healthTypes, read: healthTypes) { success, error in
                if success {
                    self.isAuthorized = false
                    print("La richiesta di autorizzazione ad HealthKit è stata accettata.")
                    self.fetchSleepdata()
                } else {
                    print("Errore durante la richiesta di autorizzazione a HealthKit: \(String(describing: error?.localizedDescription))")
                }
            }
        }
    }
    
    func fetchSleepdata(){
        guard let sleepTypes = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {return}
        
        let start = Calendar.current.date(byAdding: .second, value: -86400, to: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: [])
        
        let query = HKSampleQuery(sampleType: sleepTypes, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, error in
            guard let results = results as? [HKCategorySample], error == nil else {
                print("Errore nel recupero dei dati del sonno: \(error?.localizedDescription ?? "Errore sconosciuto")")
                return
            }
            self.processSleepData(results: results)
        }
        healthStore.execute(query)
    }
    
    func fetchSleepDataForAPI() async -> [String: Any] {
        return [
            "name": "\(Date())",
            "in_bed": Int(timeInBed),
            "awake": Int(timeAwake),
            "asleep_core": Int(timeCore),
            "asleep_deep": Int(timeDeep),
            "asleep_rem": Int(timeRem),
            "asleep_unspecified": Int(timeunspecified),
            "startDate": ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .second, value: -86400, to: Date())!),
            "endDate": ISO8601DateFormatter().string(from: Date())
        ]
    }

    // Funzione di supporto per convertire l'enum in stringa
    func getSleepStage(value: HKCategoryValueSleepAnalysis) -> String {
        switch value {
            case .inBed: return "inBed"
            case .asleep: return "asleep"
            case .awake: return "awake"
            case .asleepCore: return "asleepCore"
            case .asleepDeep: return "asleepDeep"
            case .asleepREM: return "asleepREM"
        case .asleepUnspecified: return "asleepUnspecified"
        @unknown default: return "unknown"
        }
    }
    
    func processSleepData(results: [HKCategorySample]) {
        var inBed: TimeInterval = 0
        var awake: TimeInterval = 0
        var rem: TimeInterval = 0
        var core: TimeInterval = 0
        var deep: TimeInterval = 0
        var asleepUnspecified: TimeInterval = 0

        for sample in results {
            let duration = sample.endDate.timeIntervalSince(sample.startDate)

            switch sample.value {
                case HKCategoryValueSleepAnalysis.inBed.rawValue:
                    inBed += duration
                case HKCategoryValueSleepAnalysis.awake.rawValue:
                    awake += duration
                case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                    rem += duration
                case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                    core += duration
                case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                    deep += duration
                case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                    asleepUnspecified += duration
                default:
                    break
            }
        }

        // Aggiorna @Published solo una volta
        DispatchQueue.main.async {
            self.timeInBed = inBed
            self.timeAwake = awake
            self.timeRem = rem
            self.timeCore = core
            self.timeDeep = deep
            self.timeunspecified = asleepUnspecified
            self.lastUpdatedDate = Date()
        }

        print("📊 Dati sonno aggiornati:")
        print("🛏️ A letto: \(inBed) sec \n 💤 REM: \(rem) sec \n 🌊 Core: \(core) sec \n 🏋️ Deep: \(deep) sec | 😴 Awake: \(awake) sec")
    }
    
    func saveSleepData(startDate: Date, endDate: Date) async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit non disponibile")
            return false
        }

        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            print("❌ Tipo di dato HealthKit non valido")
            return false
        }
        
        // Controlla i permessi prima di salvare
        let status = healthStore.authorizationStatus(for: sleepType)
        if status != .sharingAuthorized {
            print("❌ Permessi di scrittura HealthKit non concessi")
            return false
        }

        let sleepSample = HKCategorySample(
            type: sleepType,
            value: HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            start: startDate,
            end: endDate
        )

        do {
            try await healthStore.save([sleepSample])
            print("✅ Dati del sonno salvati con successo")
            return true
        } catch {
            print("❌ Errore nel salvataggio: \(error.localizedDescription)")
            return false
        }
    }

    // Funzione per aggiornare il tempo a letto
    func updateTimeInBed(_ newTime: TimeInterval) {
        timeInBed = newTime
        lastUpdatedDate = Date() // Aggiorna anche la data
    }
}
