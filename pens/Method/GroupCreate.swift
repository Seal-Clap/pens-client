//
//  GroupCreate.swift
//  pens'
//
//  Created by 신지선 on 2023/05/02.
//

import Foundation

struct GroupAPI {
    func createGroup(groupName: String, groupAdminUserId: Int, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: APIContants.groupCreateURL) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters : [String: Any] = ["groupName": groupName, "groupAdminUserId": groupAdminUserId]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data, let httpResponse = response as? HTTPURLResponse else { return }
            
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                guard let success = jsonResponse?["success"] as? Bool, let message = jsonResponse?["message"] as? String else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: nil)))
                    return
                }
                
                if httpResponse.statusCode == 201 && success {
                    completion(.success(message))
                } else {
                    completion(.failure(NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}
