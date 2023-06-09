//
//  AddGroupView.swift
//  pens'
//
//  Created by 박상준 on 2023/04/16.
//

import SwiftUI

struct AddGroupView: View {
    @Binding var isPresented: Bool
    @State private var groupName: String = ""
    @State private var userId: Int? = nil
    var onAddGroup: (String) -> Void // 콜백 함수 수정: 그룹 이름 대신 그룹 ID 사용
    @State private var groupAPI = GroupAPI() // GroupAPI 인스턴스 추가

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .shadow(radius: 10)

            VStack {
                Text("그룹 추가하기")
                    .font(.title3)
                    .fontWeight(.light)
                    .padding()
                
                TextField("그룹 이름 입력", text: $groupName)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                HStack{
                    Button(action: {
                        groupAPI.createGroup(groupName: groupName) { result in // createGroup 메소드 호출 수정
                            switch result {
                            case .success(let groupID):
                                print("+++++++++++++그룹 생성 성공+++++++++++++: \(groupID)")
                                onAddGroup(groupName) // 콜백 함수 호출
                            case .failure(let error):
                                print("그룹 생성 실패: \(error)")
                            }
                            isPresented = false
                        }
                    }) {
                        Text("추가")
                            .font(.system(size: 15, weight: .light))
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }.padding()
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("취소")
                            .font(.system(size: 15, weight: .light))
                            .padding()
                            .background(Color.cyan)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .frame(width: 300, height: 300) // 높이를 증가시켜서 그룹 관리자 이름 입력 필드를 포함하도록 수정
    }
}

struct AddGroupView_Previews: PreviewProvider {
    static var previews: some View {
        AddGroupView(isPresented: .constant(false), onAddGroup: {_ in })
    }
}
