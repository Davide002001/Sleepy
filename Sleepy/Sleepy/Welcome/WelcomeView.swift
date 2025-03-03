//
//  WelcomeView.swift
//  Sleepeer
//
//  Created by Davide Perrotta on 16/02/25.
//

import SwiftUI

struct WelcomeView: View {
    
    var onDismiss: () -> Void
    
    @ObservedObject var health : HealthManager
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all) // Sfondo nero
            
            VStack(spacing: 20) {
                
                Image(systemName: "moon.zzz")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 100)
                    .foregroundColor(.blue)
                    .padding(.top, 70)
                
                // 📢 TITOLO
                Text("Migliora il tuo sonno\ncon il monitoraggio")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // 📌 PRIMA SEZIONE
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "bed.double.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Perché monitorare il sonno?")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Capire le tue abitudini notturne ti aiuta a migliorare la qualità del sonno e il benessere generale.")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top,30)
                
                // 📌 SECONDA SEZIONE
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "clock.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Quanto dovresti dormire?")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Gli esperti consigliano almeno 7-9 ore di sonno per notte per un riposo ottimale.")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 90)

                Button(action: {
                    health.requestSleepAuthorization()
                    onDismiss() // Chiude il foglio
                }) {
                    Text("Inizia")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(30)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 20)
            }
        }
    }
}

#Preview {
    WelcomeView(onDismiss: {}, health: HealthManager())
}

