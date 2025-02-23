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
    
    @State private var showSheet = false  // Stato per mostrare il foglio delle info sulle fasi del sonno
    
    
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
                    
                    // 🛌 Media Secondi a Letto
                    HStack(spacing: 5) {
                        Text("🛌")
                            .font(.system(size: 17))
                        Text("MEDIA SEC. A LETTO")
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
                            Sleephasesinfo() // Mostra la tua View
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading)
                    .padding(.top, 20)

                    let (hours, minutes) = formatTime(seconds: Int(health.timeInBed))
                    HStack {
                        HStack(alignment: .lastTextBaseline) {
                            Text(hours)
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("h")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Text(minutes)
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("min")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 20)
                    }
                    .onAppear{
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
            health.requestSleepAuthorization()
            Task {
                health.fetchSleepdata() 
            }
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
        .sheet(isPresented: $showWelcomeSheet) {
            WelcomeView {
                showWelcomeSheet = false
            }
            .background(Color(UIColor.systemBackground))
        }
    }
    
    func formatTime(seconds: Int) -> (String, String) {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return ("\(hours)", "\(minutes)")
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

