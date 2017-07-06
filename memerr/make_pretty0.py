#MnemRet.py --beg '2010-03-01 00:00:00' --end 'now' LCMMEMCPUNODE LCMMEMLOG0TYP LCMMEMLOG0ADD LCMMEMLOG1TYP LCMMEMLOG1ADD LCMMEMLOG2TYP LCMMEMLOG2ADD LCMMEMLOG3TYP LCMMEMLOG3ADD

# Note:  This script assumes that all fields are present and that
#        they are given in the order listed above
#
# Description:  Makes a list of all VALID memory errors
# Output formate looks like this:
#   SIU: 2009-10-05 17:06:51.823456 (1254762411.823456)  Address:   32273736 (0x01ec7548)  Type: 3 (Correctable single-bit error)


import sys
import datetime
import traceback

cpus = ['SIU', 'EPU0', 'EPU1', 'EPU2']
error_type = {3:"Correctable single-bit error", 4:"Correctable multi-bit error"}


#-------------------------------------------------------#
def make_pretty():
#-------------------------------------------------------#  
  file = sys.stdin
  node = None

  for line in file.readlines():
    if not line.startswith('VAL'): continue
    line = line.split()
    ts   = line[3].strip('(').strip(')')
    mnem = line[4]
    val  = int(line[-1].strip(')'))

    if mnem == 'LCMMEMCPUNODE':
      node = val

    # Evaluate whether or not the address entry is valid and evalute the type
    if (mnem.find('TYP') >= 0):
      valid = (val>>31)&0x1
      typ   = (val>>24)&0x1f

    # If address is valid, append to full list of timestamps
    if (mnem.find('ADD') >= 0):
      if valid:
        print "%4s: %20s (%s)  Address: %10d (0x%08x)  Type: %d (%s)" % \
              (cpus[node], \
               datetime.datetime.utcfromtimestamp(float(ts)), \
               ts, int(val), int(val), typ, error_type[typ])

#-------------------------------------------------------#
def make_pretty_all():
#-------------------------------------------------------#  
  file = sys.stdin
  node = None

  for line in file.readlines():
    if not line.startswith('VAL'): continue
    line = line.split()
    ts   = line[3].strip('(').strip(')')
    mnem = line[4]
    val  = int(line[-1].strip(')'))

    if mnem == 'LCMMEMCPUNODE':
      node = val

    # Evaluate whether or not the address entry is valid and evalute the type
    if (mnem.find('TYP') >= 0):
      log   = val
      valid = (val>>31)&0x1
      typ   = (val>>24)&0x1f

    # Append address to full list of timestamps
    if (mnem.find('ADD') >= 0):
      print "%4s: %20s (%s)  Address: %10d (0x%08x)  Log:  %10d (0x%08x) (Type=%d, Valid=%d)" % \
            (cpus[node], \
             datetime.datetime.utcfromtimestamp(float(ts)), \
             ts, int(val), int(val), int(log), int(log), typ, valid)




#-------------------------------------------------------#  
if __name__ == '__main__':
    try:
        make_pretty()
    except:
        traceback.print_exc( file=sys.stdout )
        sys.exit( 1 )
#-------------------------------------------------------#          


      




