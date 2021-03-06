#####################################################################
#   delta_snap.py 
#
#   This program calculates the difference between text files
#   The input files are from the PowerShell scripts:  win_snap.ps1
#   and lin_snap.ps1
#
#   The User enters two folders names (folder1, folder2)
#   The deltas are computed in the direction (folder2 - folder1)
#
#   Registry files are converted into dictionaries before computing deltas
#
#   Written by:  Brian Nishida
#   Date:        2020-09-23
#
####################################################################

import difflib
import sys, os
import datetime


# Dictionary of PowerShell snapshot files
# key: file name, value: encoding type
psfiles = {'processes.csv':'ascii',
	'services.csv':'ascii', 
	'tcpconnections.csv':'ascii',
	'eventlog_application.csv': 'ascii',
	'eventlog_security.csv': 'ascii',
	'eventlog_system.csv': 'ascii',
	'files.csv':'ascii',
	'folders.csv':'ascii',
	'filehashes.csv':'ascii', 	
	'autoruns.csv':'iso8859_15',
        'auth.log':'ascii',
	'bash_history':'ascii',
	'boot.log':'utf-8',
	'bootstrap.log':'ascii',
	'dmesg.log':'utf-8',
	'dpkg.log':'ascii',
	'journal.log':'utf-8',
	'kern.log':'ascii',
	'syslog':'utf-8',
	'Xorg.0.log':'ascii',
	'recently-used.xbel':'ascii',
        'gsettings.txt':'ascii'
       }

# List of Registry files
regfiles = ['hkcu.reg', 
	'hklm.reg', 
	'hkcr.reg', 
	'hku.reg',
	'hkcc.reg']


# Function to create registry file dictionary
def reg2dict(file:str) -> dict:
    # need to chomp off 1st lines without a bracket [ ]
    regdict = {}
    cnt = 0

    with open(file, encoding='utf-16') as regfile:
    #with open(file) as regfile:
        for line in regfile:
            cnt += 1
            if (cnt >= 3):
                if line.startswith('['):
                    regkey = line
                    regval = ''
                    regdict[regkey] = regval
                else:
                    regval = regval + line
                    regdict[regkey] = regval
    return regdict


# Prompt the user for folders to compute deltas from.  Create a delta folder
folder1 = input('Enter 1st folder (before): ')
folder2 = input('Enter 2nd folder (after ): ')

# Print out the starting date/time
now = datetime.datetime.now()
print ("\n")
print ("Start Time: ",now.strftime("%Y-%m-%d %H:%M:%S"))

folder3 = folder2 + '-' + folder1
folder3path = os.getcwd() + '/' + folder3
if not os.path.exists(folder3path):
    os.mkdir(folder3path)

prefix = folder3path + '/' + 'delta_'


# Loop through all files in folder2 to compute difference files
for file in os.listdir(folder2):
    strfile = str(file)

    # Loop through the PowerShell snapshot files
    if strfile in psfiles.keys():

        # set the encoding
        encode = psfiles[strfile]
           
        with open(folder1 + '/' + strfile, encoding=encode) as file1:
            with open(folder2 + '/' + strfile, encoding=encode) as file2:
                
                diff = difflib.ndiff(file1.readlines(), file2.readlines())
                print('Writing ' + prefix + strfile)

                # save header to write to delta files
                file2.seek(0)
                header = str(file2.readline())

            # write the delta file for folder2-folder1 signified by '+' sign in ndiff
            with open(prefix + strfile, 'w') as file3:
                file3.write(header)
                for line in diff:
                    if line.startswith('+'):
                        file3.write(line[2:])     # Remove '+ ' at beginning of line

                        
    # Else if a Registry file
    # Convert Registry text files into dictionaries
    elif strfile in regfiles:
        regd1 = reg2dict(folder1 + '/' + strfile)
        regd2 = reg2dict(folder2 + '/' + strfile)

        # compute the delta of registry dictionaries
        set1 = set(regd1.items())
        set2 = set(regd2.items())
        regdelta = dict(set2 - set1)

        # write the delta file
        print('Writing ' + prefix + strfile)
        with open(prefix + strfile, 'w') as regfile3:
            for keys,values in regdelta.items():
                regfile3.write(str(keys))
                regfile3.write(str(values))

# Print out the ending date/time
now = datetime.datetime.now()
print ("\n")
print ("End Time: ",now.strftime("%Y-%m-%d %H:%M:%S"))





