//
//  NightmareStatus.swift
//  WilliDreams
//
//  Created by William Gallegos on 7/26/24.
//

enum DreamScale {
    case great
    case good
    case ok
    case bad
    case nightmare
}

func getDreamStatus(dreamScale: Double) -> DreamScale {
    if dreamScale >= 0.9 {
        return .great
    } else if dreamScale >= 0.6 {
        return .good
    } else if dreamScale >= 0.4 {
        return .ok
    } else if dreamScale >= 0.2 {
        return .bad
    } else {
        return .nightmare
    }
}
