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
    
    func addSleepData(minutes: Int) {
        // Ottiene il tipo di dato per l'analisi del sonno da HealthKit
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        
        // Istanza del calendario per gestire le date
        let calendar = Calendar.current
        
        // Ottiene la data e ora attuali
        let now = Date()
        
        // Trova l'inizio della giornata corrente (00:00:00)
        let todayStart = calendar.startOfDay(for: now)
        
        // Trova l'inizio della giornata di ieri (-86400 secondi = -24 ore)
        let yesterdayStart = calendar.date(byAdding: .second, value: -86400, to: todayStart)!
        
        // Definisce il range del sonno consentito:
        // L'orario di inizio è fissato alle 18:00 di ieri
        let sleepStartTime = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: yesterdayStart)!
        
        // L'orario di fine è fissato alle 11:00 di oggi
        let sleepEndTime = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: todayStart)!
        
        // Crea un predicato per filtrare i dati del sonno entro l'intervallo specificato
        let predicate = HKQuery.predicateForSamples(withStart: sleepStartTime, end: sleepEndTime, options: .strictStartDate)
        
        // Definisce un criterio di ordinamento (dal più recente al più vecchio)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        // Calcola l'orario di inizio del periodo di sonno basandosi sui minuti forniti
        let startDate = now.addingTimeInterval(-Double(minutes * 60))
        
        // L'orario di fine sarà semplicemente il momento attuale
        let endDate = now
        
        // Controlla che il nuovo intervallo sia all'interno del range valido (18:00 di ieri - 11:00 di oggi)
        guard startDate >= sleepStartTime, endDate <= sleepEndTime else {
            print("Errore: l'orario selezionato è fuori dal range consentito.")
            return // Se l'intervallo non è valido, interrompe la funzione
        }
        
        // Crea un campione di sonno per HealthKit con il tipo "in bed" (tempo a letto)
        let sample = HKCategorySample(type: sleepType, value: HKCategoryValueSleepAnalysis.inBed.rawValue, start: startDate, end: endDate)
        
        // Salva il campione in HealthKit
        healthStore.save(sample) { success, error in
            if success {
                // Se il salvataggio ha successo, aggiorna i dati del sonno
                DispatchQueue.main.async {
                    self.fetchSleepdata() // Ricarica i dati per riflettere l'aggiornamento
                }
            } else {
                // Se c'è un errore, lo stampa nella console
                print("Errore salvataggio dati: \(error?.localizedDescription ?? "Sconosciuto")")
            }
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
        // Creiamo un dizionario per memorizzare l'ultimo campione per ogni tipo di sonno
        var latestSamples: [Int: HKCategorySample] = [:]
        
        // Otteniamo il timestamp di 24 ore fa
        let last24Hours = Calendar.current.date(byAdding: .hour, value: -24, to: Date())!

        for sample in results {
            // Consideriamo solo i dati delle ultime 24 ore
            guard sample.startDate >= last24Hours else { continue }

            // Controlliamo se già esiste un campione più recente per quel tipo di sonno
            if let existingSample = latestSamples[sample.value] {
                // Se il campione attuale è più recente, lo sostituiamo
                if sample.startDate > existingSample.startDate {
                    latestSamples[sample.value] = sample
                }
            } else {
                // Se è il primo campione di quel tipo, lo salviamo
                latestSamples[sample.value] = sample
            }
        }

        // Aggiorno le variabili @Published con i dati più recenti
        DispatchQueue.main.async {
            self.timeInBed = latestSamples[HKCategoryValueSleepAnalysis.inBed.rawValue]?.endDate.timeIntervalSince(
                latestSamples[HKCategoryValueSleepAnalysis.inBed.rawValue]?.startDate ?? Date()
            ) ?? 0

            self.timeAwake = latestSamples[HKCategoryValueSleepAnalysis.awake.rawValue]?.endDate.timeIntervalSince(
                latestSamples[HKCategoryValueSleepAnalysis.awake.rawValue]?.startDate ?? Date()
            ) ?? 0

            self.timeRem = latestSamples[HKCategoryValueSleepAnalysis.asleepREM.rawValue]?.endDate.timeIntervalSince(
                latestSamples[HKCategoryValueSleepAnalysis.asleepREM.rawValue]?.startDate ?? Date()
            ) ?? 0

            self.timeCore = latestSamples[HKCategoryValueSleepAnalysis.asleepCore.rawValue]?.endDate.timeIntervalSince(
                latestSamples[HKCategoryValueSleepAnalysis.asleepCore.rawValue]?.startDate ?? Date()
            ) ?? 0

            self.timeDeep = latestSamples[HKCategoryValueSleepAnalysis.asleepDeep.rawValue]?.endDate.timeIntervalSince(
                latestSamples[HKCategoryValueSleepAnalysis.asleepDeep.rawValue]?.startDate ?? Date()
            ) ?? 0

            self.timeunspecified = latestSamples[HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue]?.endDate.timeIntervalSince(
                latestSamples[HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue]?.startDate ?? Date()
            ) ?? 0

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

    
    func saveSleepData(startDate: Date, endDate: Date, sleepType: HKCategoryValueSleepAnalysis) async -> Bool {
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
    }


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
