//
//  SettingsView.swift
//  HashCamera
//
//  Created by Anto-Yang on 3/28/24.
//

import SwiftUI

/// SettingsView를 감싸는 회전 제한 ViewController
final class PortraitSettingsViewController: UIViewController {

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var shouldAutorotate: Bool {
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let settingsView = SettingsView()
        let hostingController = UIHostingController(rootView: settingsView)
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.didMove(toParent: self)
    }
}

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
        
        NavigationView {
            VStack {
                
                List {
 
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
                        NavigationLink(destination: WidgetSettingView()) {
                            Text(localizedString(forKey: "N007_5", value: "Widget Setting"))
                        }
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
                  
                        HStack(alignment: .center) {
                            Text(localizedString(forKey: "N007_4", value: "Version"))
                            Spacer()
                            Text(AppStatus.fullVersion)
                            
                        }
                    }
                    
                }
            }
            .navigationTitle(localizedString(forKey: "N007_1", value: "Settings"))
            .navigationBarItems(leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(uiImage: SystemUIImage.xmark.withRenderingMode(.alwaysTemplate))
                    .resizable()
                    .scaledToFit()
                    .tint(.blue)
                    .frame(height:18)
            })
        } //./NavigationView
    }

}

#Preview {
    SettingsView()
}
