//
//  AddDataView.swift
//  Sleepeer
//
//  Created by Davide Perrotta on 18/02/25.
//

import SwiftUI

struct AddDataView: View {
    
    @ObservedObject var health: HealthManager
    @Binding var apiResponse: String
    @Binding var isLoading: Bool
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    //Data di inzio e fine ora per il sonno
    @State private var selectedStartDate = Date()
    @State private var selectedEndDate = Date()
    
    
    
    @State private var stepperValue: TimeInterval = 0
    
    @State private var showStartDatePicker = false
    @State private var showEndDatePicker = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "bed.double.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 24))
                    Text("Inserisci il tempo a letto")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                VStack {
                    //Bottone ora di inizio
                    Button(action: {
                        withAnimation {
                            showStartDatePicker.toggle()
                            showEndDatePicker = false // Chiude l'altro DatePicker
                        }
                    }) {
                        HStack {
                            Text("Ora di inizio")
                                .font(.system(size: 18))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Spacer()
                            Text(selectedStartDate.formatted(date: .abbreviated, time: .shortened)) // Mostra data + ora
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.2)))
                    }
                    
                    if showStartDatePicker {
                        DatePicker("", selection: $selectedStartDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(WheelDatePickerStyle())
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.2)))
                            .transition(.opacity)
                            .padding()
                    }
                    
                    // Bottone per Ora di fine
                    Button(action: {
                        withAnimation {
                            showEndDatePicker.toggle()
                            showStartDatePicker = false // Chiude l'altro DatePicker
                        }
                    }) {
                        HStack {
                            Text("Ora di fine")
                                .font(.system(size: 18))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Spacer()
                            Text(selectedEndDate.formatted(date: .abbreviated, time: .shortened))
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.2)))
                    }
                    
                    if showEndDatePicker {
                        DatePicker("", selection: $selectedEndDate, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(WheelDatePickerStyle())
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.2)))
                            .transition(.opacity)
                            .padding()
                    }
                }
                
                Button(action: {
                    guard selectedStartDate < selectedEndDate else {
                        alertTitle = "Errore"
                        alertMessage = "L'orario di inizio deve essere prima di quello di fine."
                        showAlert = true
                        return
                    }

                    let addedTimeInBed = selectedEndDate.timeIntervalSince(selectedStartDate)
                    
                    Task {
                        isLoading = true
                        
                        // Usa addSleepData per salvare su HealthKit
                        health.addSleepData(minutes: Int(addedTimeInBed / 60))
                        
                        DispatchQueue.main.async {
                            health.timeInBed += addedTimeInBed
                            health.objectWillChange.send()
                            updateUserDefaults()
                        }
                        
                        await sendTimeInBed() // Invio dati al server
                    }
                }) {
                    Text("Salva")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                }
                .padding(.horizontal, 24)

            }
            .padding()
            // Imposta lo sfondo dell'intera schermata su nero, estendendolo oltre i margini sicuri
            .background(Color.black.edgesIgnoringSafeArea(.all))
            
            // Imposta il titolo della schermata nella barra di navigazione
            .navigationTitle("Tempo a letto")
            
            // Visualizza il titolo in formato inline (più piccolo e compatto)
            .navigationBarTitleDisplayMode(.inline)
            
            // Mostra un alert se showAlert è true
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            
            //Stampa a schermo la risposta dell'API
            if !apiResponse.isEmpty {
                Text(apiResponse)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(30)
                    .padding(.horizontal, 24)
            }
        }
    }
    
    func sendTimeInBed() async {
        isLoading = true
        do {
            let response = try await NetworkManager.shared.sendPost_request(seconds: Int(health.timeInBed))
            
            await MainActor.run{
                apiResponse = "✅ Successo : \(response)"
                alertTitle = "✅ Successo"
                alertMessage = "\n Dati inviati correttamente"
                showAlert = true
                isLoading = false
            }
            
            let sleepDate = Date()
            let startDate = sleepDate.addingTimeInterval(-health.timeInBed)
            
            let success = await health.saveSleepData(startDate: startDate, endDate: sleepDate, sleepType: .inBed)
            if success {
                apiResponse += "\n✅ Dati salvati in HealthKit"
                DispatchQueue.main.async {
                    updateUserDefaults()
                }
            } else {
                apiResponse += "\n⚠️ Errore nel salvataggio su HealthKit"
            }
        } catch {
            
            await MainActor.run{
                apiResponse = "❌ Successo : \(error.localizedDescription)"
                alertTitle = "❌ Errore. \n Riprova più tardi"
                alertMessage = "\n Riprova più tardi"
                showAlert = true
                isLoading = false
            }
        }
        isLoading = false
    }
    
    func updateUserDefaults() {
        let now = Date()
        UserDefaults.standard.set(health.timeInBed, forKey: "timeInBed")
        UserDefaults.standard.set(now, forKey: "timeInBedDate")
        
        DispatchQueue.main.async {
            health.lastUpdatedDate = now
        }
    }
    
    func formatTimeInterval(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600 // Calcola le ore
        let minutes = (Int(timeInterval) % 3600) / 60 // Calcola i minuti
        let seconds = Int(timeInterval) % 60 // Calcola i secondi
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds) // Formatta il testo
    }
}
