///
//  AudioController.swift
//  STTN
//
//  Created by OS Programming on 07/06/23.
//

import Foundation
import AVFoundation

class Level4_try {
    
    private var dingPlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "ShortDing", ofType: "mp3")!))
    
    private var updateTargetAnglePlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "earcon", ofType: "wav")!))
    private var jumpPlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "repositioning", ofType: "wav")!))
    private var emergencyPlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "emergency", ofType: "wav")!))
    
    private let voice = AVSpeechSynthesisVoice(language: "en-US")!
    private var speech_synthesizer = AVSpeechSynthesizer()
    var lastText = ""
    private var beeping = false
    private var lastAngleSector = 1
    var selectedSonification = 1 ///0: Ping     1: Tick     2: Notes
    private var afterNSeconds = 5
    var stretchLength : Float? = nil
    private var sectorSize : Float? = nil
    var angleLength : Float? = nil
    private var angleSectorSize : Float? = nil
    private var timeLastThingSaid = NSDate().timeIntervalSince1970-7
    private var timeLastDing = NSDate().timeIntervalSince1970-7
    private var lastThingSaid = ""
    
    public var startSonification:Bool = false
    private var talkFinished:Bool = false
    public var flag_repeat_message:Bool = false
    
    public var previous_direction:String = ""
    public var previous_state:String = ""
    
    public var timerRepeatInstruction: Double = 0.0
    public var t:Double = 0.0
    
    public var debugConditions = ""
    
    // se è già stato comunicato il messaggio e ha già finito di parlare dopo 1.2 secondi. altrimenti sonifico
    func speak(message: String, angular_difference: Float? = nil, range: Float = 30.0, distanceFromTarget: Float? = nil, safeAreaRadius: Float? = nil, direction: String? = nil, movement : Float? = nil, state: String, changeNode: Bool, changePath:Bool, repeatInstructionFlag:Bool) {
        t = CFAbsoluteTimeGetCurrent() - timerRepeatInstruction
        // se si verifica una di queste condizioni allora non usare la sonificazione e devi dire il messaggio:
        // 1- se il messaggio cambia serve che dico il nuovo messaggio. se sto svoltando/camminando voglio continuare eccetto in casi particolari trattati in seguito.
        let condition1 = self.lastText != message
        // 2- se cambia la direzione, sto svoltando e la sonificazione è stata attivata e non è maggiore di 160 gradi
        //let condition2 = (previous_direction != direction && message.contains("turn") && startSonification && abs(angular_difference ?? 0) >= range && abs(self.angleLength ?? 0) < 160)
        // abs(self.angleLength ?? 0) < 160) da tenere perchè evita che nell'alternanza tra 180 e -180 venga ripetuto "turn around"
        let condition2 = (previous_direction != direction && message.contains("turn") && startSonification && abs(self.angleLength ?? 0) < 160)
        // 3- se sono inside un istante prima ed outside un istante dopo e viceversa
        let condition3 = (previous_state=="inside" && state=="outside")
        // 4- se sono outside un istante prima ed inside un istante dopo e viceversa
        let condition4 = (previous_state=="outside" && state=="inside")
        // 5- se chiedo di ripetere l'istruzione
        let condition5 = repeatInstructionFlag
        // 6- se sono più o meno direzionato e comincio a camminare e sono passati più di 5 secondi.
        //var condition6 = ( movement != nil && (movement! < 0.2 || movement! > 2.0 ) && message.contains("turn") && Int(t)%afterNSeconds==0 && Int(t)>0 && abs(angular_difference ?? 0)  >= Level3().alpha3)
        //let condition6 = false && message.contains("turn") && Int(t)%afterNSeconds==0 && Int(t)>0  // MARK: TIMER
        let condition6 = false
        // se mi sono spostato un metro indipendentemente dalla istruzione di rotazione.
        //var condition7 = movement != nil && movement! >= 1 && message.contains("turn") // MARK: SPOSTAMENTO
        //var condition7=false
        let condition7 = false
        // cambio del percorso
        var condition8 = changePath
        
        guard condition1 || condition2 || condition3 || condition4 || condition5 || condition6 || condition7 || condition8 else {
            // TODO: Level3().alpha3 non sarebbe corretto
            if !startSonification{ // set angle and distance required again after wait 1.2s
                
                if message.contains("walk") { // when set the new angle or distance set volume to 0
                    self.stretchLength = distanceFromTarget!
                } else if message.contains("turn") {
                    self.angleLength = abs(angular_difference!)
                }
                Synth.shared.volume = 0
            } else { // after setting the new angle or distance set volume to 0.8
                Synth.shared.volume = 0.8
            }
            
            if startSonification && (angular_difference != nil || distanceFromTarget != nil) {
                
                // cambio angolo target e riproduco earcon che indica update della svolte se: cambia il nodo, sto ruotando, il volume non è a zero, il mio stato è inside, angolo è maggiore di alpha3 // e la distanza dal prossimo target è maggiore del raggio della safe area.
                if changeNode && message.contains("turn") && Synth.shared.volume != 0 && state == "inside" && angular_difference ?? range >= range { // && distanceFromTarget ?? 1 >= safeAreaRadius ?? 1 {
                    Synth.shared.volume = 0
                    //self.angleLength = abs(angular_difference!)
                    self.startSonification=false // permette di cambiare l'angolo target perchè lo imposto a riga 70!!!!
                    playUpdateTargetAngleSound()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
                        //Synth.shared.volume = 0.8
                        self.startSonification=true
                    }
                }
                
                self.sonificate(message: message, angular_difference: angular_difference!, distanceFromTurn: distanceFromTarget!, safeAreaRadius: safeAreaRadius!, state: state)
                print("self.sonificate finished")
                print()
            }
            
            if message.contains("destination reached") || state == "Arrived" || message.contains("update"){
                let utterance = AVSpeechUtterance(string:message)
                self.startSonification=false
                Synth.shared.audioEngine.stop()
                utterance.rate = 0.5
                utterance.pitchMultiplier = 0.8
                utterance.postUtteranceDelay = 0
                utterance.preUtteranceDelay = 0
                utterance.voice = self.voice
                Synth.shared.volume = 0
                Synth.shared.frequency = 0
                self.playGoalReachedSound()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                    self.speech_synthesizer.speak(utterance)
                }
            }
            previous_state = state
            return
        }
        
        self.speech_synthesizer.stopSpeaking(at: .immediate)
        
        
        if message.contains("walk") && distanceFromTarget != nil { // if the instruction is walk, set the distance to the target
            self.stretchLength = distanceFromTarget!
            self.angleLength = nil
        } else if message.contains("turn") && angular_difference != nil { // if the instruction is turn, set the angular difference with respect to the target
            self.angleLength = abs(angular_difference!) //180-abs((angular_difference!-180).truncatingRemainder(dividingBy: 180))
            self.stretchLength = nil
        } else {
            self.angleLength = nil
            self.stretchLength = nil
        }
        // reset sonification.
        self.startSonification=false
        Synth.shared.audioEngine.stop()
        
        // if the sonification is not started and the angular error or the distance from target is defined, start a new sonification and set start sonification.
        if (angular_difference != nil || distanceFromTarget != nil) && !self.startSonification{
            //print("start timer")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2){
                self.startSonification=true
                do {
                    try Synth.shared.audioEngine.start()
                    if message.contains("turn"){
                        Synth.shared.setWaveformTo(Oscillator.square)
                    } else if message.contains("walk"){
                        Synth.shared.setWaveformTo(Oscillator.IS_Walk)
                    } else {
                        Synth.shared.setWaveformTo(Oscillator.square)
                    }
                    
                } catch {
                    print("Could not start engine: \(error.localizedDescription)")
                }
            }
            //self.stretchLength = distanceFromTarget!
            //self.angleLength = 180-abs((angular_error!-180).truncatingRemainder(dividingBy: 180))
        }
        if message != "" {
            self.lastText = message
            self.playGoalReachedSound(description: "1")
            self.timeLastDing = NSDate().timeIntervalSince1970
            
            var instruction:String = ""
            
            instruction = message.contains("turn") ? "\(message) \(direction!)" : message
            instruction = message.contains("turn") && abs(self.angleLength ?? 0) >= 160 ? "\(message) around" : instruction
            instruction = changePath ? "Rerouting, \(instruction)" : instruction
            
            if previous_state == "outside" && state == "inside"{
                instruction = "Inside, \(instruction)"
            } else if previous_state == "inside" && state == "outside"{
                instruction = "Outside, \(instruction)"
                self.emergencySound()
            }
            
            debugConditions = "\(condition1 ? "t":"f")\(condition2 ? "t":"f")\(condition3 ? "t":"f")\(condition4 ? "t":"f")"
            
            timerRepeatInstruction = CFAbsoluteTimeGetCurrent()
            
            let utterance = AVSpeechUtterance(string: instruction)
            utterance.rate = 0.5
            utterance.pitchMultiplier = 0.8
            utterance.postUtteranceDelay = 0
            utterance.preUtteranceDelay = 0
            utterance.voice = self.voice
            self.speech_synthesizer.speak(utterance)
        }
        previous_direction = direction ?? ""
        previous_state = state
        //print("EVALUATION")
        print()
    }
    
    // NO OK
    private func sonificate(message: String, angular_difference: Float? = nil, distanceFromTurn: Float? = nil, safeAreaRadius: Float? = nil, state: String) {
        /*guard !beeping else { // when is beeeping don't play nothing // TODO: CHECK THIS
            print("Beeping")
            return
        }*/
        if message == self.lastText && (message.contains("turn")  || message.contains("turn")) && angleLength != nil { // if the instruction doesn't change you must ticking base on the angular error.
            let rotation : Float = abs(angular_difference!)//180-abs((angular_difference!-180).truncatingRemainder(dividingBy: 180))
            // if angular error is major than the initial angular error movement required, you must play a default frequency of 1 Hz, else the ticking rate must base on the angular error until 15 Hz (15 Hz to avoid wave definition earable).
            //print("angleLength",self.angleLength, "rotation",rotation)
            if rotation > self.angleLength! {
                self.startTicking(rate: 1)
            } else {
                let duration = 1 + 14 * pow(1-min(abs(rotation/self.angleLength!),1),4)
                //print("duration change turn", duration) // DEBUG
                self.startTicking(rate: duration)
            }
            
            if rotation < Level3().alpha1 {
                self.startSonification=false
                Synth.shared.audioEngine.stop()
            }
            /*switch selectedSonification{
                case 1:
                    if normRotation > self.angleLength! {
                        self.startTicking(duration: 1)
                    }else{
//                        let duration : Double = 1.065-Double(pow(1-min(abs(normRotation/self.angleLength!),1),4))
//                        self.startTicking(duration: duration)
                        let duration = 1 + 14 * pow(1-min(abs(normRotation/self.angleLength!),1),4)
                        self.startTicking(duration: duration)
                    }
                default:
                    break
            }*/
        }else if message.contains("walk") && self.lastText.contains("walk") && stretchLength != nil { // if the user is walking, change the sonification rate base on distance to the target.
            //print(distanceFromTurn!, self.stretchLength!) // DEBUG
            let duration = 1+14*pow(1-min(abs((distanceFromTurn!/self.stretchLength!)),1),4)
            //print("duration change walk", duration)
            self.startTicking(rate: duration)
            //print(duration)
            
            if (distanceFromTurn ?? 0) < (safeAreaRadius ?? 0) && state != "outside" {
                self.startSonification=false
                Synth.shared.audioEngine.stop()
            }
            
            /*switch selectedSonification{
                case 1:
                    let duration = 1+14*pow(1-min(abs((distanceFromTurn!/stretchLength!)),1),4)
                    self.startTicking(duration: duration)
                default:
                    break
            }*/
        }
        //return text
    }
    
    // OK!
    private func startTicking(rate: Float){
        if self.speech_synthesizer.isSpeaking && Synth.shared.volume != 0{
            Synth.shared.volume = 0
        } else if !self.speech_synthesizer.isSpeaking && Synth.shared.volume == 0{
            Synth.shared.volume = 0.8
        }

        let frequency = Float(round(1000*rate)/1000)
        
        //print("tick", rate, "Hz", frequency, "volume", Synth.shared.volume)
        
        if Synth.shared.frequency != frequency {
            print("tick", rate, "Hz", "volume", Synth.shared.volume)
            Synth.shared.frequency = frequency
        }
    }
    
    func playGoalReachedSound(description: String? = nil){
        dingPlayer.play()
    }
    
    // earcon per indicare che è cambiato il nodo durante una svolta e quindi avviso l'utente dell'avvenuto cambio
    func playUpdateTargetAngleSound(description: String? = nil){
        updateTargetAnglePlayer.play()
    }
    
    func jumpSound(description: String? = nil){
        jumpPlayer.play()
    }
    
    func emergencySound(description: String? = nil){
        emergencyPlayer.play()
    }
    
    func feedback(_ message: String){
        let utterance = AVSpeechUtterance(string: message )
        utterance.rate = 0.5
        utterance.pitchMultiplier = 0.8
        utterance.postUtteranceDelay = 0
        utterance.preUtteranceDelay = 0
        utterance.voice = self.voice
        self.speech_synthesizer.speak(utterance)
    }
}
