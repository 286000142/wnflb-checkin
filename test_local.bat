@echo off
setlocal
set /p U=请输入论坛账号: 
set /p P=请输入论坛密码: 
set FORUM_USERNAME=%U%
set FORUM_PASSWORD=%P%
python wnflb_checkin.py
pause
