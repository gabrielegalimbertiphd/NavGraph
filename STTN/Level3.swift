//
//  Level3.swift
//  STTN
//
//  Created by OS Programming on 07/06/23.
//

import Foundation

class Level3 {
    public var alpha4:Float=160.0 // OK
    public var alpha3:Float=30.0 // OK
    public var alpha2:Float=10.0 // OK
    public var alpha1:Float=1.0 // OK
    public var previous_state = "start"
    private var previous_message = ""
    
    func generateMessage(angular_error: Float, current_state: String, changeNode: Bool, version_setup: String, range: Float? = 30.0, lateralDistance: Float, timerRepeatInstruction: Double ) -> String{ // SERVE LA DISTANZA
        var message = previous_message
        var t : Double = CFAbsoluteTimeGetCurrent() - timerRepeatInstruction
        
        if (current_state == "arrived") {
            if(previous_state != current_state){
                message = "destination reached"
                previous_state = "arrived"
            } else{
                message = ""
            }
            print("arrived")
        }
        else if (current_state == "outside") { // MARK: OUTSIDE
            
            //if (angular_error <= alpha1 && previous_message=="turn") || (angular_error <= alpha2 && timerRepeatInstruction>=5 && previous_message=="turn") {
            /*if (angular_error <= alpha1 && previous_message=="turn") { //|| (angular_error <= alpha2 && t>=5 && previous_message=="turn") {
                message = "walk lateral" // TODO: MESSAGGIO?
                //previous_state = "O_NR"
            }
            else */
            if (angular_error >= alpha4 && version_setup=="basic") || (angular_error >= alpha4 && version_setup=="advanced") {
                message = "turn"
                //previous_state = "O_R"
            } else {
                message = "lateral"
            }
            if previous_state != current_state{
                Level4().flag_repeat_message=true
            } else {
                Level4().flag_repeat_message=false
            }
            /*if(previous_state == "inside") {
                message = "outside, \(message)"
            }*/
            
            previous_state = "outside"
            print("outside")
        } else if (current_state == "inside") { // MARK: INSIDE
            
            // if (angular_error <= alpha1 && previous_message=="turn") || (angular_error <= alpha2 && t>=5 && previous_message=="turn") || changeTargetNode(changeNode: changeNode, previous_message: previous_message, current_state: current_state, angular_error: angular_error) { // MY PROPOSAL
            print("(angular_error <= alpha1 && previous_message==turn)","\(angular_error) <= \(alpha1) && \(previous_message)==turn")
            print("\(previous_message)==lateral")
            
            print("changeTargetNode",changeTargetNode(changeNode: changeNode, previous_message: previous_message, current_state: current_state, angular_error: angular_error))
            if ((angular_error <= alpha1 && previous_message=="turn") ||
                previous_message=="lateral") ||
                changeTargetNode(changeNode: changeNode, previous_message: previous_message, current_state: current_state, angular_error: angular_error) {
                message = "walk" // TODO: MESSAGGIO?
                //previous_state = "N_NR"
                print("WALK")
            }
            else if (angular_error >= alpha3 && version_setup=="basic") || (angular_error >= range ?? alpha3 && version_setup=="advanced") {
                message = "turn"
                //previous_state = "N_R"
            } 
            /*if(previous_state == "outside") {
                message = "inside, \(message)" // TODO: MESSAGGIO?
            }*/
            
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
        return changeNode && (previous_message == "turn" || previous_message == "lateral") && Synth.shared.volume != 0 && current_state == "inside" && angular_error <= alpha3
        // TODO: angular_error <= alpha3 MAYBE IS NOT GOOD
    }
}
