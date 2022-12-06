//
//  SpecRxEntry.swift
//  Opticalc
//
//  Created by Robert McQualter on 26/07/2015.
//
//

import Foundation
import WatchKit

class SpecRxEntry: WKInterfaceController {
    
    @IBOutlet var sphereDecimalPicker: WKInterfacePicker!
    @IBOutlet var spherePicker: WKInterfacePicker!
    @IBOutlet var cylPicker: WKInterfacePicker!
    @IBOutlet var axisPicker: WKInterfacePicker!
    @IBOutlet var rxLabel: WKInterfaceLabel!
    @IBOutlet var titleLabel: WKInterfaceLabel!

    var spherePickerItems: [WKPickerItem]
    var decimalPickerItems: [WKPickerItem]
    var cylPickerItems: [WKPickerItem]
    var axisPickerItems: [WKPickerItem]
    
    var sphPickerVal:Int = 0
    var sphDecimalPickerVal:Int = 0
    var cylPickerVal:Int = 0
    var axisPickerVal:Int = 0
    
    var lensPower:LensPrescription
    
    var delegate: InterfaceController? = nil
    
    override init() {
        self.spherePickerItems = Array()
        self.decimalPickerItems = Array()
        self.cylPickerItems = Array()
        self.axisPickerItems = Array()
        self.lensPower = LensPrescription()
        
        // Set up picker arrays.
		for i in -20 ..< 20 {
            let wkPicker = WKPickerItem()
            var str:String = ""
            
            if (i == 0) {
                // -0
                str = String.localizedStringWithFormat("%1.0f", -0.001)
            } else {
                str = String.localizedStringWithFormat("%+3li", (i < 0 ? i : i - 1))
            }
            
            wkPicker.title = str

            self.spherePickerItems.append(wkPicker)
        }
        
        // decimals.
		for j in 0 ..< 4 {
            let wkPicker = WKPickerItem()
			let k:Float = Float(j)
            var str = String.localizedStringWithFormat("%.2f", k / 4.0)
            str.remove(at: str.startIndex) // Remove the leading zero.
            wkPicker.title = str
            
            self.decimalPickerItems.append(wkPicker)
        }
        
        // cyl.
		for k in stride(from: 0, to: -10, by: -1) {
            let wkPicker = WKPickerItem()
            var str:String = ""
			
            if k == 0 {
                str = "DS"
            } else {
                str = String.localizedStringWithFormat("%+.2f", Float(k) / 4.0)
            }
            wkPicker.title = str
            self.cylPickerItems.append(wkPicker)
        }
        
        // Axis.
        for axis in 1 ..< 37 {
            let wkPicker = WKPickerItem()
            let str:String = String.localizedStringWithFormat("x%3li", axis * 5)
            
            wkPicker.title = str
            self.axisPickerItems.append(wkPicker)
        }
    }
    
    override func awake(withContext context: Any?) {
        let dict = context as! [String: AnyObject]
        
        if  let power: LensPrescription = dict["RX"] as? LensPrescription,
            let title:String = dict["TITLE"] as? String,
            let del: InterfaceController = dict["DELEGATE"] as? InterfaceController {
                self.lensPower = power
                titleLabel.setText(title)
                self.delegate = del
        }
 
        // If axis is zero, that really means it's a plano Rx, so set axis to 90.
        if self.lensPower.axis == 0 {
            self.lensPower.axis = 90
        }
        
        spherePicker.setItems(self.spherePickerItems)
        self.sphereDecimalPicker.setItems(self.decimalPickerItems)
        self.cylPicker.setItems(self.cylPickerItems)
        self.axisPicker.setItems(self.axisPickerItems)

        setPickerToRx()
        updateRxText()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

	override func willDisappear() {
		delegate?.rxEntryDoneWithRx(lensPower)
	}
	
    func setPickerToRx() {
        // Update the selected items.
        var sphRow, sphDecRow, cylRow, axisRow: Double
        
        (sphRow, sphDecRow) = modf(lensPower.sph) // Get integer part and decimal part.
        
        sphDecRow = abs(sphDecRow) * 4.0
        sphRow += 20;
        
        if (lensPower.sph >= 0) {
            sphRow += 1;
        }
        
        cylRow = abs(lensPower.cyl * 4.0);
        axisRow = lensPower.axis / 5 - 1;
        
        sphPickerVal = Int(sphRow)
        sphDecimalPickerVal = Int(sphDecRow)
        cylPickerVal = Int(cylRow)
        axisPickerVal = Int(axisRow)
        
        spherePicker.setSelectedItemIndex(sphPickerVal)
        sphereDecimalPicker.setSelectedItemIndex(sphDecimalPickerVal)
        cylPicker.setSelectedItemIndex(cylPickerVal)
        axisPicker.setSelectedItemIndex(axisPickerVal)
    }
    
    func updateRxText() {
        var sphPower, cylPower, axis: Double
        
        NSLog("%i", sphPickerVal)
        
        let sphString:String = spherePickerItems[sphPickerVal].title!
        let sphDecimal:String = decimalPickerItems[sphDecimalPickerVal].title!
        let cylString:String = cylPickerItems[cylPickerVal].title!
	
		sphPower = LensPrescription.doubleFromString(sphString)
        if sphPickerVal <= 20 {
            sphPower -= LensPrescription.doubleFromString(sphDecimal)
        } else {
            sphPower += LensPrescription.doubleFromString(sphDecimal)
        }

		cylPower = LensPrescription.doubleFromString(cylString)
        axis = Double(axisPickerVal + 1) * 5
        
        self.lensPower.sph = sphPower
        self.lensPower.cyl = cylPower
        self.lensPower.axis = axis
		
        let rxString: String = self.lensPower.rxString as String
        self.rxLabel.setText(rxString)
    }
    
    @IBAction func spherePickerChanged(_ value: Int) {
        self.sphPickerVal = value
        self.updateRxText()
    }
    
    @IBAction func sphereDecimalPickerChanged(_ value: Int) {
        self.sphDecimalPickerVal = value
        self.updateRxText()
    }
    
    @IBAction func cylPickerChanged(_ value: Int) {
        self.cylPickerVal = value
        self.updateRxText()
    }
    
    @IBAction func axisPickerChanged(_ value: Int) {
        self.axisPickerVal = value
        self.updateRxText()
    }
    
}
