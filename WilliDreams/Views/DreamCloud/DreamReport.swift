//
//  DreamReport.swift
//  WilliDreams
//
//  Created by William Gallegos on 3/26/25.
//

import SwiftUI
import WilliKit

struct DreamReport: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    var dream: DreamCloud
    
    @State private var ruleBreaker: User? = nil
    
    @State private var textInput: String = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("Report")
                        .bold()
                    Spacer()
                    Button(action: {
                        dismiss()
                    }, label: {
                        Image(systemName: "x.circle.fill")
                            .foregroundStyle(.red)
                    })
                    .buttonStyle(.borderless)
                    .withHoverEffect()
                }
                Divider()
                Form {
                    if let ruleBreaker = ruleBreaker {
                        Section("Tell us why \(ruleBreaker.username) is breaking the rules.") {
                            TextEditor(text: $textInput)
                                .frame(minHeight: 100)
                                .textEditorStyle(.plain)
                                .scrollDisabled(true)
                        }
                    } else {
                        //WilliLoadingIndicator()
                    }
                }
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
                
                Button(action: {
                    Task {
                        await submitReport()
                    }
                }, label: {
                    Text("Submit")
                        .frame(maxWidth: .infinity, minHeight: 30)
#if !os(tvOS)
                        .foregroundStyle(.white)
#endif
                })
#if !os(tvOS) && !os(visionOS)
                .buttonStyle(WillButtonStyle())
#endif
#if !os(tvOS) && !os(watchOS)
                .keyboardShortcut(.defaultAction)
#endif
                .withHoverEffect()
            }
            .task {
                await ruleBreaker = getUser(userID: dream.author)
            }
#if os(macOS)
            .frame(width: 500, height: 300)
#endif
            .padding()
#if os(iOS)
            .padding(.horizontal)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundStyle(colorScheme == .dark ? .black : .white)
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundStyle(colorScheme == .dark ? Color.gray : Color.gray)
                        .opacity(colorScheme == .dark ? 0.6 : 0.1)
                }
                .padding(.horizontal)
            }
#endif
        }
        .presentationDetents([.height(350)])
#if os(iOS)
        .presentationBackground(.clear)
#endif
        .zIndex(10)
        
    }
    
    var webhookStringURL = "Webhook URL for Discord here"
    
    func submitReport() async {
        guard let webhookURL = URL(string: webhookStringURL) else {
            print("WILLIDEBUG: Invalid webhook URL")
            return
        }
        
        let payload: [String: Any] = [
            "username" : "\(ruleBreaker!.username) (\(ruleBreaker!.userUID))",
            "content": "**Report type:** Dream \n\n**Report reason:**\n\(textInput) \n\n**Dream UUID:** \(dream.uuid)\n"
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            print("WILLIDEBUG: Failed to encode JSON")
            return
        }
        
        var request = URLRequest(url: webhookURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 204 {
                print("WILLIDEBUG: Report submitted successfully")
            } else {
                print("WILLIDEBUG: Failed to submit report. Status Code: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
            }
        } catch {
            print("WILLIDEBUG: Error submitting report: \(error)")
        }
        
        dismiss()
    }
}
