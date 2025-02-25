//
//  SleepMoreInfoView.swift
//  Sleepeer
//
//  Created by Davide Perrotta on 17/02/25.
//

import Foundation
import SwiftUI

struct SleepMoreInfoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sonno: per saperne di più")
                .font(.headline)
                .bold()
                .foregroundColor(.white)
            
            Text("""
            Sonno è in grado di fornirti una panoramica sulle abitudini legate al riposo. I dispositivi di monitoraggio del sonno possono aiutarti a determinare il numero di ore in cui rimani a letto o dormi grazie all’analisi della tua attività fisica e dei movimenti del corpo durante la notte. Puoi inoltre monitorare le abitudini legate al sonno inserendo manualmente una stima delle ore passate a letto o dormendo.
            
            “A letto” include il tempo passato cercando di dormire, ad esempio da quando spegni la luce a quando ti alzi. Sonno indica il periodo di tempo in cui effettivamente dormi.
            """)
            .font(.system(size: 14))
            .foregroundColor(.white)
            .padding()
            .background(Color(UIColor.darkGray))
            .cornerRadius(10)
        }
        .padding()
        .background(Color(UIColor.black))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}


#Preview {
    SleepMoreInfoView()
}
