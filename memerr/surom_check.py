# MnemRet.py --beg '2008-09-03 00:00:00' --end '2008-09-09 00:00:0' LCMMEMCPUNODE LCMMEMLOG0TYP LCMMEMLOG1TYP LCMMEMLOG2TYP LCMMEMLOG3TYP | python memerr.py

if __name__ == "__main__":
  import sys

  #file = open('error.txt')
  file = sys.stdin
  
  summary = {0:{},1:{},2:{}}

  for line in file.readlines():
    if not line.startswith('VAL'): continue
    line = line.split()
    mnem = line[4]
    val  = int(line[-1].strip(')'))
    #print "%s 0x%08x"%(mnem,val)

    if mnem == 'LCMMEMCPUNODE':
      node = val
      
    if mnem == 'LCMMEMLOG0ADD':
      if (val >= 0xfff00000) and (val <= 0xfff04000):
        print "ERROR - SUROM on node %d corrupted at address 0x%08x" % (node, val)
        if summary[node].has_key(val):
          summary[node][val] += 1
        else:
          summary[node][val] = 1
          
    if mnem == 'LCMMEMLOG1ADD':
      if (val >= 0xfff00000) and (val <= 0xfff04000):
        print "ERROR - SUROM on node %d corrupted at address 0x%08x" % (node, val)        
        if summary[node].has_key(val):
          summary[node][val] += 1
        else:
          summary[node][val] = 1

    if mnem == 'LCMMEMLOG2ADD':
      if (val >= 0xfff00000) and (val <= 0xfff04000):
        print "ERROR - SUROM on node %d corrupted at address 0x%08x" % (node, val)        
        if summary[node].has_key(val):
          summary[node][val] += 1
        else:
          summary[node][val] = 1

    if mnem == 'LCMMEMLOG3ADD':
      if (val >= 0xfff00000) and (val <= 0xfff04000):
        print "ERROR - SUROM on node %d corrupted at address 0x%08x" % (node, val)        
        if summary[node].has_key(val):
          summary[node][val] += 1
        else:
          summary[node][val] = 1

print summary
      

