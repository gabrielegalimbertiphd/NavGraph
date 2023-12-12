//
//  AudioController.swift
//  STTN
//
//  Created by OS Programming on 07/06/23.
//

import Foundation
import AVFoundation

class Level4 {
    
    private var dingPlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "ShortDing", ofType: "mp3")!))
    
    private var updateTargetAnglePlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "earcon", ofType: "wav")!))
    private var jumpPlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "repositioning", ofType: "wav")!))
    private var emergencyPlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "emergency", ofType: "wav")!))
    
    private let voice = AVSpeechSynthesisVoice(language: "it-IT")!//"it-IT")!
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
    
    public var other10meters:Bool = false
    
    public var previous_direction_turn:String = ""
    public var previous_state:String = ""
    
    public var timerRepeatInstruction: Double = 0.0
    public var t:Double = 0.0
    
    public var debugConditions = ""
    
    public var ttsspeed : Float = 0.5
    
    public var readInstruction : Bool = false
    
    public var num_turn : Int = 0
    public var num_walk : Int = 0
    public var num_lateral : Int = 0
    
    public var sonif_rate : Float = 0.0
    
    // se è già stato comunicato il messaggio e ha già finito di parlare dopo 1.2 secondi. altrimenti sonifico
    func speak(message: String, angular_difference: Float? = nil, range: Float = 30.0, distanceFromTarget: Float? = nil, safeAreaRadius: Float? = nil, lateralDistance:Float? = nil, direction_turn: String? = nil, direction_lateral: String? = nil, movement : Float? = nil, state: String, changeNode: Bool, changePath:Bool, repeatInstructionFlag:Bool) {
        readInstruction = false
        t = CFAbsoluteTimeGetCurrent() - timerRepeatInstruction
        // se si verifica una di queste condizioni allora non usare la sonificazione e devi dire il messaggio:
        // 1- se il messaggio cambia serve che dico il nuovo messaggio. se sto svoltando/camminando voglio continuare eccetto in casi particolari trattati in seguito.
        let condition1 = self.lastText != message
        // 2- se cambia la direzione, sto svoltando e la sonificazione è stata attivata e non è maggiore di 160 gradi
        //let condition2 = (previous_direction_turn != direction_turn && message.contains("turn") && startSonification && abs(angular_difference ?? 0) >= range && abs(self.angleLength ?? 0) < 160)
        // abs(self.angleLength ?? 0) < 160) da tenere perchè evita che nell'alternanza tra 180 e -180 venga ripetuto "turn around"
        let condition2 = false //(previous_direction_turn != direction_turn && message.contains("turn") && startSonification && abs(self.angleLength ?? 0) < 160) // condizione per identificare il cambio di direzione.
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
        // TURN AROUND CONDITION
        let condition7 = false //(message.contains("turn") && startSonification && abs(self.angleLength ?? 0) < 160) && abs(angular_difference ?? 0 )>=160 // condizione per dire "girati indietro"
        // cambio del percorso
        var condition8 = false // changePath TODO just in case we use a different method
        
        //var condition9 = self.angleLength != nil && (angular_difference ?? 30)-(self.angleLength ?? 0) > 30 && angular_difference ?? 30 < 145 // ripeto solo se sono a 160-30/2 ... se no c'è rischio che venga ripetuta una istruzione di svolta e subito dopo una istruzione di voltati indietro.
        
        guard condition1 || condition2 || condition3 || condition4 || condition5 || condition6 || condition7 || condition8  else {
            // TODO: Level3().alpha3 non sarebbe corretto
            if !startSonification{ // set angle and distance required again after wait 1.2s
                
                if message.contains("walk") { // when set the new angle or distance set volume to 0
                    self.stretchLength = distanceFromTarget!
                } else if message.contains("turn") {
                    self.angleLength = abs(angular_difference!)
                } else if message.contains("lateral") { // when set the new angle or distance set volume to 0
                    self.stretchLength = lateralDistance!
                }
                Synth.shared.volume = 0
            } else { // after setting the new angle or distance set volume to 0.8
                Synth.shared.volume = 0.8
            }
            
            if startSonification && (angular_difference != nil || distanceFromTarget != nil) {
                
                // cambio angolo target e riproduco earcon che indica update della svolte se: cambia il nodo, sto ruotando, il volume non è a zero, il mio stato è inside, angolo è maggiore di alpha3 // e la distanza dal prossimo target è maggiore del raggio della safe area.
                // IN CASO STIA RUOTANDO ED HA LA STESSA ISTRUZIONE DI ROTAZIONE
                if changeNode && message.contains("turn") && Synth.shared.volume != 0 && state == "inside" { //&& angular_difference ?? range >= range {
                    Synth.shared.volume = 0
                    //self.angleLength = abs(angular_difference!)
                    self.startSonification=false // permette di cambiare l'angolo target perchè lo imposto a riga 70!!!!
                    playUpdateTargetAngleSound()
                    print(changeNode, message, angular_difference, distanceFromTarget, lateralDistance)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){ // Per 0.2 secondi non sonifico.
                        //Synth.shared.volume = 0.8
                        self.startSonification=true
                    }
                }
                
                // Notifica che mancano %10 metri alla prossima svolta
                /*if message.contains("walk") && Synth.shared.volume != 0 && Int(distanceFromTarget!) <= 10 && self.stretchLength ?? 0 >= 15 && self.other10meters {
                    Synth.shared.volume = 0
                    self.startSonification=false
                    self.other10meters = false
                    feedback("next turn after \(Int(distanceFromTarget!)+1) meters")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){ // Per 0.2 secondi non sonifico.
                        //Synth.shared.volume = 0.8
                        self.startSonification=true
                    }
                }*/
                
                self.sonificate(message: message, angular_difference: angular_difference!, distanceFromTurn: distanceFromTarget!, lateralDistance: lateralDistance!, safeAreaRadius: safeAreaRadius!, state: state)
                print("self.sonificate finished")
                print()
            }
            
            if message.contains("destination reached") || state == "Arrived" || message.contains("update"){
                let utterance = AVSpeechUtterance(string:message)
                self.startSonification=false
                Synth.shared.audioEngine.stop()
                utterance.rate = ttsspeed
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
        } else if message.contains("lateral") { // if the instruction is turn, set the angular difference with respect to the target
            self.angleLength = nil
            self.stretchLength = lateralDistance!
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {//+ 1.2){
                self.startSonification=true
                do {
                    try Synth.shared.audioEngine.start()
                    if message.contains("turn"){
                        Synth.shared.setWaveformTo(Oscillator.square)
                    } else if message.contains("walk"){
                        Synth.shared.setWaveformTo(Oscillator.IS_Walk)
                    } else if message.contains("lateral"){
                        Synth.shared.setWaveformTo(Oscillator.IS_Lateral)
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
            
            // IN CASO CAMBIA NODO TARGET
            /*if changeNode==true && changePath != true && state == "inside" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4){ // Per 0.4 secondi non sonifico.
                    self.playUpdateTargetAngleSound()
                }
            }*/
            
            self.other10meters = true
            
            if message.contains("turn"){
                num_turn=num_turn+1
            } else if message.contains("walk"){
                num_walk=num_walk+1
            } else if message.contains("lateral"){
                num_lateral=num_lateral+1
            }
            
            var instruction:String = ""
            
            // WALK INSTRUCTION
            //instruction = message.contains("walk") ? "walk" : ""
            if message.contains("walk") {
                instruction = distanceFromTarget ?? 1<2 ? "Prosegui dritto per circa un metro":"Prosegui dritto per \(Int(distanceFromTarget ?? 1)) metri"
            }
            // LATERAL STRIDE INSTRUCTION
            //instruction = message.contains("lateral") ? "lateral" : ""
            else if message.contains("lateral"){
                if direction_lateral! == "Left"{
                    instruction = "Spostati a sinistra"
                } else if direction_lateral! == "Right"{ // era "right"
                    instruction = "Spostati a destra"
                }
                print("QUI")
            }
            // TURN AROUND INSTRUCTION + TURN INSTRUCTION
            //instruction = message.contains("turn") && abs(self.angleLength ?? 0) >= 160 ? "\(message) around" : instruction
            else if message.contains("turn")  {
                var direzione : String = direction_turn!=="Left" ? "sinistra" : "destra"
                instruction = message.contains("turn") ? "Gira a \(direzione)" : ""
                //instruction = message.contains("turn") && abs(self.angleLength ?? 0) >= 160 ? "Girati indietro" : instruction // era Girati
            }
            //instruction = changePath ? "Rerouting, \(instruction)" : instruction // TODO decide if use or not "Rerouting"
            // ANY OTHER INSTRUCTION
            else if message.contains("walk")==false && message.contains("lateral")==false &&  message.contains("turn")==false {
                instruction=message
                print("QUI")
            }
            
            if previous_state == "outside" && state == "inside"{
                // TODO decide if use or not "inside"
                //instruction = "Inside, \(instruction)"
            } else if previous_state == "inside" && state == "outside"{
                // TODO decide if use or not "outside"
                //instruction = "Outside, \(instruction)"
                self.emergencySound()
            }
            
            debugConditions = "\(condition1 ? "t":"f")\(condition2 ? "t":"f")\(condition3 ? "t":"f")\(condition4 ? "t":"f")"
            
            timerRepeatInstruction = CFAbsoluteTimeGetCurrent()
            
            readInstruction = true
            
            let utterance = AVSpeechUtterance(string: instruction)
            utterance.rate = ttsspeed
            utterance.pitchMultiplier = 0.8
            utterance.postUtteranceDelay = 0
            utterance.preUtteranceDelay = 0
            utterance.voice = self.voice
            self.speech_synthesizer.speak(utterance)
        }
        previous_direction_turn = direction_turn ?? ""
        previous_state = state
        //print("EVALUATION")
        print()
    }
    
    // NO OK
    private func sonificate(message: String, angular_difference: Float? = nil, distanceFromTurn: Float? = nil, lateralDistance: Float? = nil, safeAreaRadius: Float? = nil, state: String) {
        /*guard !beeping else { // when is beeeping don't play nothing // TODO: CHECK THIS
            print("Beeping")
            return
        }*/
        if message == self.lastText && (message.contains("turn")) && angleLength != nil { // if the instruction doesn't change you must ticking base on the angular error.
            let rotation : Float = abs(angular_difference!)//180-abs((angular_difference!-180).truncatingRemainder(dividingBy: 180))
            // if angular error is major than the initial angular error movement required, you must play a default frequency of 1 Hz, else the ticking rate must base on the angular error until 15 Hz (15 Hz to avoid wave definition earable).
            //print("angleLength",self.angleLength, "rotation",rotation)
            if rotation > self.angleLength! {
                
                let duration = 1 * (abs(self.angleLength!/rotation))
                self.startTicking(rate: duration)
//                self.startTicking(rate: 1)
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
            if distanceFromTurn! < self.stretchLength!{
                let duration = 1+14*pow(1-min(abs((distanceFromTurn!/self.stretchLength!)),1),4)
                //print("duration change walk", duration)
                self.startTicking(rate: duration)
                //print(duration)
            }
            else {
                let duration = 1 * (abs(self.stretchLength!/distanceFromTurn!))
                self.startTicking(rate: duration)
            }
            
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
        } else if message.contains("lateral") && self.lastText.contains("lateral") && stretchLength != nil { // if the user is walking, change the sonification rate base on distance to the target.
            //print(distanceFromTurn!, self.stretchLength!) // DEBUG
            if lateralDistance! < self.stretchLength!{
                let duration = 1+14*pow(1-min(abs((lateralDistance!/self.stretchLength!)),1),4)
                //print("duration change walk", duration)
                self.startTicking(rate: duration)
                //print(duration)
            }
            else {
                let duration = 1 * (abs(self.stretchLength!/lateralDistance!))
                self.startTicking(rate: duration)
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
        
        sonif_rate = frequency
        //print("tick", rate, "Hz", frequency, "volume", Synth.shared.volume)
        
        if Synth.shared.frequency != frequency {
            print("tick", rate, "Hz", "volume", Synth.shared.volume)
            Synth.shared.frequency = frequency
        }
    }
    
    /*
     private func playNote(sector: Int){
//        guard !self.synthesizer.isSpeaking else {return}
        guard 0...6 ~= sector && sector != self.lastAngleSector else { return }
        self.lastAngleSector = sector
        notePlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: self.sectorNote(sector), ofType: "wav")!))
        notePlayer.play()
    }
    
    private func sectorNote(_ sector: Int) -> String{
        switch sector {
            case 0: return "C4"
            case 1: return "D4"
            case 2: return "E4"
            case 3: return "F4"
            case 4: return "G4"
            case 5: return "A4"
            default: return "B4"
        }
    }
    
    func say(_ text: String, important: Bool = false){
        guard ((lastThingSaid != text || NSDate().timeIntervalSince1970 - self.timeLastThingSaid > 7) && NSDate().timeIntervalSince1970 - self.timeLastDing > 7) || important else {return}
        
        if important {
            self.synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = ttsspeed
        utterance.pitchMultiplier = 0.8
        utterance.postUtteranceDelay = 0
        utterance.preUtteranceDelay = 0
        //utterance.voice = self.voice
        speech_synthesizer.speak(utterance)
        
        self.timeLastThingSaid = NSDate().timeIntervalSince1970
        self.lastThingSaid = text
    }
     */
    
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
        print("dovrei parlare 2")
        let utterance = AVSpeechUtterance(string: message )
        utterance.rate = ttsspeed
        utterance.pitchMultiplier = 0.8
        utterance.postUtteranceDelay = 0
        utterance.preUtteranceDelay = 0
        utterance.voice = self.voice
        self.speech_synthesizer.speak(utterance)
    }
}
