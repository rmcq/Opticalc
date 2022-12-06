//
//  ResultsInterfaceController.swift
//  Opticalc
//
//  Created by Robert McQualter on 27/07/2015.
//
//

import WatchKit
import Foundation


class ResultsInterfaceController: WKInterfaceController {

    var delegate: InterfaceController? = nil
    let optiCalc = OpticalCalculator()
    
    @IBOutlet var lensToOrderLabel: WKInterfaceLabel!
    @IBOutlet var rotationLabel: WKInterfaceLabel!
    @IBOutlet var apparentCLRxLabel: WKInterfaceLabel!
    @IBOutlet var ocularRxLabel: WKInterfaceLabel!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        let dict = context as! [String: AnyObject]
        
        if let specRx = dict["SPECRX"] as? LensPrescription,
            let nominalCLRx = dict["CLRX"] as? LensPrescription,
            let overRx = dict["OVERRX"] as? LensPrescription,
            let delegate = dict["DELEGATE"] as? InterfaceController,
            let useOcRx = dict["USEOCULARRX"] as? Bool
        {
            
            // Correct objects. Do what we need.
            self.delegate = delegate
            
            // Do calculations.
            optiCalc.patientRx = specRx
            optiCalc.nominalCLRx = nominalCLRx
            optiCalc.overRx = overRx
            optiCalc.useOcularRx = useOcRx
        
            optiCalc.calcToricRx()
			
            // Update UI.
            lensToOrderLabel.setText(optiCalc.lensToOrder?.rxString)
			rotationLabel.setText(optiCalc.stringFromAxis(optiCalc.rotation, shortString: true))
			apparentCLRxLabel.setText(optiCalc.effectiveCLRx?.rxString)
			
			let ocularRx = specRx.newLensPrescriptionOcularRxWithPowerPrecision(100, axisPrecision: 1)
           	ocularRxLabel.setText(ocularRx.rxString)
        } else {
            lensToOrderLabel.setText("Bad arguments")
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

    @IBAction func doneButtonTapped() {
        if let del = self.delegate {
            del.resultsDone()
        }
    }
}
