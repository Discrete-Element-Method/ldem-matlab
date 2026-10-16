@echo off
if "%SPHINXBUILD%"=="" set SPHINXBUILD=sphinx-build
%SPHINXBUILD% -b html source build\html
