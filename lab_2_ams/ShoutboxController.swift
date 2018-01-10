//
//  ShoutboxController.swift
//  
//
//  Created by r on 10/01/2018.
//

import UIKit
import DGElasticPullToRefresh
import Alamofire
import SwiftyJSON

extension Date {
    func minutes(from date: Date) -> Int {
        return Calendar.current.dateComponents([.minute], from: date, to: self).minute ?? 0
    }
}

class ShoutboxController: UITableViewController {
    
    var values: Array<Message> = []
    
    @IBOutlet weak var composeButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        self.navigationItem.title = NSLocalizedString("nav-title", comment: "Navigation Title");
        self.composeButton.title = NSLocalizedString("button-text", comment: "Button text");
        
        super.viewDidLoad()
        self.loadData()
        
        let loadingView = DGElasticPullToRefreshLoadingViewCircle()
        loadingView.tintColor = UIColor(red: 78/255.0, green: 221/255.0, blue: 200/255.0, alpha: 1.0)
        tableView.dg_addPullToRefreshWithActionHandler({ [weak self] () -> Void in
            self?.loadData()
            self?.tableView.dg_stopLoading()
            }, loadingView: loadingView)
        tableView.dg_setPullToRefreshFillColor(UIColor(red: 57/255.0, green: 67/255.0, blue: 89/255.0, alpha: 1.0))
        tableView.dg_setPullToRefreshBackgroundColor(tableView.backgroundColor!)
    }
    
    func loadData() {
        Alamofire.request("https://home.agh.edu.pl/~ernst/shoutbox.php?secret=ams2017").responseJSON { response in
            if let json = response.result.value {
                self.values = []
                print("JSON: \(json)") // serialized json response
                for entry in JSON(json)["entries"] {
                    let name = entry.1["name"].string!
                    let messageText = entry.1["message"].string!
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    let messageDate = dateFormatter.date(from: entry.1["timestamp"].string!)!
                    
                    let message = Message(name: name, message: messageText, timestamp: messageDate)
                    self.values.append(message)
                }
                self.values = self.values.sorted(by: { $0.timestamp.compare($1.timestamp) == ComparisonResult.orderedDescending })
                self.tableView.reloadData()
            }
            
        }
    }
    
    @IBAction func onComposeButtonCliecked(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: NSLocalizedString("new-message-title", comment: "New message title"), message: NSLocalizedString("new-message-subtitle", comment: "New message subtitle"), preferredStyle: .alert)
        alertController.addTextField(configurationHandler: { textField in
            textField.placeholder = NSLocalizedString("name-placeholder", comment: "Name placeholder")
        } )
        alertController.addTextField(configurationHandler: { textField in
            textField.placeholder = NSLocalizedString("message-placeholder", comment: "Message placeholder")
        } )
        let sendAction = UIAlertAction(title: NSLocalizedString("send-button-text", comment: "Send button text"), style: .default, handler: { action in
            let name = alertController.textFields?[0].text
            let message = alertController.textFields?[1].text
            self.addNewMessage(name: name!, message: message!)
        })
        alertController.addAction(sendAction)
        let cancelAction = UIAlertAction(title: NSLocalizedString("cancel-button-text", comment: "Cancel button text"), style: .cancel, handler: { _ in })
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true)
    }
    
    func addNewMessage(name: String, message: String) {
        let params: Parameters = [
            "name": name,
            "message": message
        ]
        Alamofire.request("https://home.agh.edu.pl/~ernst/shoutbox.php?secret=ams2017", method: .post, parameters: params).responseJSON{response -> Void in
            print(response)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return values.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath)
        
        let d = Date()
        
        cell.textLabel?.text = "\(d.minutes(from: self.values[indexPath.row].timestamp)) " + NSLocalizedString("cell-title-text", comment: "Cell title text");
        cell.detailTextLabel?.text = "\(self.values[indexPath.row].name) " + NSLocalizedString("cell-subtitle-text", comment: "Cell subtitle text") + " \(self.values[indexPath.row].message)"

        return cell
    }
}
