//
//  SettingsInterfaceController.swift
//  Opticalc
//
//  Created by Robert McQualter on 27/07/2015.
//
//

import WatchKit
import Foundation


class SettingsInterfaceController: WKInterfaceController {
    var vertexDistance: Double = 12
    var useOcularRx: Bool = false
    
    fileprivate var vdPickerItems: [WKPickerItem] = Array()
    fileprivate var delegate: InterfaceController? = nil
    
    @IBOutlet var vdPicker: WKInterfacePicker!
    @IBOutlet var ocRxSwitch: WKInterfaceSwitch!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Set up picker.
		for vd in 0 ..< 20 {
            let txt:String = "\(vd)mm"
            let item = WKPickerItem()
            
            item.title = txt
            vdPickerItems.append(item)
        }
        
        vdPicker.setItems(vdPickerItems)
        
        // Make sure context is the right thing.
        guard let dict = context as? [String: AnyObject] else {
            return
        }
        
        // Get current vertexDistance and useOcularRx values from context.
        if let vd = dict["VD"] as? Double {
			vdPicker.setSelectedItemIndex(Int(vd))
        }
        
        if let ocRx = dict["USEOCULARRX"] as? Bool {
            useOcularRx = ocRx
            ocRxSwitch.setOn(ocRx)
        }
        
        if let del = dict["DELEGATE"] as? InterfaceController {
            delegate = del
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @IBAction func vdChanged(_ value: Int) {
		vertexDistance = Double(value)
    }
    
    @IBAction func useOcRxChanged(_ value: Bool) {
        useOcularRx = value
    }
    
    @IBAction func doneButtonSelected() {
        delegate?.settingsDone(vertexDistance, useOcularRx: useOcularRx)
    }
}
