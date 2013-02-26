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

#ifndef CBPAYPALBILLITEM_H_
#define CBPAYPALBILLITEM_H_

/**
 * this object represents a single item within a CBPayPalBill object.
 */
@interface CBPayPalBillItem : NSObject

/**
 * The name of the item for the transaction
 */
@property (nonatomic, retain) NSString* name;
/**
 * An extended description of the item. This should also contain the amount as
 * PayPal does not always display it.
 */
@property (nonatomic, retain) NSString* description;
/**
 * The amount of the transaction
 */
@property (nonatomic, retain) NSNumber* amount;
/**
 * additional taxes to be added to the amount
 */
@property (nonatomic, retain) NSNumber* tax;
/**
 * a quantity representing the number of items involved in the transaction.
 * for example 100 poker chips
 */
@property (nonatomic, retain) NSNumber* quantity;

@end

#endif