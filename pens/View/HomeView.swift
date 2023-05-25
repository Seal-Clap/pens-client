//
//  HomeView.swift
//  pens'
//
//  Created by 박상준 on 2023/04/09.
//

import SwiftUI
import Alamofire
import Combine

struct HomeView: View {
    //로그아웃 위해
    @Binding var loginState: Bool?
    @State private var showingLogoutAlert = false
    //그룹
    @State private var grouplist: [String] = []
    @State private var showInviteGroupMember = false
    @State private var showAddGroup = false
    private let groupLoade = GroupLoader()
    //
    @State private var selectedGroup: GroupElement = GroupElement(groupId: 0, groupName: "pens'")
    @State private var showingGroupLeaveAlert = false
    //
    @State private var userId: Int? = nil
    @State private var groups = [GroupElement]()
    //
    @State private var isImporting: Bool = false
    @State private var fileURL: URL?
    
    @ObservedObject var viewModel: AudioCallViewModel
    @State private var addFileView : Bool = false
    //
    @State private var showMenu : Bool = false
  
  
    
    var body: some View {
        NavigationView {
            //그룹 목록부분
            VStack {
                HStack{
                    Image(systemName: "person.line.dotted.person").font(.system(size: 30, weight: .light))
                        .foregroundColor(Color.cyan)
                    Text("그룹").font(.title2)
                        .fontWeight(.regular)
                }
                List {
                    ForEach(groups, id: \.groupId) { group in
                        // Text("Group ID: \(group.groupId)")
                        VStack(alignment: .leading) {
                            Text("\(group.groupName)").font(.system(size: 15, weight : .light))
                        }
                        .padding(.leading)
                        .onTapGesture {
                            selectedGroup = group
                            
                        }.swipeActions {
                            Button(role: .destructive) {
                                delete(group, groups, userId!)
                            } label: {
                                Label("나가기", systemImage: "trash")
                            }
                        }
                    }
                    // duplicated request TODO
                }.onAppear {
                    print("get Group \(groups)")
                    getGroups(completion: { (groups) in
                        self.groups = groups
                    }, userId)
                    groups.sort { $0.groupId > $1.groupId }
                }.listStyle(InsetGroupedListStyle())
                Button(action: {
                    showAddGroup = true
                }, label: { Text("그룹 추가").font(.system(size : 15, weight: .regular)) })
            }
            //음셩채팅부분
            VStack {
//                Text("User ID: \(userId ?? 0)")
//                    .onAppear {
//                        userId = getUserId()
//                    }
                HStack{
                    Text(selectedGroup.groupName)
                        .font(.title2)
                        .fontWeight(.regular)
                    Button(action: {
                        showMenu = true
                    })
                    {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 25, weight : .thin))
                            .foregroundColor(Color.cyan)
                    }.padding(.leading, 10)
                }
                VoiceChannelView(groupId: $selectedGroup.groupId, userId: $userId, viewModel: viewModel)
                //로그아웃
                Button(action: {
                    showingLogoutAlert = true
                }) {
                    Text("로그아웃")
                        .font(.system(size : 15, weight: .regular))
                }.alert(isPresented: $showingLogoutAlert) {
                    Alert(
                        title: Text("로그아웃 확인"),
                        message: Text("로그아웃 하시겠습니까?"),
                        primaryButton: .destructive(Text("로그아웃")) {
                            deleteToken()
                            loginState = false
                        },
                        secondaryButton: .cancel()
                    )
                }
            }
            VStack{
                FileView(selectedGroup: $selectedGroup, isPresented: $addFileView, viewModel: AudioCallViewModel())
            }.navigationBarTitle("문서")
        }.onAppear{
            userId = getUserId()
        }
        .overlay(
            Group {
                if showMenu {
                    GroupMenuView(isPresented: $showMenu, selectedGroup: $selectedGroup)
                }
                if showAddGroup {
                    AddGroupView(isPresented: $showAddGroup, onAddGroup: { groupID in
                        getGroups(completion: { (groups) in
                            self.groups = groups
                        }, userId)
                        groups.sort { $0.groupId > $1.groupId }
                    })
                }
            }
        )
    }
}


struct HomeView_Previews: PreviewProvider {
    @State static private var loginState: Bool? = true
    static var previews: some View {
        HomeView(loginState: $loginState, viewModel: AudioCallViewModel()).environmentObject(LeaveGroup())
    }
}

