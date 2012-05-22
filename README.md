ATPagingMod
===========

I have a strange jump in the ATPagingView while rotating in a node of the last row. The module handles nicely view loading in the manner of UITableView for an UIScrollview. I modified it to be able to scroll vertically while each row is again an ATPagingView, which scrolls horizontally and while not in the first branch prevents to scroll in the vertical direction. So far everything works fine, but if you are on the last row the

currentPageIndex
is set wrong and I can't identify the place where it happens.

I really would appreciate any help.

To reproduce the bug: go to node 9.x where x > 0 and change the interface orientation and you will see any other page but 9.x