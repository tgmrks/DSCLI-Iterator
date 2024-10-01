## DSCLI Iterator 

This bash script was created by me to automate the tedious process of listing ranks (lsrank) from several DS8000 GUI. 

When I started my carrier at IBM as an intern, my tech leader asked me to work on a monthly report they had to provide. After spending a few hours collecting .csv files extracted from several devices, I decided to improve this process anyway I could. I did some research and found it could be accomplish via DSCLI. As the whole process was the same for all devices, I managed to iterate over a list of IPs using bash script and to format the data with AWK. This script helped me to reduce hours of repetitive work into a few minutes.     

**Functions available:**

1 - Rank Report</br> 
2 - List IP Adresses</br>
3 - Convert report to XML</br>
4 - Test credentials</br>
0 - Exit