//
//  SleepButtonsView.swift
//  Sleepy
//
//  Created by Davide Perrotta on 20/02/25.
//

import SwiftUI

struct SleepButtonsView: View {
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var isLoading: Bool = false
    @State private var apiResponse: String = ""
    
    @ObservedObject private var health = HealthManager()
    
    @State private var sleepDataText: String = ""
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                Task {
                    isLoading = true
                    await health.fetchSleepdata()
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 secondo
                    await health.generateSleepJSON()
                    isLoading = false
                    await sendSleepTime()
                    await health.fetchSleepdata()
                    
                    
                    /*if health.timeInBed > 0 { // Evita di inviare 0 al server, perchè al primo avvio potrebbe inviare 0
                        await sendSleepTime()
                    } else {
                        apiResponse = "⚠️ Dati non disponibili, riprova dopo la sincronizzazione."
                        alertTitle = "⚠️ Attenzione"
                        alertMessage = "I dati del sonno non sono ancora stati caricati."
                        showAlert = true
                    }*/
                }
            }) {
                HStack {
                    Image(systemName: "clock")
                    Text("Sincronizza sonno con il server")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(12)
            }
            
            Button(action: {
                Task {
                    isLoading = true
                    await health.fetchSleepdata()
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 secondo
                    await health.generateSleepJSON()
                    isLoading = false
                    await sendSleepDetails()
                    await health.fetchSleepdata()
                }
            }) {
                HStack {
                    Image(systemName: "square.and.pencil")
                    Text("Aggiorna fasi sonno con il server")
                        .fontWeight(.semibold)
                }
                .foregroundColor(Color.green)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.systemGreen).opacity(0.2))
                .cornerRadius(12)
            }
            .padding(.top, 10)
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            
            if !health.sleepDataJSON.isEmpty {
                Text(health.sleepDataJSON)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(12)
                    .padding(.top, 10)
            }
        }
        .padding()
        .onAppear {
            Task {
                await health.fetchSleepdata() // Carica i dati subito quando la view appare
            }
        }
        .onReceive(health.$isSleepDataUpdated) { updated in
            if updated {
                sleepDataText = health.sleepDataJSON
                health.isSleepDataUpdated = false // reset per il prossimo aggiornamento
            }
        }
    }
    
    // Funzioni per API
    
    private func sendSleepTime() async {
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
        } catch {
            await MainActor.run{
                apiResponse = "❌ Errore : \(error.localizedDescription)"
                alertTitle = "❌ Errore. \n Riprova più tardi"
                alertMessage = "\n Riprova più tardi"
                showAlert = true
                isLoading = false
            }
            
            apiResponse = "❌ Errore: \(error.localizedDescription)"
        }
        isLoading = false
    }
        
    private func sendSleepDetails() async {
      await MainActor.run {isLoading = true}
        do {
            let sleepDetails = await health.fetchSleepDataForAPI()
            let response = try await NetworkManager.shared.sendSleepDetails(sleepData: sleepDetails)
               
            await MainActor.run{
                apiResponse = "✅ Successo : \(response)"
                alertTitle = "✅ Successo"
                alertMessage = "\n Dati inviati correttamente"
                showAlert = true
                isLoading = false
            }
                
        } catch {
            print("❌ Errore nell'invio dei dettagli del sonno: \(error.localizedDescription)") // Per il Debug
            
            await MainActor.run{
                apiResponse = "❌ Errore : \(error.localizedDescription)"
                alertTitle = "❌ Errore. \n Riprova più tardi"
                alertMessage = "Riprova più tardi"
                showAlert = true
                isLoading = false
            }
        }
    }
}

struct SleepButtonsView_Previews: PreviewProvider {
    static var previews: some View {
        SleepButtonsView()
            .preferredColorScheme(.dark) // Forza il tema scuro
    }
}
