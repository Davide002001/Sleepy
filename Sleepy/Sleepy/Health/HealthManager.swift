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
    
    
    private var shouldRequestAuthorization: Bool = false
    
    init(requestAuthorization: Bool = false) {
        self.shouldRequestAuthorization = requestAuthorization
        if requestAuthorization {
            requestSleepAuthorization()
        }
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
        // ✅ Ottiene il tipo di dato HealthKit per l'analisi del sonno
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!

        // ✅ Crea un'istanza del calendario corrente per la gestione delle date
        let calendar = Calendar.current

        // ✅ Ottiene la data e l'ora attuali
        let now = Date()

        // ✅ Trova l'inizio della giornata di oggi (00:00)
        let todayStart = calendar.startOfDay(for: now)

        // ✅ Trova l'inizio della giornata di ieri (00:00), sottraendo un giorno
        let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart)!

        // ✅ Trova l'inizio della giornata di domani (00:00), aggiungendo un giorno
        let tomorrowStart = calendar.date(byAdding: .day, value: 1, to: todayStart)!

        // ✅ Definisce il range per la sessione notturna di ieri (18:00 - 11:00 di oggi)
        let sleepStartYesterday = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: yesterdayStart)!
        let sleepEndToday = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: todayStart)!

        // ✅ Definisce il range per la sessione notturna di oggi (18:00 - 11:00 di domani)
        let sleepStartToday = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: todayStart)!
        let sleepEndTomorrow = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: tomorrowStart)!

        // ✅ Definisce il range per la sessione pomeridiana (12:00 - 17:00 di oggi)
        let sleepStartAfternoon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: todayStart)!
        let sleepEndAfternoon = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: todayStart)!

        // ✅ Definisce il range per l'ultima parte della sessione pomeridiana (17:00 - 18:00 di oggi)
        let sleepStartLateAfternoon = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: todayStart)!
        let sleepEndEarlyEvening = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: todayStart)!

        // ✅ Dichiarazione della variabile per il filtro di ricerca (predicate)
        var predicate: NSPredicate

        // ✅ Se l'ora attuale è prima delle 18:00, considera la sessione notturna di ieri e quella pomeridiana
        if calendar.component(.hour, from: now) < 18 {
            // 🔹 Include:
            //    - La sessione di ieri (18:00 - 11:00 di oggi)
            //    - La sessione pomeridiana (12:00 - 17:00 di oggi)
            //    - Il periodo dalle 17:00 alle 18:00, che si collega alla sessione pomeridiana
            let predicateYesterday = HKQuery.predicateForSamples(withStart: sleepStartYesterday, end: sleepEndToday, options: .strictStartDate)
            let predicateAfternoon = HKQuery.predicateForSamples(withStart: sleepStartAfternoon, end: sleepEndAfternoon, options: .strictStartDate)
            let predicateLateAfternoon = HKQuery.predicateForSamples(withStart: sleepStartLateAfternoon, end: sleepEndEarlyEvening, options: .strictStartDate)

            // 🔹 Combina tutti i predicati con OR → Prende dati da più sessioni
            predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [predicateYesterday, predicateAfternoon, predicateLateAfternoon])
        } else {
            // ✅ Se l'ora attuale è dopo le 18:00, considera la sessione attuale e quella pomeridiana
            // 🔹 Include:
            //    - La sessione di ieri (18:00 - 11:00 di oggi)
            //    - La sessione attuale (18:00 di oggi - 11:00 di domani)
            //    - La sessione pomeridiana (12:00 - 17:00 di oggi)
            //    - Il periodo 17:00 - 18:00 per gestire chi si addormenta prima di mezzanotte
            let predicateYesterday = HKQuery.predicateForSamples(withStart: sleepStartYesterday, end: sleepEndToday, options: .strictStartDate)
            let predicateToday = HKQuery.predicateForSamples(withStart: sleepStartToday, end: sleepEndTomorrow, options: .strictStartDate)
            let predicateAfternoon = HKQuery.predicateForSamples(withStart: sleepStartAfternoon, end: sleepEndAfternoon, options: .strictStartDate)
            let predicateLateAfternoon = HKQuery.predicateForSamples(withStart: sleepStartLateAfternoon, end: sleepEndEarlyEvening, options: .strictStartDate)

            // 🔹 Combina i predicati con OR
            predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [predicateYesterday, predicateToday, predicateAfternoon, predicateLateAfternoon])
        }

        // ✅ Crea la query su HealthKit per recuperare i dati del sonno
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, error in
            // ✅ Se c'è un errore, lo stampa e interrompe la funzione
            guard let results = results as? [HKCategorySample], error == nil else {
                print("❌ Errore nel recupero dei dati: \(error?.localizedDescription ?? "Sconosciuto")")
                return
            }
            self.processSleepData(results: results)
        }
        // ✅ Esegue la query su HealthKit per ottenere i dati richiesti
        healthStore.execute(query)
    }
    
    
    func addSleepData2(startDate: Date, endDate: Date) async -> Bool {
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let calendar = Calendar.current
        let timeZone = TimeZone.current
        let now = Date()
        
        // ✅ Trova l'inizio della giornata di oggi (00:00)
        let todayStart = calendar.startOfDay(for: now)
        
        // ✅ Definisce l'inizio della sessione pomeridiana (12:00 di oggi)
        let sleepStartTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: todayStart)!
        
        // ✅ Definisce il termine della sessione pomeridiana (18:00 di oggi)
        let sleepEndTimeUTC = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: todayStart)!
        let sleepEndTime = sleepEndTimeUTC.addingTimeInterval(TimeInterval(timeZone.secondsFromGMT()))
        
        print("📅 Intervallo valido per l'inserimento: \(sleepStartTime) - \(sleepEndTime)")
        print("🕒 Tentativo di inserimento: \(startDate) - \(endDate)")

        // ✅ Modifica il controllo per includere i dati tra 17:00 e 18:00
        guard startDate >= sleepStartTime, endDate <= sleepEndTime else {
            print("⛔ Errore: Il periodo selezionato (\(startDate) - \(endDate)) è fuori dal range (\(sleepStartTime) - \(sleepEndTime)).")
            return false
        }

        // ✅ Crea un oggetto HKCategorySample per rappresentare il periodo di sonno
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
            fetchSleepdata()
            return true
        } catch {
            print("❌ Errore salvataggio dati: \(error.localizedDescription)")
            return false
        }
    }

    
    func addSleepData(startDate: Date, endDate: Date) async -> Bool {
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let calendar = Calendar.current

        // ✅ Usa la data di inizio selezionata dall'utente come riferimento
        let startDay = calendar.startOfDay(for: startDate)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: startDay)!

        // ✅ Intervallo consentito: 18:00 del giorno di `startDate` - 11:00 del giorno successivo
        let sleepStartTime = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: startDay)!
        let sleepEndTime = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: nextDay)!

        print("📅 Intervallo valido per l'inserimento: \(sleepStartTime) - \(sleepEndTime)")
        print("🕒 Tentativo di inserimento: \(startDate) - \(endDate)")

        // ✅ Controllo che i dati siano nel range consentito
        guard startDate >= sleepStartTime, endDate <= sleepEndTime else {
            print("⛔ Errore: Il periodo selezionato (\(startDate) - \(endDate)) è fuori dal range (\(sleepStartTime) - \(sleepEndTime)).")
            return false
        }

        // ✅ Crea il campione di sonno
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
            fetchSleepdata()
            return true
        } catch {
            print("❌ Errore salvataggio dati: \(error.localizedDescription)")
            return false
        }
    }



    func fetchSleepDataForAPI() async -> [String: Any] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        
        return [
            "name": "SleepData_\(timestamp)_\(UUID().uuidString)", //genera un ID univoco e casuale,i leggebile con la data
            "in_bed": Int(timeInBed),
            "awake": Int(timeAwake),
            "asleep_core": Int(timeCore),
            "asleep_deep": Int(timeDeep),
            "asleep_rem": Int(timeRem),
            "asleep_unspecified": Int(timeunspecified),
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

    // Funzione per aggiornare il tempo a letto
    func updateTimeInBed(_ newTime: TimeInterval) {
        timeInBed = newTime
        lastUpdatedDate = Date() // Aggiorna anche la data
    }
}
