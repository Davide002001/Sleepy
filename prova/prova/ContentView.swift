//
//  ContentView.swift
//  prova
//
//  Created by Davide Perrotta on 11/04/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var health: HealthManager

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                if let report = health.sleepReport {
                    Text("Totale ore dormite:")
                        .font(.headline)
                    Text(report.formattedTotalSleep)
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Divider()
                    
                    Text("Risvegli: \(report.wakeIntervals.count)")
                        .font(.headline)
                    ForEach(report.wakeIntervals) { interval in
                        VStack(alignment: .leading) {
                            Text("• \(interval.start.formatted(date: .omitted, time: .shortened)) - \(interval.end.formatted(date: .omitted, time: .shortened))")
                            Text("  Durata: \(Int(interval.duration / 60)) min")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                } else {
                    ProgressView("Caricamento dati sonno…")
                }
            }
            .padding()
            .navigationTitle("Report Sonno")
            .task {
                await health.requestAuthorization()
                await health.generateSleepReport()
                health.startTimer()
            }
        }
        .onDisappear {
            health.stopTimer()
        }
    }
}


#Preview {
    ContentView().environmentObject(HealthManager())
}
