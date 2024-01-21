echo on
set SKIP_THIRDPARTY_INSTALL=1
set IS_AUTOMATED_BUILD=1
set "BAZEL_SH=%BUILD_PREFIX%\Library\usr\bin\bash.exe"

echo ==========================================================
echo try to work around https://github.com/bazelbuild/bazel/issues/18592
echo ==========================================================
set BAZEL_VC=C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC
echo dir %BAZEL_VC%
dir "%BAZEL_VC%"
rmdir /q /s "%BAZEL_VC%\vcpkg"
echo dir %BAZEL_VC%
dir "%BAZEL_VC%"

echo ==========================================================
echo calling pip to install
echo ==========================================================
cd python
rem This requires patch 0006
echo startup --output_user_root=D:/tmp >> ..\.bazelrc
"%PYTHON%" -m pip install . -vv

rem remember the return code
set RETCODE=%ERRORLEVEL%

rem Now clean everything up so subsequent builds (for potentially
rem different Python version) do not stumble on some after-effects.
"%PYTHON%" setup.py clean --all

rem Now shut down Bazel server, otherwise Windows would not allow moving a directory with it
rem bazel "--output_user_root=%SRC_DIR%\..\bazel-root" "--output_base=%SRC_DIR%\..\b-o" clean
bazel  clean
rem bazel "--output_user_root=%SRC_DIR%\..\bazel-root" "--output_base=%SRC_DIR%\..\b-o" shutdown
bazel shutdown
rd /s /q "%SRC_DIR%\..\b-o" "%SRC_DIR%\..\bazel-root"
rem Ignore "bazel shutdown" errors
exit /b %RETCODE%
