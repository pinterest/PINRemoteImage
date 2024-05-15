//
//  ContentView.swift
//  PINCache-SPM-Integration
//
//  Created by Petro Rovenskyy on 19.11.2020.
//

import SwiftUI
import PINCache

struct ContentView: View {
    let cacheKey: String
    @State
    private var cachedValue: String = "loading..."
    var body: some View {
        Text(cachedValue)
            .onAppear(perform: loadValue)
            .padding()
    }
    private func loadValue() {
        PINCache.shared.object(forKeyAsync: self.cacheKey, completion: { (_, _, object) in
            if let object: String = object as? String {
                self.cachedValue = object
                return
            }
            self.cachedValue = "Failed to load value from cache"
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(cacheKey: AppDelegate.cacheKey)
    }
}
