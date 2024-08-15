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
                Text("설정")
                    .font(.headline)
                    .padding()
                Spacer()
            }
            .overlay(alignment:.topLeading ) {
                closeButton
            }
            
            List {
                Section {
                    Toggle("Location Info", isOn: $locationInfo)
                        .onChange(of: locationInfo) { newValue in
                            CameraSetting.locationInfo = newValue
                        }
                    
                }
                
                Picker("Photo Format", selection: $photoFormat) {
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
                        Text("Help & Feedback")
                    })
                }
                
                Section {
                    HStack(alignment: .center) {
                        Text("Version")
                        Spacer()
                        Text(AppStatus.fullVersion)
                        
                    }
                }
                
            }
        }
        .navigationTitle("설정")
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
