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
    
    @AppStorage("timeInBed") private var savedTimeInBed: Int = 0
    
    @StateObject private var health = HealthManager()
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                Task {
                    let isFirstLaunch = !UserDefaults.standard.bool(forKey: "isFirstLaunch")
                            
                    if isFirstLaunch {
                        savedTimeInBed = Int(health.timeInBed)
                        UserDefaults.standard.set(savedTimeInBed, forKey: "timeInBed")
                        UserDefaults.standard.set(true, forKey: "isFirstLaunch")
                    }
                    
                    await sendSleepTime()
                    health.fetchSleepdata()
                }
            }) {
                HStack {
                    Image(systemName: "clock")
                    Text("Sincronizza dati del sonno con il server")
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
                    await sendSleepDetails()
                    health.fetchSleepdata()
                }
            }) {
                HStack {
                    Image(systemName: "square.and.pencil")
                    Text("Aggiorna dettagli del sonno del server")
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

            if isLoading {
                ProgressView()
                    .padding()
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
        .padding()
        
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
                apiResponse = "❌ Successo : \(error.localizedDescription)"
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
                    apiResponse = "❌ Successo : \(error.localizedDescription)"
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
