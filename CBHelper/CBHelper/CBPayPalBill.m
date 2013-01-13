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

#import "CBPayPalBill.h"

@implementation CBPayPalBill

@synthesize name, description, invoiceNumber, items, currency, paymentCompletedFunction, paymentCancelledFunction, paymentCompletedUrl, paymentCancelledUrl;

- (void) addNewItem:(CBPayPalBillItem*)newItem {
    if (self.items == NULL)
        self.items = [[NSMutableArray alloc] init];
    
    [self.items addObject:newItem];
}

- (NSMutableDictionary*) serializePurchase {
    // first check that we have bill items
    if (self.items == NULL || [self.items count] == 0) {
        return NULL;
    }

    // calculate the total amount for the bill by looping over the items
    // and generate the detail items array
    double amount = 0.0f;
    NSMutableArray* itemsArray = [[NSMutableArray alloc] init];

    for (CBPayPalBillItem* curItem in self.items) {
        amount += curItem.amount.doubleValue + (curItem.tax == NULL?0:curItem.tax.doubleValue);
        NSMutableDictionary* itemDict = [[NSMutableDictionary alloc] init];
        [itemDict setObject:curItem.name forKey:@"item_name"];
        [itemDict setObject:curItem.description forKey:@"item_description"];
        [itemDict setObject:curItem.amount.stringValue forKey:@"item_amount"];
        [itemDict setObject:curItem.tax.stringValue forKey:@"item_tax"];
        [itemDict setObject:curItem.quantity forKey:@"item_quantity"];
        
        [itemsArray addObject:itemDict];
    }

    NSMutableDictionary* output = [[NSMutableDictionary alloc] init];
    
    [output setObject:self.name forKey:@"name"];
    [output setObject:self.description forKey:@"description"];
    [output setObject:[NSNumber numberWithDouble:amount].stringValue forKey:@"amount"];
    [output setObject:self.invoiceNumber forKey:@"invoice_number"];
    [output setObject:itemsArray forKey:@"items"];

    return output;
}

@end
