//
//  SleepSummaryView.swift
//  Sleepy
//
//  Created by Davide Perrotta on 24/02/25.
//

import SwiftUI

struct SleepSummaryView: View {
    
    @ObservedObject var health : HealthManager
    
    @State private var showSheet = false  // Stato per mostrare il foglio delle info sulle fasi del sonno
    
    var hours: Int {
        Int(health.timeInBed) / 3600
    }
        
    var minutes: Int {
        (Int(health.timeInBed) % 3600) / 60
    }
        
    var seconds: Int {
        Int(health.timeInBed) % 60
    }
    
    
    var body: some View {
        HStack(spacing: 5) {
            Text("🛌")
                .font(.system(size: 17))
            Text("MEDIA ORE A LETTO")
                .font(.system(size: 16, weight: .regular))
                .bold()
                .foregroundColor(.gray)
                .padding(.top, 5)
                
            Spacer()
            
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .font(.system(size: 24))
                    .onTapGesture {
                        showSheet = true  // Mostra il foglio
                    }
            }
            .sheet(isPresented: $showSheet) {
                Sleephasesinfo()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading)
        .padding(.top, 20)
        
        HStack {
            HStack(alignment: .lastTextBaseline) {
                Text("\(hours)")
                    .font(.system(size: 45, weight: .bold))
                    .foregroundColor(.white)
                
                Text("h")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.gray)
                
                Text("\(minutes)")
                    .font(.system(size: 35, weight: .bold))
                    .foregroundColor(.white)
                
                Text("min")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 20)
            .onAppear{
                Task{
                    await health.fetchSleepdata()
                }
            }
        }
    }
}

#Preview {
    SleepSummaryView(health: HealthManager())
}
