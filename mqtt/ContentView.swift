//
//  ContentView.swift
//  mqtt
//
//  Created by Kevin Walchko on 12/5/21.
//

import SwiftUI
import MQTTNIO


// https://www.swiftbysundell.com/articles/the-main-actor-attribute/
// this keeps it in main thread
@MainActor
class ViewModel: ObservableObject {
    @Published var msg: String = ""
    let client: MQTTClient
    var timer: Timer = Timer()
    
    init(_ host: String, port: Int=1883) {
        self.client = MQTTClient(
            configuration: .init(
                target: .host(host, port: port)
            ),
            eventLoopGroupProvider: .createNew
        )
        self.client.connect()
        self.client.subscribe(to: "test")
        
        self.client.whenMessage(forTopic: "test") { message in
            // this keeps it in main thread ... otherwise you have to
            // disbatch to main thread. Task is from async
            Task {
                if message.payload.string == nil {
                    return
                }
                let m = message.payload.string!
                print(m)
                self.msg = m
            }
        }
        
        self.timer = Timer.scheduledTimer(
            withTimeInterval: 0.01,
            repeats: true,
            block: { _ in
                self.update()
            })
        
    }
    
    var cnt: Int = 0
    func update(){
        self.client.publish("Hello World! \(self.cnt)", to: "test", qos: .exactlyOnce)
        self.cnt += 1
    }
}

struct ContentView: View {
    @ObservedObject var vm = ViewModel("10.0.1.199", port: 1883)
    
    var body: some View {
        ZStack {
//            Color.black.edgesIgnoringSafeArea(.all)
            Text(self.vm.msg)
                .padding()
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(Color.teal)
        }
        .preferredColorScheme(.dark)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
