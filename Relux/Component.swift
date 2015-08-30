//
//  Component.swift
//  Relux
//
//  Created by 林達也 on 2015/08/11.
//  Copyright © 2015年 jp.sora0077. All rights reserved.
//

import Foundation

public protocol Component: class {
    
    func render() -> Any
}
