//
//  AboutView.swift
//  Mako
//
//  Created by Mark Chan on 2025/5/18.
//

import SwiftUI
import DarockUI

struct AboutView: View {
    var body: some View {
        List {
            Section {
                Link(destination: URL(string: "https://github.com/Darock-Studio/Project-Mako")!) {
                    HStack {
                        Text(verbatim: "GitHub")
                        Spacer()
                        Image(systemName: "arrow.up.forward.square")
                            .fontWeight(.medium)
                    }
                }
            } header: {
                Text("源代码")
                    .textCase(nil)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .padding(.horizontal, -15)
            }
            Section {
                SinglePackageBlock(name: "Alamofire", license: "MIT license")
                SinglePackageBlock(name: "BottomSheet", license: "MIT license")
                SinglePackageBlock(name: "SDWebImage", license: "MIT license")
                SinglePackageBlock(name: "SDWebImageSwiftUI", license: "MIT license")
                SinglePackageBlock(name: "swiftui-introspect", license: "MIT license")
                SinglePackageBlock(name: "SwiftyJSON", license: "MIT license")
            } header: {
                Text("软件包引用")
                    .textCase(nil)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .padding(.horizontal, -15)
            }
            Section {
                Text("Project Mako 仅用于学习 Swift 以及 SwiftUI 开发以及供个人、非商业性地使用，内容版权属于网易云音乐以及音乐创作者。")
            } header: {
                Text(verbatim: "Disclaimer")
                    .textCase(nil)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .padding(.horizontal, -15)
            }
        }
        .navigationTitle("关于 App")
    }
    
    struct SinglePackageBlock: View {
        var name: String
        var license: String
        var body: some View {
            HStack {
                Image(systemName: "shippingbox.fill")
                    .foregroundColor(Color(hex: 0xa06f2f))
                VStack {
                    HStack {
                        Text(name)
                        Spacer()
                    }
                    HStack {
                        Text(license)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                }
            }
        }
    }
}
