//
//  APIService.swift
//  RubyEvents
//
//  Created by Marco Roth on 28.03.2025.
//

import Foundation

enum NetworkError: Error {
  case invalidURL
  case invalidResponse
  case invalidData
  case requestFailed(Error)
}

class APIService {
  static let shared = APIService()

  private init() {}

  func fetchData<T: Decodable>(from endpoint: String, completion: @escaping (Result<T, NetworkError>) -> Void) {
    guard let url = URL(string: endpoint) else {
      completion(.failure(.invalidURL))
      return
    }

    let task = URLSession.shared.dataTask(with: url) { data, response, error in
      if let error = error {
        completion(.failure(.requestFailed(error)))
        return
      }

      guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        completion(.failure(.invalidResponse))
        return
      }

      guard let data = data else {
        completion(.failure(.invalidData))
        return
      }

      do {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        print("JSON structure: \(json ?? [:])")

        let decodedData = try JSONDecoder().decode(T.self, from: data)
        completion(.success(decodedData))
      } catch {
        completion(.failure(.invalidData))
      }
    }

    task.resume()
  }

  func fetchData<T: Decodable>(from endpoint: String) async throws -> T {
    guard let url = URL(string: endpoint) else {
      throw NetworkError.invalidURL
    }

    let (data, response) = try await URLSession.shared.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse,
        (200...299).contains(httpResponse.statusCode) else {
      throw NetworkError.invalidResponse
    }

    do {
      return try JSONDecoder().decode(T.self, from: data)
    } catch {
      throw NetworkError.invalidData
    }
  }
}
