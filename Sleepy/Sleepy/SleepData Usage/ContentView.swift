//
//  ContentView.swift
//  Sleepy
//
//  Created by Davide Perrotta on 19/02/25.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    @State private var sleepData: [HKCategorySample] = []
    
    @StateObject private var health = HealthManager()

    
    @State private var showWelcomeSheet = UserDefaults.isFirstLaunch
    
    
    @State private var apiResponse: String = ""
    @State private var sleepTime: Double = 0
    @State private var isLoading: Bool = false
    
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemGray6
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    SleepSummaryView(health: health)
                    .onAppear{
                        //health.fetchSleepdata()
                        UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
                    }

                    // Lista Sonno    
                    SleepTrackerTabView(health: health)
                        .frame(height: 280)
                        .padding(.top, -45)
                    
                    SleepButtonsView()
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
                    //SleepInfoView()
                    SleepMoreInfoView()
                }
                .padding(.top, 20)
            }
            .refreshable {
                await refreshData()
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationTitle("Sonno")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink("Aggiungi Dati", destination: AddDataView(health: health, apiResponse: $apiResponse, isLoading: $isLoading))
                        .font(.system(size: 18, weight: .regular))
                }
            }
        }
        .onAppear {
            Task {
                await health.fetchSleepdata()
            }
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
        .sheet(isPresented: $showWelcomeSheet) {
            WelcomeView(onDismiss: {
                // Chiude il modale
                showWelcomeSheet = false
            }, health: health)
            .background(Color(UIColor.systemBackground))
            .onDisappear {
                // Avvia la richiesta di autorizzazione dopo che il modale è stato chiuso
                Task {
                    await health.requestSleepAuthorization()
                }
            }
        }
    }
    
    func formatTime(seconds: Int) -> (String, String, String) {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let sec = seconds % 60
        return ("\(hours)", "\(minutes)", "\(sec)")
    }
    
    func refreshData() async{
        isLoading = true
        await health.fetchSleepdata()
        isLoading = false
    }
}

extension UserDefaults {
    static var isFirstLaunch: Bool {
        get {
            let hasLaunched = standard.bool(forKey: "hasLaunchedBefore")
            if !hasLaunched {
                standard.set(true, forKey: "hasLaunchedBefore")
            }
            return !hasLaunched
        }
    }
}

#Preview {
    ContentView()
}

