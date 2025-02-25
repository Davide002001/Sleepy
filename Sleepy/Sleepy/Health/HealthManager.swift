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
    
    init()
    {
        requestSleepAuthorization()
        fetchSleepdata()
    }
    
    
    func requestSleepAuthorization(){
        guard let sleepTypes = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            print("Recupero dei dati di sonno falliti");
            return
        }
        
        let healthTypes : Set<HKSampleType> = [sleepTypes]
        
        
        healthStore.requestAuthorization(toShare: healthTypes, read: healthTypes) { success, error in
                DispatchQueue.main.async {
                    self.isAuthorized = true
                    if success {
                        print("✅ Autorizzazione concessa")
                        self.fetchSleepdata()
                    } else {
                        print("❌ Autorizzazione negata: \(error?.localizedDescription ?? "Nessun dettaglio")")
                }
            }
        }
    }
    
    func fetchSleepdata() {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return }
            
        let calendar = Calendar.current
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)
        let yesterdayStart = calendar.date(byAdding: .second, value: -86400, to: todayStart)!
            
        let sleepStartTime = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: yesterdayStart)!
        let sleepEndTime = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: todayStart)!
            
        let predicate = HKQuery.predicateForSamples(withStart: sleepStartTime, end: sleepEndTime, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, results, error in
            guard let results = results as? [HKCategorySample], error == nil else {
                print("❌ Errore nel recupero dei dati del sonno: \(error?.localizedDescription ?? "Sconosciuto")")
                return
            }
            DispatchQueue.main.async {
                self.processSleepData(results: results)
            }
        }
        healthStore.execute(query)
    }
    
    func addSleepData(startDate: Date, endDate: Date) async -> Bool {
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let calendar = Calendar.current
        
        // Intervallo consentito: 18:00 di ieri - 11:00 di oggi
        let todayStart = calendar.startOfDay(for: Date())
        let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart)!
        
        let sleepStartTime = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: yesterdayStart)!
        let sleepEndTime = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: todayStart)!
        
        // ✅ Controllo che i dati siano nel range consentito
        guard startDate >= sleepStartTime, endDate <= sleepEndTime else {
            print("⛔ Errore: Il periodo selezionato (\(startDate) - \(endDate)) è fuori dal range (\(sleepStartTime) - \(sleepEndTime)).")
            return false
        }
        
        // Crea il campione di sonno
        let sample = HKCategorySample(
            type: sleepType,
            value: HKCategoryValueSleepAnalysis.inBed.rawValue,
            start: startDate,
            end: endDate
        )
        
        // ✅ Salvataggio su HealthKit in modo asincrono
        do {
            try await healthStore.save(sample)
            print("✅ Dati del sonno salvati correttamente: \(startDate) - \(endDate)")
            fetchSleepdata() // Aggiorna i dati dopo il salvataggio
            return true
        } catch {
            print("❌ Errore salvataggio dati: \(error.localizedDescription)")
            return false
        }
    }

    func fetchSleepDataForAPI() async -> [String: Any] {
        guard let lastDate = lastUpdatedDate else {
            print("❌ Nessun dato aggiornato")
            return [:]
        }
        
        return [
            "name": "\(lastDate)",
            "in_bed": Int(timeInBed),
            "awake": Int(timeAwake),
            "asleep_core": Int(timeCore),
            "asleep_deep": Int(timeDeep),
            "asleep_rem": Int(timeRem),
            "asleep_unspecified": Int(timeunspecified),
            "startDate": ISO8601DateFormatter().string(from: lastDate.addingTimeInterval(-timeInBed)),
            "endDate": ISO8601DateFormatter().string(from: lastDate)
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
        var totalTimeInBed: TimeInterval = 0
        var totalTimeAwake: TimeInterval = 0
        var totalTimeRem: TimeInterval = 0
        var totalTimeCore: TimeInterval = 0
        var totalTimeDeep: TimeInterval = 0
        var totalTimeUnspecified: TimeInterval = 0
        
        // Otteniamo il timestamp di 24 ore fa
        //let last24Hours = Calendar.current.date(byAdding: .hour, value: -24, to: Date())!

        for sample in results {
            let duration = sample.endDate.timeIntervalSince(sample.startDate)

            switch sample.value {
                case HKCategoryValueSleepAnalysis.inBed.rawValue:
                    totalTimeInBed += duration
                case HKCategoryValueSleepAnalysis.awake.rawValue:
                    totalTimeAwake += duration
                case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                    totalTimeRem += duration
                case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                    totalTimeCore += duration
                case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                    totalTimeDeep += duration
                case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                    totalTimeUnspecified += duration
                default:
                    break
            }
        }

        // Aggiorno le variabili @Published con i dati più recenti
        DispatchQueue.main.async {
                self.timeInBed = totalTimeInBed
                self.timeAwake = totalTimeAwake
                self.timeRem = totalTimeRem
                self.timeCore = totalTimeCore
                self.timeDeep = totalTimeDeep
                self.timeunspecified = totalTimeUnspecified
                self.lastUpdatedDate = Date()
            }

        // Debug: Stampo i dati aggiornati
        print("📊 Dati sonno aggiornati (ultimi 24h):")
        print("🛏️ A letto: \(self.timeInBed) sec")
        print("💤 REM: \(self.timeRem) sec")
        print("🌊 Core: \(self.timeCore) sec")
        print("🏋️ Deep: \(self.timeDeep) sec")
        print("😴 Awake: \(self.timeAwake) sec")
    }

    
    /*func saveSleepData(startDate: Date, endDate: Date, sleepType: HKCategoryValueSleepAnalysis) async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit non disponibile")
            return false
        }

        guard let sleepCategoryType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            print("❌ Tipo di dato HealthKit non valido")
            return false
        }
        
        // Controlla i permessi prima di salvare
        let status = healthStore.authorizationStatus(for: sleepCategoryType)
        if status != .sharingAuthorized {
            print("❌ Permessi di scrittura HealthKit non concessi")
            return false
        }

        let sleepSample = HKCategorySample(
            type: sleepCategoryType,
            value: sleepType.rawValue,
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
    }*/


    // Funzione per aggiornare il tempo a letto
    func updateTimeInBed(_ newTime: TimeInterval) {
        timeInBed = newTime
        lastUpdatedDate = Date() // Aggiorna anche la data
    }
    
    /*func deleteExistingSleepData(startDate: Date, endDate: Date) async {
        let healthStore = HKHealthStore()
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, _ in
            guard let samples = results as? [HKCategorySample] else { return }
            
            Task {
                for sample in samples {
                    try await healthStore.delete(sample)
                }
            }
        }
        
        healthStore.execute(query)
    }*/

}
