//
//  DreamLogView.swift
//  WilliDreams
//
//  Created by William Gallegos on 7/25/24.
//

import SwiftUI
import SwiftData
import FirebaseFirestore
import FirebaseAI
import FoundationModels

struct DreamLogView: View {
    @AppStorage("aiSummary") private var aiSummary = ""
    @AppStorage("canAIProcess") private var canAIProcess = true
    
    @Environment(\.modelContext) private var modelContext
    
    @Query private var dreams: [Dream]
    
    @State private var dreamTitle: String = ""
    @State private var dreamDescription: String = ""
    @State private var dreamRanking: Double = 1
    
    @State private var dreamViewState: Int = 1
    
    @State private var isLogging = false
    
    @State private var dreamDate: Date = Date()
    
    @State private var hasTitle: Bool = true
    
    @State private var dreamDatePicker: Bool = false
    
    @State private var friendsCanSee: Bool = true
    
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("userUID") private var userID = ""
    @AppStorage("loginStatus") private var isLoggedIn = false
    
    var body: some View {
        VStack {
            switch dreamViewState {
            case 1:
                DreamSlider(dreamLogViewState: $dreamViewState, nightmareScale: $dreamRanking)
            case 2:
                DreamTitleDesc(dreamTitle: $dreamTitle, dreamDescription: $dreamDescription, dreamViewState: $dreamViewState, shouldShowTitle: $hasTitle, friendsCanSee: $friendsCanSee)
            default:
                Text("View unsupported")
                    .onAppear {
                        if isLogging == false {
                            logDream()
                        }
                    }
            }
        }
        .padding(.horizontal)
        
        .sheet(isPresented: $dreamDatePicker) {
            VStack {
                Spacer()
                Image(systemName: "calendar")
                    .font(.system(size: 100))
                Text("When was this dream?")
                    .font(.largeTitle)
                    .bold()
                    .multilineTextAlignment(.center)
                Spacer()
                DatePicker("", selection: $dreamDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                Spacer()
                Button(action: {
                    dreamDatePicker = false
                }, label: {
                    Text("Confirm")
                        .bold()
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: 50)
                })
                .background {
                    RoundedRectangle(cornerRadius: 90)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding()
        }
        
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            #else
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            #endif
            
            ToolbarItem(placement: .principal) {
                Text(dreamDate, style: .date)
            }
            
            ToolbarItem(placement: .secondaryAction) {
                //Menu("", systemImage: "ellipsis.circle") {
                    Button("Change Date", systemImage: "calendar") {
                        dreamDatePicker = true
                    }
                    if hasTitle {
                        Button("Hide Title", systemImage: "eye.slash") {
                            hasTitle.toggle()
                        }
                    } else {
                        Button("Show Title", systemImage: "eye") {
                            hasTitle.toggle()
                        }
                    }
                //}
            }
        }
        .onChange(of: dreamViewState) {
            if dreamViewState == 3 {
                if isLogging == false {
                    logDream()
                }
            }
        }
    }
    
    func logDream() {
        isLogging = true
        if dreamDescription.isEmpty == false {
            let newDream = Dream(name: dreamTitle)
            newDream.dreamDescription = dreamDescription
            newDream.date = dreamDate
            if dreamTitle.isEmpty {
                hasTitle = false
            }
            newDream.nightmareScale = dreamRanking
            newDream.titleVisible = hasTitle
            newDream.isPublic = friendsCanSee
            modelContext.insert(newDream)
            
            if isLoggedIn {
                let dreamsCollection = Firestore.firestore().collection("UserDreams")
                    .document(userID)
                    .collection("dreams")
                
                let dreamCloud = DreamCloud(dream: newDream, userID: userID)
                
                let newDocRef = dreamsCollection.document()
                do {
                    var data = try Firestore.Encoder().encode(dreamCloud)
                    data["id"] = newDocRef.documentID
                    newDocRef.setData(data) { error in
                        if let error = error {
                            print("Error creating new dream: \(error.localizedDescription)")
                        } else {
                            print("New dream created successfully!")
                        }
                    }
                } catch {
                    print("Error encoding DreamCloud: \(error)")
                }
            }
        }
        if canAIProcess {
            Task {
                var dreamsToAnalyze: [Dream] = []
                
                var int = 0
                let oneWeekAgo = Calendar.current.startOfDay(for: Date.now).addingTimeInterval(-86400 * 7)
                
                for dream in dreams {
                    if Calendar.current.startOfDay(for: dream.date) >= oneWeekAgo {
                        dreamsToAnalyze.append(dream)
                    }
                }
                
                var shouldUseGemini = false
                
                if #available(iOS 26, macOS 26, *) {
                    if SystemLanguageModel.default.isAvailable {
                        do {
                            let response = try await AISummary.summarizeDreams(dreamsToAnalyze: dreamsToAnalyze)
                            aiSummary = response
                        } catch {
                            shouldUseGemini = true
                        }
                    } else {
                        shouldUseGemini = true
                    }
                } else {
                    shouldUseGemini = true
                }
                    
                if shouldUseGemini {
                    print("GEMINI USED")
                    
                    let ai = FirebaseAI.firebaseAI(backend: .googleAI())
                    let model = ai.generativeModel(modelName: "gemini-2.5-flash")
                    
                    var prompt: String = "Summarize the following dreams: \n"
                    
                    for dreamToAnalyze in dreamsToAnalyze {
                        prompt += "Title: \(dreamToAnalyze.name) \n"
                        prompt += "Description: \(dreamToAnalyze.dreamDescription) \n"
                    }
                    
                    let chat = model.startChat()
                    
                    let response = try await chat.sendMessage(prompt)
                    
                    aiSummary = response.text ?? NSLocalizedString("Summary could not be created. Try creating a dream later.", comment: "Error for creating summaries.")
                }
            }
        }
        
        dismiss()
    }
}

#Preview {
    NavigationStack {
        DreamLogView()
            .modelContainer(for: Dream.self, inMemory: true)
    }
}
