//
//  NetworkManager.swift
//  Sleepeer
//
//  Created by Davide Perrotta on 17/02/25.
//

import Foundation


class NetworkManager{
    
    static let shared = NetworkManager() 
    private init() {} 
    
    //API Swiingo
    private let sURL = "https://onboarding.swiingo.scatol.one"
    
    //Chiave di autenticazione nelle richieste
    private let APIkey = "Swiingo2025!"
    
    // Funzione asincrona che prende in Input n.secondi e in Output dà una stringa e lancio un errore
    func sendPost_request(seconds: Int) async throws -> String {
        
        // Costruisce l'URL con il numero di secondi nel path
        guard let url = URL(string: "\(sURL)/sleep/time/\(seconds)") else {
            throw URLError(.badURL)
        }

        print("🌐 URL richiesta: \(url)") // Debug dell'URL generato

        // Crea la richiesta HTTP
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(APIkey, forHTTPHeaderField: "X-API-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            // Effettua la richiesta in modo asincrono
            let (data, response) = try await URLSession.shared.data(for: request)

            // Controlla se la risposta è valida
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }

            // Verifica il codice di stato HTTP
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Errore sconosciuto"
                throw NSError(domain: "APIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Errore API: \(errorMessage)"])
            }

            // Converte la risposta in stringa
            if let responseString = String(data: data, encoding: .utf8) {
                
                // Debug della risposta
                print("📥 Risposta ricevuta: \(responseString)")
                return responseString
            } else {
                throw URLError(.cannotParseResponse)
            }

        } catch {
            //se si verifica un errore di rete, catturato e trasformato in errore dettagliato
            throw NSError(domain: "NetworkError", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Errore di rete: \(error.localizedDescription)"])
        }
    }

    
    
    // Funzione per inviare una richiesta POST con i dettagli del sonno
    func sendSleepDetails(sleepData: [String: Any]) async throws -> String {
        guard let url = URL(string: "\(sURL)/sleep/details") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(APIkey, forHTTPHeaderField: "X-API-Key")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        //Serializza il dizionario in un oggetto JSON per l'invio della richiesta
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: sleepData, options: [])
            
            // Assegna il JSON  al corpo della richiesta(request) con .httpBody
            request.httpBody = jsonData
            
        } catch {
            //Nel caso di fallimento della richiesta, viene generato un errore specifico
            throw NSError(domain: "JSONSerializationError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Errore nella serializzazione del JSON"])
        }

        // Stampa il JSON inviato per debugging
        if let jsonString = String(data: request.httpBody!, encoding: .utf8) {
            print("📤 JSON Inviato: \(jsonString)")
        }

        do {
            //Richiesta in modo asincrono e attende la risposta del server
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Verifica della risposta HTTP
            guard let httpResponse = response as? HTTPURLResponse else {
                
                // Se non è un HTTPURLResponse, genera un errore
                throw URLError(.badServerResponse)
            }

            // Se la risposta non è nel range 200-299 di successo, restituisce un errore dettagliato
            if !(200...299).contains(httpResponse.statusCode) {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Errore sconosciuto"
                
                //Se risposta non è nel range, restituisce un errore con il messaggio di errore del server
                throw NSError(domain: "APIError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Errore API: \(errorMessage)"])
            }

            //RISPOSTA VALIIDA -> Converte in una stringa per il debug
            if let responseString = String(data: data, encoding: .utf8) {
                
                //Stampa la stringa di risposta
                print("📥 Risposta ricevuta: \(responseString)")
                return responseString
            } else {
                //Se la ripsota non può essere convertita in stringa, restituisce un errore
                return "Nessuna risposta valida"
            }
            
        } catch {
            //se si verifica un errore di rete, catturato e trasformato in errore dettagliato
            throw NSError(domain: "NetworkError", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Errore di rete: \(error.localizedDescription)"])
        }
    }
    
    func fetchData(from url: URL) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
}
