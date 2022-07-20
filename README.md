# FM-PLUGIN-TOOLS - A toolkit for FileMaker plug-in development in Common Lisp

Sample code for defining a plugin function:

```
(define-plugin-function "Add( number1; number2 )"
    ((number1 :float) (number2 :float))
  "Adds two numbers - same as + operator in FM"
  (+ number1 number2))

```

Sample code for defining a plugin script step with UI (New to FileMaker Pro 16):

```
(define-plugin-script-step "Convert To Base"
    ((nil    :text    (:type :target) (:label "Destination") (:inline t))
     (number :integer (:type :calc) (:inline t) (:label "Number"))
     (fake-p :boolean (:type :bool) (:label "Fake") (:default nil))
     (base   :integer (:type :list) (:inline t) (:label "Base") (:default 16)
                      (:contents ((2  "Binary")
                                  (3  "Ternary")
                                  (8  "Octal")
                                  (12 "Duodecimal")
                                  (16 "Hexadecimal")))))
  "Converts the number into a string using the specified base"
  (if fake-p "FAKE VALUE" ; for test purposes only
    (if (< 0 base)
        (let ((format-string (format nil "~~~DR" base)))
          (format nil format-string number))
      "BAD BASE VALUE")))
```

To use FM-PLUGIN-TOOLS you will need the Common Lisp implementation from LispWorks and of course FileMaker Pro (Advanced). You won't need a C or C++ compiler on Windows, though! (On OS X you will need Apple's Xcode which comes for free with every Mac.)

## Preparing `fli.lisp`

### Download the SDK Headers

The needed FileMaker SDK headers (`fm_plugin_sdk_ver.zip`) can be
downloaded from
[FileMaker Plug-in Support](https://www.claris.com/resources/downloads/). (The
plugin headers from latest SDK headers should also work for old versions of FileMaker Pro
and FileMaker Pro Advanced.)

### Further processing of SDK Headers

Please do this on the same platform when you are building your FMP plugins:

1. Open a terminal window and go to the directory `PlugInSDK/Headers/FMWrapper`.
2. Execute `for i in *.h; do grep -v "#include" $i > ${i}h; done`.
3. Execute `for i in *.hh; do gcc -std=c++17 -E $i > ${i}h; done`.

NOTE: on Windows, the above 2nd command must be `for %i in (*.hh) do cl /E %i > "%i"h` where Microsoft Compiler is used. (GCC doesn't work because FileMaker Pro is not compiled by GCC on Windows.)

NOTE: `-std=c++17` is required for processing SDK Headers version 19 (version 0.3.1+ is required).

At the end, 10 files like `FMXExtern.hhh` are generated and will be used by
the `prepare-fm-plugin-tools` package.

## Unified plug-in bundle format

The following notes come from SDK headers for FMP 18:

A unified plug-in bundle is now supported so that only one folder of items need to be distributed for the Mac, Win, and Linux platforms. The iOS bundles will still be independent since they cannot be installed by the FileMaker script step and instead are part of the iOS SDK build process. The bundle folder format matches the Mac plug-in bundle with the addition of a Windows and Linux folder inside the Resources folder. The format of the actual Windows or Linux dynamic libraries does not change, now you can just place the Windows .fmx and .fmx64 files into the Windows folder and the Linux .fmx file into Linux folder. The name (minus extension) of the dynamic library must match the name of the bundle folder (minus the extension). An example disk layout of a "fat" plug-in would look like:

```
FMMiniPlugIn.fmplugin
  Contents
    _CodeSignature
      CodeResources
    MacOS
      FMMiniPlugIn
    Resources
      Linux
        FMMiniPlugIn.fmx
      Windows
        FMMiniPlugIn.fmx
        FMMiniPlugIn.fmx64
    Info.plist
    PkgInfo
```

The reason the Linux and Windows folders are inside the Resources folder is due to how Mac bundles are signed by Xcode. Note that plug-ins are now required to be signed by their development environments and the bundle has to be signed after the non-Mac plug-ins are added to it. Currently only the Mac can import this bundle format into a container folder directly with the Insert File command. Insert from URL can be used on other platforms by creating a properly compressed Mac plug-in bundle via these two commands that come with the macOS:

```
  xar -cf MyCoolPlugin.fmplugin.xar MyCoolPlugin.fmplugin
  gzip -c MyCoolPlugin.fmplugin.xar > MyCoolPlugin.fmplugin.gz
```
