This repository contains stuff I've been working on that is DOS-related
in a way (more like DOS-era, as some content is BIOS-related). I will be
adding more stuff from time to time, but in the meantime here is a brief
description of the contents:

1. park: A small utility to park the heads of your hard drive. Parking
   the heads is moving them outside of the data area so when the computer
   is turned off, they don't damage any data. This is not needed by most
   hard drives, dating even to the mid-80s. However, it is a must for the
   older ones such as the Seagate ST-412, which came originally with the
   IBM PC XT. Most drives around that time required parking the heads
   before powering off to avoid damaging data. This program will take
   care of it, provided that you run it before powering off.
2. wdbios: Reverse-engineered BIOS for the WD1002-WX1, a very old MFM,
   XT-class, hard drive controller. It's equivalent to the Super-BIOS
   v2.4, so dynamic geometry support is present.
