//
//  GroupMenuView.swift
//  pens
//
//  Created by 박상준 on 2023/05/25.
//

import SwiftUI

struct GroupMenuView: View {
    @Binding var isPresented: Bool
    @Binding var selectedGroup: GroupElement
    @State private var showInviteGroupMember : Bool = false
    @State private var showGroupUsers : Bool = false
    @State private var showCreateChannel : Bool = false
    
    @ObservedObject var voiceChannelModel: VoiceChannelModel
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .shadow(radius: 10)
            VStack {
                HStack{
                    Text(selectedGroup.groupName)
                        .font(.title3)
                        .fontWeight(.light)
                        .padding()
                }
                List{
                    //초대
                        Button(action: {
                            showInviteGroupMember = true
                        }) {
                            Text("그룹 멤버 초대하기").font(.system(size: 15, weight: .light))
                        }
                    //멤버 목록보기
                        Button(action: {
                            showGroupUsers = true
                           
                        }) {
                            Text("그룹 멤버 목록보기").font(.system(size: 15, weight: .light))
                        }
                    //채널 생성
                    Button(action: {
                       showCreateChannel = true
                    }) {
                        Text("음성 채널 생성하기").font(.system(size: 15, weight: .light))
                    }

                    
                }
                Button(action: {
                    isPresented = false
                }) {
                    Text("닫기")
                        .font(.system(size: 15, weight: .light))
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }.padding()
            }
        }.frame(width: 300, height: 350)
            .overlay{
                Group{
                    if showInviteGroupMember {
                        InviteGroupMemberView(isPresented: $showInviteGroupMember, groupId: selectedGroup.groupId)
                    }
                    if showGroupUsers {
                        GroupUsersView(isPresented: $showGroupUsers, groupId: selectedGroup.groupId)
                    }
                    if showCreateChannel{
                        CreateVoiceChannelView(voiceChannelModel: voiceChannelModel, isPresented : $showCreateChannel, groupId: selectedGroup.groupId)
                    }
                }
            }
    }
}

//struct GroupMenuView_Previews: PreviewProvider {
//    static var selectedGroup: GroupElement = GroupElement(groupId: 0, groupName: "pens'")
//    static var previews: some View {
//        GroupMenuView(isPresented: .constant(false), selectedGroup: .constant(selectedGroup))
//    }
//}
