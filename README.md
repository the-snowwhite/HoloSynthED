# HoloSynthED

Status 13/8-2016

I finally managed to backport the knowlege gained from the Mksocproject work back to this multiple yeared dx-7 style synthesier development / studying / learning project that created the whole backgroung making me able to pull of the transformation process of the Xilinx based mesa project into the Altera camp and then reincluding the main competitioner again.

After handing off that next step was the revalal of The Holosynth which, has been parked in many bits and pieces for an consirable amount of time. (while I myself was mostly out of order, broadly ).

Very much to my suprise the pieces I managed to get parked are in very good shape solid and in working order.

Only needed to put in the generic uio driver stuff in the hardware HolosynthV project, and add the qt gui to the scripts.

ssh -X 'ing into holosynth works prefektly.

However I have not been able to get the framebuffer for the 10 - 15" led touch screens I have from Chalk Elec to get out of power down mode with the 4.1+ kernel or find out how and where to ask how to get it to function, as long as the project still seems invisible or uninterresting seen from the outside.

I expect the next steps will involve be getting the framebuffer to work + the other dev kit projects up (Sockit, Cyclone V devkit, de0-nano, perhaps).

Pulling the recent changes into master with understandable commits. Making demos, more sound patches, document how to rescale the compilation (num voices, oscilators, envelope gens via changing the built in parameters).

If you find this interresting be so kind as to donate it into this pool by sharing in actively.
