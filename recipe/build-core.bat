cd python
set SKIP_THIRDPARTY_INSTALL=1
set IS_AUTOMATED_BUILD=1
set "BAZEL_SH=%BUILD_PREFIX%\Library\usr\bin\bash.exe"

echo ==========================================================
echo calling pip install
echo ==========================================================

"%PYTHON%" -m pip install . -vv
rem remember the return code
set RETCODE=%ERRORLEVEL%

rem Now clean everything up so subsequent builds (for potentially
rem different Python version) do not stumble on some after-effects.
"%PYTHON%" setup.py clean --all

rem Now shut down Bazel server, otherwise Windows would not allow moving a directory with it
bazel "--output_user_root=%SRC_DIR%\..\bazel-root" "--output_base=%SRC_DIR%\..\b-o" clean
bazel "--output_user_root=%SRC_DIR%\..\bazel-root" "--output_base=%SRC_DIR%\..\b-o" shutdown
rd /s /q "%SRC_DIR%\..\b-o" "%SRC_DIR%\..\bazel-root"
rem Ignore "bazel shutdown" errors
exit /b %RETCODE%
