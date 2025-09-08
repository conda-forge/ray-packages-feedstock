echo on
set SKIP_THIRDPARTY_INSTALL_CONDA_FORGE=1
set IS_AUTOMATED_BUILD=1
set "BAZEL_SH=%BUILD_PREFIX%\Library\usr\bin\bash.exe"

mkdir thirdparty\systemlibs
robocopy /E %RECIPE_DIR%\systemlibs thirdparty\systemlibs

echo ==========================================================
echo try to work around https://github.com/bazelbuild/bazel/issues/18592
echo ==========================================================
set BAZEL_VC=C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC
rmdir /q /s "%BAZEL_VC%\vcpkg"

echo ==========================================================
echo calling pip to install
echo ==========================================================
cd python
echo startup --output_user_root=D:/tmp >> ..\.bazelrc
rem echo build --subcommands=pretty_print >> ..\.bazelrc
"%PYTHON%" -m pip install . -vv --no-deps --no-build-isolation

rem remember the return code
set RETCODE=%ERRORLEVEL%

rem setup.py uses D:\bazel-root and D:\b-o since ray 2.10.0.
rem Get the drive for SRC_DIR, in case it changes from D:
@for %%G in  ("%SRC_DIR%") DO @SET DRIVE=%%~dG
rem Now shut down Bazel server, otherwise Windows would not allow moving a directory with it
bazel "--output_user_root=%DRIVE%\bazel-root" "--output_base=%DRIVE%\b-o" clean
bazel "--output_user_root=%DRIVE%\bazel-root" "--output_base=%DRIVE%\b-o" shutdown
rd /s /q "%DRIVE%\..\b-o" "%DRIVE%\..\bazel-root"
rem Ignore "bazel shutdown" errors
exit /b %RETCODE%
