//
//  Level3.swift
//  STTN
//
//  Created by OS Programming on 07/06/23.
//

import Foundation

class Level3 {
    public var alpha3_outside:Float=135.0 // OK
    public var alpha2_inside:Float=30.0 // OK
    public var alpha2_outside:Float=45.0 // OK used only for outside
    public var alpha1:Float=1.0 // OK
    public var previous_state = "start"
    private var previous_message = ""
    
    func generateMessage(angular_error: Float, current_state: String, changeNode: Bool, version_setup: String, range: Float? = 30.0, rangeL: Float? = 30.0, rangeR: Float? = 30.0, lateralDistance: Float, timerRepeatInstruction: Double ) -> String{ // SERVE LA DISTANZA
        var message = previous_message
        var t : Double = CFAbsoluteTimeGetCurrent() - timerRepeatInstruction
        
        if (current_state == "arrived") {// MARK: ARRIVED
            if(previous_state != current_state){
                message = "destination reached"
                previous_state = "arrived"
            } else{
                message = ""
            }
            print("arrived")
        }
        else if (current_state == "outside") { // MARK: OUTSIDE

            /*if (abs(angular_error) >= alpha4 && version_setup=="basic") || (abs(angular_error) >= alpha4 && version_setup=="advanced") {
                message = "turn"
            } else {
                message = "lateral"
            }*/
            
            if (abs(angular_error) >= alpha3_outside) {
                message = "turn"
            } else if (abs(angular_error) > alpha2_outside && abs(angular_error) < alpha3_outside && previous_message != "turn") {
                message = "lateral"
            } else if
                (abs(angular_error) <= alpha2_outside && (previous_message == "walk")) || (abs(angular_error) <= alpha1 && (previous_message == "lateral")) {
                message = "walk"
            }
            else {
                message = "walk"
            }
            
            
            if previous_state != current_state{
                Level4().flag_repeat_message=true
            } else {
                Level4().flag_repeat_message=false
            }
            
            previous_state = "outside"
            print("outside")
        } else if (current_state == "inside") { // MARK: INSIDE
            let evaluateRangeL : Bool = angular_error<0.0 && (abs(angular_error) >= rangeL ?? alpha2_inside)
            let evaluateRangeR : Bool = angular_error>0.0 && (abs(angular_error) >= rangeR ?? alpha2_inside)
            
            if ((abs(angular_error) <= alpha1 && previous_message=="turn") ||
                previous_message=="lateral") ||
                changeTargetNode(changeNode: changeNode, previous_message: previous_message, current_state: current_state, angular_error: abs(angular_error)) {
                message = "walk"
            }
            /*else if (abs(angular_error) >= alpha2_inside && version_setup=="basic") || (abs(angular_error) >= range ?? alpha2_inside && version_setup=="advanced") {*/
            else if (abs(angular_error) >= alpha2_inside && version_setup=="basic")
                        ||
                       (((evaluateRangeL) || (evaluateRangeR))  && version_setup=="advanced") {
                message = "turn"

            } 

            
            if previous_state != current_state{
                Level4().flag_repeat_message=true
            } else {
                Level4().flag_repeat_message=false
            }
            previous_state = "inside"
            print("inside")
        }
        print("message",message)
        
        previous_message = message
        
        return message
        
    }
    
    // change Node while i'm into the safe area
    func changeTargetNode(changeNode: Bool, previous_message: String, current_state: String, angular_error: Float) -> Bool{
        return changeNode && (previous_message == "turn" || previous_message == "lateral") && Synth.shared.volume != 0 && current_state == "inside" && angular_error <= alpha2_inside
        // TODO: angular_error <= alpha3 MAYBE IS NOT GOOD
    }
}
