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
    
    @State private var stepperValue: TimeInterval = 0
    
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
                    Text("\(Int(stepperValue)) secondi")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                                    
                    Stepper(value: $stepperValue, in: 0...86400, step: 60) {
                        Text("Regola il tempo").foregroundColor(.gray)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.2)))
                }
                .padding()

                Button(action: {
                    let newTimeInBed = health.timeInBed + stepperValue
                    let sleepDate = Date()
                    let startDate = sleepDate.addingTimeInterval(-newTimeInBed)
                    
                    Task {
                        let success = await health.saveSleepData(startDate: startDate, endDate: sleepDate, sleepType: .inBed)
                        if success {
                            health.timeInBed = newTimeInBed // Aggiorna il valore in HealthKit
                            apiResponse += "\n✅ Dati salvati in HealthKit"
                            DispatchQueue.main.async {
                                updateUserDefaults()
                            }
                        } else {
                            apiResponse += "\n⚠️ Errore nel salvataggio su HealthKit"
                        }
                        await sendTimeInBed()
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
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationTitle("Tempo a letto")
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }

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

    private func sendTimeInBed() async {
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

    private func updateUserDefaults() {
        let now = Date()
        UserDefaults.standard.set(health.timeInBed, forKey: "timeInBed")
        UserDefaults.standard.set(now, forKey: "timeInBedDate")
        
        DispatchQueue.main.async {
            health.lastUpdatedDate = now  // Notifica SwiftUI che è cambiato
        }
    }
}
