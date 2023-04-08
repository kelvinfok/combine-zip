//
//  ViewController.swift
//  multiple-apis
//
//  Created by Kelvin Fok on 8/4/23.
//

import UIKit
import Combine
// Making multiple APIs asynchronously with Combine Zip operator

class ViewController: UIViewController {

  private let apiService = APIService()
  private var cancellables = Set<AnyCancellable>()

  override func viewDidLoad() {
    super.viewDidLoad()
//    fetchAPISequentially()
//    fetchAPIAsynchronously()
    fetchAPIWithCombineZip()
  }

  private func fetchAPIWithCombineZip() {
    apiService.fetch().sink { completion in
      print(completion)
    } receiveValue: { (users, posts) in
      print(">>> done with zip \(users.count) - \(posts.count)")
    }.store(in: &cancellables)
  }

  private func fetchAPISequentially() {
    apiService.fetchUsers { [weak self] result in
      if case .success(let users) = result {
        self?.apiService.fetchPosts(completion: { result in
          if case .success(let posts) = result {
            print(">>> done sequentially \(users.count) - \(posts.count)")
          }
        })
      }
    }
  }

  private func fetchAPIAsynchronously() {
    let group = DispatchGroup()
    var users: [User] = []
    var posts: [Post] = []
    group.enter()
    apiService.fetchUsers { result in
      group.leave()
      if case .success(let value) = result {
        users = value
      }
    }
    group.enter()
    apiService.fetchPosts { result in
      group.leave()
      if case .success(let value) = result {
        posts = value
      }
    }
    group.notify(queue: .main) {
      print(">>> done asynchronously \(users.count) - \(posts.count)")
    }
  }
}

class APIService {

  func fetchPosts(completion: @escaping (Result<[Post], Error>) -> Void) {
    let urlString = "https://jsonplaceholder.typicode.com/posts"
    let request = URLRequest(url: URL(string: urlString)!)
    URLSession.shared.dataTask(with: request) { data, res, error in
      if let error = error {
        completion(.failure(error))
      } else {
        let posts = try! JSONDecoder().decode([Post].self, from: data!)
        completion(.success(posts))
      }
    }.resume()
  }

  func fetchUsers(completion: @escaping (Result<[User], Error>) -> Void) {
    let urlString = "https://jsonplaceholder.typicode.com/users"
    let request = URLRequest(url: URL(string: urlString)!)
    URLSession.shared.dataTask(with: request) { data, res, error in
      if let error = error {
        completion(.failure(error))
      } else {
        let users = try! JSONDecoder().decode([User].self, from: data!)
        completion(.success(users))
      }
    }.resume()
  }

  private func fetchUsers() -> AnyPublisher<[User], Error> {
    URLSession.shared.dataTaskPublisher(
      for: URL(string: "https://jsonplaceholder.typicode.com/users")!)
    .map { $0.data }
    .decode(type: [User].self, decoder: JSONDecoder())
    .eraseToAnyPublisher()
  }

  private func fetchPosts() -> AnyPublisher<[Post], Error> {
    URLSession.shared.dataTaskPublisher(
      for: URL(string: "https://jsonplaceholder.typicode.com/posts")!)
    .map { $0.data }
    .decode(type: [Post].self, decoder: JSONDecoder())
    .eraseToAnyPublisher()
  }

  func fetch() -> AnyPublisher<([User], [Post]), Error> {
    Publishers.Zip(
      fetchUsers(),
      fetchPosts())
    .eraseToAnyPublisher()
  }

}


struct User: Decodable, Hashable {
  let id: Int
  let username: String
}

struct Post: Decodable, Hashable {
  let id: Int
  let title: String
}
