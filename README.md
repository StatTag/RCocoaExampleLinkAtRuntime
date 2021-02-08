# RCocoaExampleLinkAtRuntime
Example of linking to RCocoa and R

# To run

* Clone repository
* As a peer folder, clone the "HeaderChange" branch of [RCocoa](https://github.com/StatTag/RCocoa/tree/HeaderChange). 

# Changes to RCocoa

This branch has a few alterations
  - References to R framework removed from headers and placed in .m files 
      - We can avoid having to allow non-modular includes
      - We no longer have to link to R in external applications or frameworks (no more double-linking)
  - Slight modifications to REngine initialization to semi-gracefully break when we can't find R. RCocoa now returns a nil Engine if R cannot be found. This should be changed to support NSError and fail-able initializers so we know what happened.
  - RCocoa now tries to tell you which version of R it is running against
  
  

