Copyright (C) 2012 cloudbase.io
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

CBHelper-iOS
============

The cloudbase.io iOS helper class

The project contains an XCode workspace with two projects:
- CBHelper - The actual cloudbase.io helper class which compiles to a .a library
- CBHelperTestApp - The demo application. This project is linked to the CBHelper library

To be able to execute the CBHelperTestApp demo application make sure that the "Other Linker Flags"
for the CBHelperTestApp target include the following two options:
* -ObjC
* -all_load

This will allow the linker to load the header files from the CBHelper project when building
the demo application