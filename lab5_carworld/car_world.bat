cd de2_car_world_system
%QUARTUS_ROOTDIR%\bin\quartus_pgm -c "USB-Blaster [USB-0]" -m jtag -o P;DE2_Media_Computer.sof
cd ..\jtag_uart
start cmd /C %QUARTUS_ROOTDIR%\bin\quartus_stp.exe -t jtag_server.tcl
timeout 10
cd ..\carworld
CMD /C win_carw.exe
cd ..

