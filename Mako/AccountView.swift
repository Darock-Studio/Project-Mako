//
//  AccountView.swift
//  Mako
//
//  Created by Mark Chan on 2025/5/10.
//

import SwiftUI
import DarockUI
import NotifKit
import Alamofire
import DarockFoundation

struct AccountView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("IsLoggedIn") var isLoggedIn = false
    @AppStorage("CachedUserName") var cachedUserName = ""
    var body: some View {
        NavigationStack {
            List {
                if isLoggedIn {
                    Section {
                        HStack {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 40))
                                .foregroundStyle(.accent)
                            Text(cachedUserName)
                        }
                        Button("退出登录", role: .destructive) {
                            isLoggedIn = false
                            cachedUserName = ""
                        }
                    }
                } else {
                    NavigationLink(destination: { LoginView() }, label: {
                        Label("登录", systemImage: "key.fill")
                    })
                }
//                Section {
//                    NavigationLink(destination: { AboutView() }, label: {
//                        Label("关于 App", systemImage: "info.circle.fill")
//                    })
//                }
            }
            .navigationTitle("账户")
            .withDismissButton {
                dismiss()
            }
        }
    }
    
    struct LoginView: View {
        @Environment(\.dismiss) var dismiss
        @AppStorage("CachedUserName") var cachedUserName = ""
        @State var usernameInput = ""
        @State var passwordInput = ""
        @State var isLoggingIn = false
        var body: some View {
            Form {
                Section {
                    TextField("手机号", text: $usernameInput)
                    #if os(iOS)
                        .keyboardType(.numberPad)
                    #endif
                    SecureField("密码", text: $passwordInput)
                }
                Section {
                    Button(action: {
                        isLoggingIn = true
                        requestJSON("\(apiBaseURL)/login/cellphone?phone=\(usernameInput)&md5_password=\(passwordInput.md5)&timestamp=\(Int(Date.now.timeIntervalSince1970))0000") { respJson, isSuccess in
                            if isSuccess, let cookie = respJson["token"].string {
                                UserDefaults.standard.set(
                                    cookie
                                        .components(separatedBy: ";")
                                        .map { $0.trimmingCharacters(in: .whitespaces) }
                                        .filter { $0.contains("=") && !$0.lowercased().hasPrefix("max-age") && !$0.lowercased().hasPrefix("expires") && !$0.lowercased().hasPrefix("path") }
                                        .joined(separator: "; "),
                                    forKey: "AccountCookie"
                                )
                                UserDefaults.standard.set(true, forKey: "IsLoggedIn")
                                cachedUserName = respJson["profile"]["nickname"].string ?? ""
                                dismiss()
                            } else {
                                
                            }
                            isLoggingIn = false
                        }
                    }, label: {
                        if !isLoggingIn {
                            Text("登录")
                        } else {
                            ProgressView()
                                .centerAligned()
                        }
                    })
                    .disabled(usernameInput.isEmpty || passwordInput.isEmpty || isLoggingIn)
                }
            }
            .navigationTitle("登录")
            .interactiveDismissDisabled(!usernameInput.isEmpty || !passwordInput.isEmpty)
        }
    }
}
