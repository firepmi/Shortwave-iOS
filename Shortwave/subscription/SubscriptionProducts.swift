//
//  SubscriptionProducts.swift
//  Locally
//
//  Created by Mobile World on 6/11/19.
//  Copyright © 2019 TheLastSummer. All rights reserved.
//

import Foundation

public struct SubscriptionProducts {
    public static let subscriptionID = "ansable_subscription"
    private static let productIdentifiers: Set<ProductIdentifier> = [subscriptionID]
    
    public static let store = IAPHelper(productIds: productIdentifiers)
}
