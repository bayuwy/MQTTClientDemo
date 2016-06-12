//
//  ViewController.swift
//  iOTDevDay
//
//  Created by Bayu Yasaputro on 6/11/16.
//  Copyright © 2016 dycodex. All rights reserved.
//

import UIKit
import MQTTClient

class ViewController: UIViewController {

    @IBOutlet weak var temperatureGaugeView: LMGaugeView!
    @IBOutlet weak var presureGaugeView: LMGaugeView!
    @IBOutlet weak var ledSwitch: UISwitch!
    
    var session: MQTTSession?
    
    let dataTopic = "iotdevday-alpha/smartiotdemo/data"
    let controlTopic = "iotdevday-alpha/smartiotdemo/control"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        temperatureGaugeView.minValue = 0
        temperatureGaugeView.maxValue = 100
        temperatureGaugeView.valueFont = UIFont.boldSystemFontOfSize(32)
        
        presureGaugeView.minValue = 85000
        presureGaugeView.maxValue = 120000
        presureGaugeView.valueFont = UIFont.boldSystemFontOfSize(32)
        
        
        let clientId = UIDevice.currentDevice().identifierForVendor!.UUIDString
        
        let transport = MQTTCFSocketTransport()
        transport.host = "iothub.id"
        transport.port = 1883;
        
        session = MQTTSession()
        session?.clientId = clientId
        session?.userName = "iotdevday-alpha"
        session?.password = "makanpadang"
        session?.transport = transport
        
        session?.delegate = self;
        
        session?.connectAndWaitTimeout(30)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func ledSwitchValueChanged(sender: UISwitch) {
        
        var payload = [String: AnyObject]()
        if sender.on {
            payload["ledControl"] = 1
        }
        else {
            payload["ledControl"] = 0
        }
        
        let theData = try! NSJSONSerialization.dataWithJSONObject(payload, options: [])
        
        session?.publishAndWaitData(theData, onTopic: controlTopic, retain: false, qos: .AtLeastOnce)
    }
}

extension ViewController: MQTTSessionDelegate {
    
    func connected(session: MQTTSession!) {
        
        session.subscribeToTopic(dataTopic, atLevel: .AtLeastOnce) { (error, gQoss) in
            if error != nil {
                print("Subscription failed \(error.localizedDescription)")
            } else {
                print("Subscription sucessfull! Granted Qos: \(gQoss)")
            }
        }
        
//        session.subscribeToTopics([dataTopic: NSNumber(integer: Int(MQTTQosLevel.AtLeastOnce.rawValue)), controlTopic: NSNumber(integer: Int(MQTTQosLevel.AtLeastOnce.rawValue))]) { (error, gQoss) in
//            if error != nil {
//                print("Subscription failed \(error.localizedDescription)")
//            } else {
//                print("Subscription sucessfull! Granted Qos: \(gQoss)")
//            }
//        }
    }
    
    func newMessage(session: MQTTSession!, data: NSData!, onTopic topic: String!, qos: MQTTQosLevel, retained: Bool, mid: UInt32) {
        
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: []) as! [String: AnyObject]
            if let roomTemp = json["roomTemp"] as? Double {
                temperatureGaugeView.value = CGFloat(roomTemp)
            }
            if let roomPress = json["roomPress"] as? Int {
                presureGaugeView.value = CGFloat(roomPress)
            }
//            if let indicLED = json["indicLED"] as? Int {
//                ledSwitch.setOn(Bool(indicLED), animated: true)
//            }
        }
        catch let error as NSError {
            print(error.localizedDescription)
        }
        
        let jsonString = String(data: data, encoding: NSUTF8StringEncoding)?.stringByReplacingOccurrencesOfString("\\\"", withString: "\"")
        print(jsonString)
    }
}

