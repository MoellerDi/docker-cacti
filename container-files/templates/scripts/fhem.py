#!/usr/bin/python

import simplejson as json
import urllib2
import re, sys
import telnetlib

class fhemdevice:
  def __init__(self, ip, port):
    self.ip = ip
    self.port = port
    self.output = {}

  def execute(self, cmd, fhemdev):
    ret = ""
    try:
      tn = telnetlib.Telnet()
      if DEBUG: print ("Connect to fhem %s:%s" % (str(self.ip), str(self.port)))
      tn.open(self.ip, self.port)
      tn.write("%s %s\n" % (str(cmd), str(fhemdev)))
      tn.write("quit\n")
      ret = tn.read_all()
      tn.close()
      ret = re.sub(r'Bye...', '',str(ret))
    except:
      if DEBUG: print "telnet exception, could not connect to fhem instance"
    return ret

  def getjson(self, fhemdev):
    self.FHEMJsonRes = json.loads(self.execute('jsonlist2', fhemdev))

  def printjson(self):
    return self.FHEMJsonRes

  def getvalue(self, item, out_as):
    if item in self.FHEMJsonRes["Results"][0]["Readings"]:
      self.output[out_as] = self.FHEMJsonRes["Results"][0]["Readings"][item]["Value"]

  def printout(self):
    res = ""
    for key in self.output:
      if self.output[key] == "null":
        self.output[key] = 0
      res += key + ":" + "%.2f" % float(self.output[key]) + " "
    self.output = {}
    return res

##############################

def get_by_serial(fhemdev):
  fhem.getjson(fhemdev)
  fhem.getvalue('batteryLevel', 'BATTERY_STATE')
  fhem.getvalue('ValvePosition', 'VALVE_STATE')
  fhem.getvalue('actuator', 'VALVE_STATE')
  fhem.getvalue('desired-temp', 'SET_TEMPERATURE')
  fhem.getvalue('measured-temp', 'ACTUAL_TEMPERATURE')
  fhem.getvalue('humidity', 'HUMIDITY')
  fhem.getvalue('temperature', 'ACTUAL_TEMPERATURE')
  fhem.getvalue('UR_TEMPERATURE_T1', 'TEMPERATURE_SENSOR1')
  fhem.getvalue('UR_TEMPERATURE_T2', 'TEMPERATURE_SENSOR2')
  fhem.getvalue('dewpoint', 'DEWPOINT')
  fhem.getvalue('rssi', 'RSSI_STATE')
  return fhem.printout()

def get_by_name(fhemdev):
  return fhem.execute('getstate', fhemdev)

#################################

if __name__ == "__main__":
  DEBUG = 0
  host = sys.argv[1]
  port = sys.argv[2]
  action = sys.argv[3]
  fhem = fhemdevice(host,port)

  if 'get_by_serial' in action:
    try:
      fhemdev = 'serialNr=' + sys.argv[4]
    except IndexError:
      print('get_by_serial function needs an argument to know what it should return')
      exit()
    print get_by_serial(fhemdev)
  elif 'get_by_name' in action:
    try:
      fhemdev = sys.argv[4]
    except IndexError:
      print('get_by_name function needs an argument to know what it should return')
      exit()
    print get_by_name(fhemdev)
  else:
    print '''fhem.py <fhem-host> <fhem-telnet.port> get_by_serial <device-serial> \nfhem.py <fhem-host> <fhem-telnet.port> get_by_name <device-name>'''