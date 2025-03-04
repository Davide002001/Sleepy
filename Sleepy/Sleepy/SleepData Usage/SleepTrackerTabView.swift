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
    
    @StateObject var health: HealthManager
    
    @State private var timer: Timer?

    var body: some View {
        List {
            HStack {
                Text("🛌 Media tempo a letto")
                Spacer()
                Text(formatTime(seconds: Int(health.timeInBed)))
            }
            HStack {
                Text("😴 Media veglia")
                Spacer()
                Text(formatTime(seconds: Int(health.timeAwake)))
            }
            HStack {
                Text("💤 Media REM")
                Spacer()
                Text(formatTime(seconds: Int(health.timeRem)))
            }
            HStack {
                Text("🌊 Media sonno principale")
                Spacer()
                Text(formatTime(seconds: Int(health.timeCore)))
            }
            HStack {
                Text("🏋️ Media sonno profondo")
                Spacer()
                Text(formatTime(seconds: Int(health.timeDeep)))
            }
        }
        .font(.system(size: 15, weight: .regular, design: .default))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top)
        .onAppear {
            updateUserDefaults()
            Task{
                await health.fetchSleepdata()
            }
            startTimer()
        }
        .onChange(of: health.isAuthorized) {
            Task{
                await health.fetchSleepdata()
            }
        }
        .onDisappear {
            stopTimer()
        }
    }

    func startTimer() {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task{
                await health.fetchSleepdata()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateUserDefaults() {
        let now = Date()
        UserDefaults.standard.set(health.timeInBed, forKey: "timeInBed")
        UserDefaults.standard.set(now, forKey: "timeInBedDate")
        
        DispatchQueue.main.async {
            health.lastUpdatedDate = now
        }
    }

    /// Funzione per formattare i secondi in ore e minuti
    private func formatTime(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours) h \(minutes) min"
        } else {
            return "\(minutes) min"
        }
    }
}

#Preview {
    SleepTrackerTabView(health: HealthManager())
}
