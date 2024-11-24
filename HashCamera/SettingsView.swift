//
//  SettingsView.swift
//  HashCamera
//
//  Created by Anto-Yang on 3/28/24.
//

import SwiftUI

struct SettingsView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @State var locationInfo: Bool
    @State var photoFormat: PhotoFileFormat
    
    init() {
        self.locationInfo = CameraSetting.locationInfo
        self.photoFormat = CameraSetting.photoFileFormat
    }
    
    
    var body: some View {
        //Photo Format
        
        VStack {
            
            HStack(alignment: .center) {
                Spacer()
                Text(localizedString(forKey: "N007_1", value: "Settings"))
                    .font(.headline)
                    .padding()
                Spacer()
            }
            .overlay(alignment:.topLeading ) {
                closeButton
            }
            
            List {
//                Section {
//                    Toggle("Location Info", isOn: $locationInfo)
//                        .onChange(of: locationInfo) { newValue in
//                            CameraSetting.locationInfo = newValue
//                        }
//                    
//                }
                
                Picker(localizedString(forKey: "N007_2", value: "Photo Format"), selection: $photoFormat) {
                    ForEach(PhotoFileFormat.allCases) {
                        Text("\($0.string)")
                            .tag($0)
                    }
                }
                .pickerStyle(.inline)
                .onChange(of: photoFormat) { newValue in
                    CameraSetting.photoFileFormat = newValue
                }
                
                Section {
                    Button(action: {
                        EmailHelper.shared
                            .sendEmail(subject: "Help & Feedback",
                                       body:
                                   """
                                   [HashCamera]
                                   Version: \(AppStatus.fullVersion)
                                   Device: \(AppStatus.getModelName())
                                   OS: \(AppStatus.getOsVersion())
                                   
                                   """,
                                       to: "anto.wg.yang@gmail.com"  )
                    }, label: {
                        Text(localizedString(forKey: "N007_3", value: "Email"))
                    })
                }
                
                Section {
                    HStack(alignment: .center) {
                        Text(localizedString(forKey: "N007_4", value: "Version"))
                        Spacer()
                        Text(AppStatus.fullVersion)
                        
                    }
                }
                
            }
        }
        .navigationTitle(localizedString(forKey: "N007_1", value: "Settings"))
    }
    
    private var closeButton: some View {
        Button {
            presentationMode.wrappedValue.dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.headline)
        }
        .buttonStyle(.bordered)
        .clipShape(Circle())
        .tint(.purple)
        .padding()
    }
}

#Preview {
    SettingsView()
}
