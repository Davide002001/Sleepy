//
//  Sleephasesinfo.swift
//  Sleepy
//
//  Created by Davide Perrotta on 17/02/25.
//

import SwiftUI

struct Sleephasesinfo: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Fasi del sonno")
                .font(.headline)
                .bold()
                .foregroundColor(.white)
            
            Text("""
            Mentre dormiamo, il cervello e il corpo si rigenerano. Ogni fase del sonno svolge un ruolo diverso, ma tutte sono essenziali per risvegliarsi freschi e riposati.

            🔴 Veglia
            Per addormentarsi è necessario un certo lasso di tempo e, durante la notte, ci svegliamo periodicamente. Nei grafici, questi periodi sono rappresentati dal termine Veglia.

            🔵 REM
            Gli studi hanno dimostrato che il sonno REM potrebbe rivestire un ruolo fondamentale per la memoria e la rigenerazione cerebrale. Si tratta della fase in cui avviene la maggior parte dei sogni. Inoltre, gli occhi si muovono da un lato all’altro. La fase REM inizia circa 90 minuti dopo essersi addormentati.

            🟠 Principale
            In questa fase, che rappresenta la maggior parte del tempo durante il sonno, l’attività dei muscoli diminuisce e la temperatura corporea si abbassa. Nonostante a volte sia denominata “sonno leggero”, è importante quanto le altre fasi.

            🟢 Profondo
            Nota anche come “sonno a onde lente”, questa fase consente al corpo di riparare le cellule e di rilasciare ormoni essenziali. Si verifica per periodi più lunghi durante la prima metà della notte. A causa dello stato di rilassamento che si raggiunge, spesso risulta difficile svegliarsi dal sonno profondo.
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
    Sleephasesinfo()
}

