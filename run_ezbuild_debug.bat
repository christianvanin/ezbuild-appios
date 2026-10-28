@echo off
cd /d C:\Users\vanin\Desktop\appIOS
ezbuild --push-and-build --non-interactive > C:\Users\vanin\Desktop\appIOS\ezbuild_output.log 2>&1
echo EXIT_CODE=%ERRORLEVEL% >> C:\Users\vanin\Desktop\appIOS\ezbuild_output.log
