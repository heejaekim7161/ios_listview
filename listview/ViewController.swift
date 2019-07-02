//
//  ViewController.swift
//  listview
//
//  Created by HeejaeKim on 02/07/2019.
//  Copyright © 2019 HeejaeKim. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let REQUEST_LIST_URL: String = "https://api.upbit.com/v1/market/all"
    let REQUEST_ITEM_URL: String = "https://api.upbit.com/v1/candles/days?market="
    let REQUEST_INTERVAL: Double = 0.2
    let CELL_HEIGHT: CGFloat = 50.0

    @IBOutlet var tableView: UITableView!

    let indicator = UIActivityIndicatorView(style: .gray)

    var names: Dictionary<String, String> = [:]
    var items: [Coin] = []
    var requestCount = 0

    struct Coin {
        var name: String
        var changeRate: Float
        var price: Float
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self

        request(url: REQUEST_LIST_URL, completion: onReceiveList)

        indicator.center = CGPoint(x: view.bounds.size.width / 2, y: view.bounds.size.height / 2)
        view.addSubview(indicator)
        indicator.startAnimating()
    }

    func onReceiveList(data: String?) {
        if let jsonArray = toJson(str: data) {
            var delay = 0.0
            for json in jsonArray {
                let unit = json["market"] as! String
                if unit.contains("KRW") {
                    names.updateValue(json["english_name"] as! String, forKey: unit)
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                        self.requestUnit(unit: unit)
                    })
                    delay += REQUEST_INTERVAL
                    requestCount += 1
                }
            }
        }
    }

    func requestUnit(unit: String) {
        request(url: REQUEST_ITEM_URL + unit, completion: onReceiveData)
    }

    func onReceiveData(data: String?) {
        if let jsonArray = toJson(str: data) {
            for json in jsonArray {
                createItem(json: json)
            }
        }

        if requestCount <= items.count {
            DispatchQueue.main.async {
                self.indicator.stopAnimating()
            }
        }
    }

    func createItem(json: Dictionary<String,Any>) {
        if let name = json["market"] as? String,
            let price = (json["trade_price"] as? NSNumber)?.floatValue,
            let changeRate = (json["change_rate"] as? NSNumber)?.floatValue {
            items.append(Coin(name: name, changeRate: changeRate, price: price))
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    func request(url: String, completion: @escaping (_: String?) -> Void) {
        var requester = URLRequest(url: URL(string: url)!)
        requester.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: requester) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                completion(nil)
                return
            }
            if let response = String(data: data, encoding: .utf8) {
                completion(response)
            } else {
                completion(nil)
            }
        }
        task.resume()
    }

    func toJson(str: String?) -> [Dictionary<String,Any>]? {
        if str == nil {
            return nil
        }

        let data = str!.data(using: .utf8)!
        do {
            if let jsonArray = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [Dictionary<String,Any>] {
                return jsonArray
            } else {
                print("bad json: " + str!)
                return nil
            }
        } catch let error as NSError {
            print(error)
            return nil
        }
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CELL_HEIGHT
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "Cell", for: indexPath) as! TableViewCell
        let coin = items[(indexPath as NSIndexPath).row]

        if let name = names[coin.name] {
            cell.name.text = name
        } else {
            cell.name.text = coin.name
        }

        cell.changeRate.text = String(round(coin.changeRate * 10000) / 100) + "%"
        if coin.changeRate > 0.0 {
            cell.price.textColor = UIColor.red
            cell.changeRate.textColor = UIColor.red
            cell.icon.image = UIImage(named: "up.png")
        } else if coin.changeRate < 0.0 {
            cell.price.textColor = UIColor.blue
            cell.changeRate.textColor = UIColor.blue
            cell.icon.image = UIImage(named: "down.png")
        } else {
            cell.price.textColor = UIColor.black
            cell.changeRate.textColor = UIColor.black
            cell.icon.image = UIImage(named: "equal.png")
        }

        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = true
        formatter.numberStyle = .currencyAccounting
        formatter.locale = Locale(identifier: "kr_KR")

        let price = coin.price
        if (price >= 100.0) {
            cell.price.text = formatter.string(from: NSNumber(value: price))
        } else {
            cell.price.text = formatter.string(from: NSNumber(value: price))
        }

        return cell
    }
}
