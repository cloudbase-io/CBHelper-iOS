/* Copyright (C) 2012 cloudbase.io
 
 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License, version 2, as published by
 the Free Software Foundation.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; see the file COPYING.  If not, write to the Free
 Software Foundation, 59 Temple Place - Suite 330, Boston, MA
 02111-1307, USA.
 */

#include <Foundation/Foundation.h>
#include "CBPayPalBillItem.h"

#ifndef CBPAYPALBILL_H_
#define CBPAYPALBILL_H_

/**
 * This is the bill object for the PayPal digital goods payments APIs. A bill object must contain
 * at least one BillItem.
 *
 * The description of the bill should also contain the total amount as PayPal does not always display
 * the amount in the checkout page.
 */
@interface CBPayPalBill : NSObject

/**
 * a name for the purchase
 */
@property (nonatomic, retain) NSString* name;
/**
 * a description of the bill item.
 * this should also contain the price for the bill as PayPal will not always display the amount field.
 */
@property (nonatomic, retain) NSString* description;
/**
 * this is a user generated unique identifier for the transaction.
 */
@property (nonatomic, retain) NSString* invoiceNumber;
/**
 * this is a list of BillItems. Each CBPayPalBill must have at least one BillItem
 */
@property (nonatomic, retain) NSMutableArray* items;
/**
 * The 3 letter ISO code for the transaction currency. If not specified this will automatically
 * be USD
 */
@property (nonatomic, retain) NSString* currency;
/**
 * This is the code of a CloudFunction to be executed once the payment is completed
 */
@property (nonatomic, retain) NSString* paymentCompletedFunction;
/**
 * This is the name of a CloudFunction to be executed if the payment is cancelled
 */
@property (nonatomic, retain) NSString* paymentCancelledFunction;
/**
 * By default the express checkout process will return to the cloudbase APIs. if you want to override 
 * this behaviour and return to a page you own once the payment is completed set this property to the url
 */
@property (nonatomic, retain) NSString* paymentCompletedUrl;
/**
 * By default the express checkout process will return to the cloudbase APIs. if you want to override
 * this behaviour and return to a page you own once the payment has been cancelled set this property to the url
 */
@property (nonatomic, retain) NSString* paymentCancelledUrl;

/**
 * This method is used internally to generate the NSMutableDictionary to be serialised
 * for the calls to the cloudbase.io APIs
 *
 * @return The Dictionary representation of the Bill object
 */
- (NSMutableDictionary*) serializePurchase;
/**
 * Adds a new item to this PayPalBill
 * 
 * @param newItem A populated CBPayPalBillItem object
 */
- (void) addNewItem:(CBPayPalBillItem*)newItem;

@end

#endif
