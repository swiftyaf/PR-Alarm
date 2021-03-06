//
//  ContentView.swift
//  Pull Request Alarm
//
//  Created by Dimitar Chakarov on 29/05/2020.
//  Copyright © 2020 Dimitar Chakarov. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var helper = RepositoryHelper()
    @State var token: String = ""
    @State var mineOnly: Bool = false
    @State var enterpriseGitHub: Bool = false
    @State var enterpriseGitHubUrl: String = ""
    @State var gitHubOrg: String = ""
    var alarmDaemon = AlarmDaemon()
    
    var body: some View {
        VStack {
            Section {
                HStack {
                    SecureField("GitHub Token", text: $token)
                    Spacer()
                    TextField("GitHub Org, e.g. my-team", text: $gitHubOrg)
                }.padding([.horizontal, .top])
                HStack {
                    Toggle(isOn: $enterpriseGitHub) {
                        Text("Use Enterprise GitHub?")
                    }
                    if enterpriseGitHub {
                        TextField("GitHub URL, e.g. github.company.com", text: $enterpriseGitHubUrl)
                    }
                    Spacer()
                }.padding([.horizontal])
                Button("Update") {
                    self.helper.settingsUpdated(token: self.token, enterpriseEnabled: self.enterpriseGitHub, url: self.enterpriseGitHubUrl, org: self.gitHubOrg)
                    self.alarmDaemon.start(using: self.helper)
                }.disabled(token.isEmpty)
                if !token.isEmpty {
                    Divider()
                    HStack {
                        Toggle(isOn: $mineOnly) {
                            Text("Show only my PRs")
                        }
                        Spacer()
                    }.padding([.horizontal])
                }
            }
            Section {
                List {
                    ForEach(helper.reposWithPRs) { repo in
                        Section(header: Text("\(repo.name)")) {
                            ForEach(self.helper.pulls[repo.full_name]!, id: \.id) { pull in
                                Group {
                                    if pull.user.login == self.helper.userLogin || !self.mineOnly {
                                        PRCell(helper: self.helper, repo: repo, pull: pull)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            self.gitHubOrg = self.helper.org ?? ""
            self.enterpriseGitHubUrl = self.helper.customUrl ?? ""
            self.enterpriseGitHub = self.helper.customUrl != nil
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct PRCell: View {
    let helper: RepositoryHelper
    let repo: Repository
    let pull: PullRequest
    
    var body: some View {
        HStack {
            Text("\(pull.mergeableDisplayValue)")
            Button("\(pull.title)") {
                NSWorkspace.shared.open(self.pull.html_url)
            }
            if pull.mergeableDisplayValue == "🟢" {
                Button("Merge") {
                    self.helper.merge(repo: self.repo.full_name, number: self.pull.number)
                }
            }
        }.padding([.horizontal])
        
    }
}
