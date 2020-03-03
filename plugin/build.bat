rem WINDOWS PLUGIN
rem use Microsoft Visual Studio (Community) or other native compiler for brainwin.plugin instead of mingw (cygwin) 
rem mingw produces slower multi-threading code for windows platforms and requires additional dlls
rem if you still have to use mingw, you have to add follwing files to plugin folder:
rem libgomp-1.dll, libwinpthread-1.dll, libgcc_s_seh-1.dll (search in cygwin installation)
rem x86_64-w64-mingw32-gcc -Wall -shared -fPIC -fopenmp -DSYSTEM=STWIN64 brain.c stata.c stplugin.c -o brainwin.plugin

gcc -shared -fopenmp -DSYSTEM=OPUNIX brain.c stata.c stplugin.c -o brainunix.plugin
gcc -shared -fopenmp -DSYSTEM=APPLEMAC brain.c stata.c stplugin.c -o brainmac.plugin