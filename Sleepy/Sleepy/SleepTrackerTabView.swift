//
//  SleepTrackerTabView.swift
//  Sleepeer
//
//  Created by Davide Perrotta on 16/02/25.
//

import Foundation
import SwiftUI
import HealthKit

struct SleepTrackerTabView: View {
    
    @StateObject private var health = HealthManager()
    
    @State private var timer: Timer?

        var body: some View {
            List{
                HStack{
                    Text("🛌 Media secondi a letto")
                    Spacer()
                    Text("\(Int(health.timeInBed)) sec.")
                }
                HStack{
                    Text("😴 Media veglia")
                    Spacer()
                    Text("\(Int(health.timeAwake)) sec.")
                }
                HStack{
                    Text("💤 Media REM")
                    Spacer()
                    Text("\(Int(health.timeRem)) sec.")
                }
                HStack{
                    Text("🌊 Media sonno principale ")
                    Spacer()
                    Text("\(Int(health.timeCore)) sec.")
                }
                HStack{
                    Text("🏋️ Media sonno profondo")
                    Spacer()
                    Text("\(Int(health.timeDeep)) sec.")
                }
            }
            .font(.system(size: 15, weight: .regular, design: .default))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top)
            .onAppear{
                health.fetchSleepdata()
                //Funzione utile per l'aggiornamento dei dati in tabella, se non
                //ci fosse rimarrebbero 0 fino alla prossima apertura
                startTimer()
            }
            .onChange(of: health.isAuthorized, {
                health.fetchSleepdata()
            })
            .onDisappear {
                stopTimer() 
            }
        }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            health.fetchSleepdata()
        }
    }
    
    private func stopTimer() {
            timer?.invalidate()
            timer = nil
        }
}


#Preview {
    SleepTrackerTabView()
}
