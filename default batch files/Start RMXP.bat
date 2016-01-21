@echo off

REM ========================================================
REM        Written by Raku (rakudayo@gmail.com)
REM     Available for free use, commercial or otherwise
REM ========================================================

REM # The plugin system directory path relative to where this
REM # file resides (RMXP project root).
SET PLUGIN_SYSTEM_ROOT="../rmxp-plugin-system"

REM # The RMXP project root path relative to the plugin
REM # system's root.
SET RMXP_PROJECT_ROOT="../Project1"

SET OLD_DIR=%CD%
CD "%PLUGIN_SYSTEM_ROOT%"

RUBY "start_rmxp.rb" "%RMXP_PROJECT_ROOT%"

CD %OLD_DIR%