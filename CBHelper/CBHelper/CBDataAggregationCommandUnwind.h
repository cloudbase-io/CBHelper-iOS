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

#import "CBDataAggregationCommand.h"

/**
 * Unwinds an array from a field inside a document by multiplying
 * the document in the result set. For example consider the document:
 * {
 *   "firstName" : "Cloud",
 *   "lastName"  : "Base",
 *   "books"     : [ "100 Years of Solitude", "Love in the Time of Cholera", "Memoirs of My Melancholy Whores" ]
 * }
 * calling the Unwind command on the books field would result in three separate
 * documents being returned by the search:
 * { "firstName" : "Cloud", "lastName" : "Base", "books" : "100 Years of Solitude" }
 * { "firstName" : "Cloud", "lastName" : "Base", "books" : "Love in the Time of Cholera" }
 * ...
 */
@interface CBDataAggregationCommandUnwind : CBDataAggregationCommand <NSCoding>

/**
 * The name of the array field to be unwound
 */
@property (nonatomic, retain) NSString *fieldName;

@end
