# 02

### Static file server

Monsoon can serve static files using the Static middleware.  
This example contains a public directory with an index.html file.  

#### Run

To run on `java`, `neko` or `node` simply run the corresponding hxml file with haxe.

To run the `cpp` version build it first (`haxe build_cpp.hxml`).  
An executable will be available in bin/cpp.   
Move the executable to this directory (so the server can find the public dir) and execute it.