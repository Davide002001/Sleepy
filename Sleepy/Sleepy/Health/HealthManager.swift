//
//  HealthManager.swift
//  Sleepeer
//
//  Created by Davide Perrotta on 14/02/25.
//

import Foundation
import SwiftUI
import HealthKit

@MainActor
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
    
    @Published var sleepDataJSON: String = ""
    
    @Published var isSleepDataUpdated: Bool = false
    
    
    private var shouldRequestAuthorization: Bool = false
    
    init()  {}

    // Assicura che tutta la funzione venga eseguita sul thread principale (utile per aggiornare proprietà @Published e la UI)
    @MainActor
    func requestSleepAuthorization() async {
        
        // Recupera il tipo di dato di HealthKit per l'analisi del sonno
        guard let sleepTypes = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            // Se il tipo di dato non esiste, stampa un messaggio di errore e termina la funzione
            print("❌ Recupero dei dati di sonno fallito")
            return
        }
        
        // Crea un set contenente il tipo di dato che vogliamo leggere e scrivere su HealthKit
        let healthTypes: Set<HKSampleType> = [sleepTypes]
        
        do {
            // Richiesta asincrona di autorizzazione a HealthKit usando una continuazione che può lanciare un errore
            
        /// requestAuthorization) usa una callback, quindi per renderla compatibile con async/await si usa withCheckedThrowingContinuation.
        /// •    Serve quando hai una funzione che usa una closure per restituire il risultato, ma tu vuoi usarla come una funzione asincrona moderna.
        ///•    Permette di sospendere l’esecuzione finché la callback non restituisce un valore o un errore.
            let success = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
                // Richiede l'autorizzazione per leggere e scrivere i dati di sonno
                healthStore.requestAuthorization(toShare: healthTypes, read: healthTypes) { success, error in
                    if let error = error {
                        // Se c'è un errore nella richiesta di autorizzazione, termina la continuazione con errore
                        continuation.resume(throwing: error)
                    } else {
                        // Se non ci sono errori, termina la continuazione restituendo il successo (true/false)
                        continuation.resume(returning: success)
                    }
                }
            }
            
            // Aggiorna la proprietà isAuthorized con il risultato della richiesta
            self.isAuthorized = success
            
            if success {
                // Se l'autorizzazione è stata concessa, stampa un messaggio di conferma
                print("✅ Autorizzazione concessa")
                // Avvia il recupero dei dati di sonno da HealthKit
                await self.fetchSleepdata()
            } else {
                // Se l'autorizzazione è stata negata senza errori, stampa un messaggio informativo
                print("❌ Autorizzazione negata senza errori specifici")
            }
            
        } catch {
            // Se la richiesta ha generato un errore, lo cattura e stampa un messaggio con la descrizione dell’errore
            print("❌ Errore durante la richiesta di autorizzazione: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func fetchSleepdata() async {
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
         
        // Crea una query per recuperare i dati di sonno da HealthKit
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] _, results, error in

            // Verifica se ci sono risultati validi e se non ci sono errori
            guard let results = results as? [HKCategorySample], error == nil else {
                print("❌ Errore nel recupero dei dati: \(error?.localizedDescription ?? "Sconosciuto")")
                return
            }

            // Se i risultati sono validi, avvia un task asincrono per elaborare i dati
            Task { @MainActor in
                // Chiama la funzione `processSleepData` per elaborare i risultati
                await self?.processSleepData(results: results)
            }
        }

        healthStore.execute(query)
        
        DispatchQueue.main.async {
            // Imposta `isSleepDataUpdated` su `true` per indicare che i dati sono stati aggiornati
            self.isSleepDataUpdated = true
        }
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
            await fetchSleepdata()
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
            await fetchSleepdata()
            return true
        } catch {
            print("❌ Errore salvataggio dati: \(error.localizedDescription)")
            return false
        }
    }
    
    // Funzione di supporto per convertire l'enum in stringa
    func getSleepStage(value: HKCategoryValueSleepAnalysis) async -> String{
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
    
    @MainActor
    func processSleepData(results: [HKCategorySample]) async {
        // Variabili per accumulare il tempo totale per ogni fase del sonno
        var totalTimeInBed: TimeInterval = 0 // Tempo totale a letto
        var totalTimeAwake: TimeInterval = 0 // Tempo totale sveglio
        var totalTimeRem: TimeInterval = 0 // Tempo totale in fase REM
        var totalTimeCore: TimeInterval = 0 // Tempo totale in fase Core (sonno leggero)
        var totalTimeDeep: TimeInterval = 0 // Tempo totale in fase Deep (sonno profondo)
        var totalTimeUnspecified: TimeInterval = 0 // Tempo totale in fase non specificata

        // Itera su ogni campione di dati del sonno recuperato da HealthKit
        for sample in results {
            // Calcola la durata del campione (differenza tra endDate e startDate)
            let duration = sample.endDate.timeIntervalSince(sample.startDate)

            // Controlla il tipo di fase del sonno e accumula il tempo corrispondente
            switch sample.value {
                case HKCategoryValueSleepAnalysis.inBed.rawValue:
                    totalTimeInBed += duration // Accumula il tempo a letto
                case HKCategoryValueSleepAnalysis.awake.rawValue:
                    totalTimeAwake += duration // Accumula il tempo sveglio
                case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                    totalTimeRem += duration // Accumula il tempo in fase REM
                case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                    totalTimeCore += duration // Accumula il tempo in fase Core
                case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                    totalTimeDeep += duration // Accumula il tempo in fase Deep
                case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                    totalTimeUnspecified += duration // Accumula il tempo in fase non specificata
                default:
                    break // Ignora altri valori non gestiti
            }
        }

        // Aggiorna le variabili @Published con i dati più recenti
        // Questo viene fatto sul thread principale per aggiornare correttamente la UI
        DispatchQueue.main.async {
            self.timeInBed = totalTimeInBed // Aggiorna il tempo totale a letto
            self.timeAwake = totalTimeAwake // Aggiorna il tempo totale sveglio
            
            self.timeRem = totalTimeRem // Aggiorna il tempo totale in fase REM
            self.timeCore = totalTimeCore // Aggiorna il tempo totale in fase Core
            self.timeDeep = totalTimeDeep // Aggiorna il tempo totale in fase Deep
            self.timeunspecified = totalTimeUnspecified // Aggiorna il tempo totale in fase non specificata
            self.lastUpdatedDate = Date() // Imposta la data dell'ultimo aggiornamento
        }

        // Debug: Stampa i dati aggiornati nella console
        print("📊 Dati sonno aggiornati (ultimi 24h):")
        print("🛏️ A letto: \(self.timeInBed) sec") // Stampa il tempo totale a letto
        print("💤 REM: \(self.timeRem) sec") // Stampa il tempo totale in fase REM
        print("🌊 Core: \(self.timeCore) sec") // Stampa il tempo totale in fase Core
        print("🏋️ Deep: \(self.timeDeep) sec") // Stampa il tempo totale in fase Deep
        print("😴 Awake: \(self.timeAwake) sec") // Stampa il tempo totale sveglio
    }


    // Funzione per recuperare i dati del sonno e formattarli in un dizionario [String: Any] per l'invio all'API
    func fetchSleepDataForAPI() async -> [String: Any] {
        // Crea un'istanza di DateFormatter per formattare la data
        let formatter = DateFormatter()
        
        // Imposta il formato della data come "yyyyMMdd_HHmmss" (anno, mese, giorno, ora, minuti, secondi)
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        
        // Ottiene la data e l'ora corrente e la formatta come stringa usando il DateFormatter
        let timestamp = formatter.string(from: Date())
        
        // Restituisce un dizionario contenente i dati del sonno formattati per l'API
        return [
            // Genera un nome univoco per i dati del sonno, combinando un timestamp e un UUID
            "name": "SleepData_\(timestamp)_\(UUID().uuidString)", // genera un ID univoco e casuale, leggibile con la data
            "in_bed": Int(timeInBed),
            "awake": Int(timeAwake),
            "asleep_core": Int(timeCore),
            "asleep_deep": Int(timeDeep),
            "asleep_rem": Int(timeRem),
            "asleep_unspecified": Int(timeunspecified),
        ]
    }

    // Funzione per generare un JSON a partire dai dati del sonno recuperati
    func generateSleepJSON() async {
        // Richiama la funzione per aggiornare i dati del sonno da HealthKit
        await fetchSleepdata()
        
        // Avvia un task asincrono per gestire la creazione del JSON
        Task {
            // Recupera i dati del sonno formattati per l'API
            let dataDict = await fetchSleepDataForAPI()
            
            // Stampa i dati locali recuperati per debug (formato dizionario)
            print("📊 Dati locali recuperati (formato dizionario): \(dataDict)")
            
            // Prova a convertire il dizionario in dati JSON
            if let jsonData = try? JSONSerialization.data(withJSONObject: dataDict, options: .prettyPrinted),
               // Converte i dati JSON in una stringa UTF-8
               let jsonString = String(data: jsonData, encoding: .utf8) {
                
                // Esegue il codice successivo sul thread principale per aggiornare la UI
                await MainActor.run {
                    // Assegna la stringa JSON alla variabile sleepDataJSON per visualizzarla o inviarla
                    self.sleepDataJSON = jsonString
                    
                    // Stampa il JSON generato nel debugger
                    print("📄 JSON generato:\n\(jsonString)")
                }
            } else {
                // Se la conversione in JSON fallisce, esegue il codice sul thread principale
                await MainActor.run {
                    // Imposta un messaggio di errore nella variabile sleepDataJSON
                    self.sleepDataJSON = "❌ Errore nella creazione del JSON"
                    
                    // Stampa un messaggio di errore nel debugger
                    print("❌ Errore: Impossibile convertire i dati in JSON.")
                }
            }
        }
    }

    // Funzione per aggiornare il tempo a letto
    func updateTimeInBed(_ newTime: TimeInterval) {
        timeInBed = newTime
        lastUpdatedDate = Date() // Aggiorna anche la data
    }
}
