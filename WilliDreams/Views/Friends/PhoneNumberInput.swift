//
//  PhoneNumberInpit.swift
//  WilliDreams
//
//  Created by William Gallegos on 3/20/25.
//

import SwiftUI
import WilliKit
import Combine

struct PhoneNumberInput: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @State private var phoneNumber: String = ""
    @State private var countryCode: String = "1"
    
    @Binding var contacts: [User]
    
    @AppStorage("userUID") private var userID = ""
    
    var contactSyncing = ContactSyncing()
    
    @State private var isShowingSymbolPicker: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("Enter Phone Number")
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
                //Form {
                    HStack {
                        TextField("CC", text: $countryCode)
#if os(iOS)
                            .keyboardType(.numberPad)
#endif
                            .onReceive(Just(countryCode)) { newValue in
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                if filtered != newValue {
                                    self.countryCode = filtered
                                }
                            }
                            .frame(width: 50)
                        TextField("Phone Number", text: $phoneNumber)
#if os(iOS)
                            .keyboardType(.numberPad)
#endif
                            .onReceive(Just(phoneNumber)) { newValue in
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                if filtered != newValue {
                                    self.phoneNumber = filtered
                                }
                            }
                    }
                    .textFieldStyle(WillTextFieldStyle())
                //}
                //.formStyle(.grouped)
#if os(iOS)
                //.scrollContentBackground(.hidden)
#endif
                
                Spacer()
                HStack {
                    Button(action: {
                        if countryCode.isEmpty == false && phoneNumber.isEmpty == false {
                            Task {
                                await contactSyncing.appendPhoneNumberToFirebase(userUID: userID, phoneNumber: phoneNumber, countryCode: countryCode)
                                var arrayOfUsers = await contactSyncing.getContactsAndCheckUsers()
                                contacts = arrayOfUsers
                                dismiss()
                            }
                        }
                    }) {
                        Text("Check Contacts")
                            .frame(maxWidth: .infinity, minHeight: getPlatform() == .mac ? 32 : 40)
                    }
                    .disabled(countryCode.isEmpty || phoneNumber.isEmpty)
#if !os(tvOS) && !os(visionOS)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .buttonStyle(.borderless)
#endif
#if os(macOS) || os(tvOS)
                    .cornerRadius(20)
#else
                    .cornerRadius(20)
#endif
#if !os(tvOS) && !os(watchOS)
                    .keyboardShortcut(.defaultAction)
#endif
                    .withHoverEffect()
                }
            }
#if os(macOS) || os(visionOS)
            .frame(width: 400, height: 200)
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
        .presentationDetents([.height(300)])
#if os(iOS)
        .presentationBackground(.clear)
#endif
        .zIndex(10)
    }
}
